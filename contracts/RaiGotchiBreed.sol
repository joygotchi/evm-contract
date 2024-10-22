// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IRaiGotchi.sol";
import "./interfaces/IToken.sol";
import "./helper/RaiGotchiEnum.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract RaiGotchiBreed is Ownable, Pausable {
    IRaiGotchi public raiGotchiNFT;
    IToken public token;

    uint256 constant MAX_BREED_COUNT = 7;

    uint256 baseBreedTime;
    uint256 baseBreedFee;

    address treasury;

    // Breed info
    uint256 public totalBreeds;
    mapping(uint256 => uint256) public breedFinishTime;
    mapping(uint256 => uint256) public breedCount;
    mapping(uint256 => address) public breedOwner;
    mapping(uint256 => uint256[2]) public breedParentsId;

    event StartBreed(uint256 breedId, uint256 nftId, uint256 nftId2);

    constructor(address _raiGotchiNFT, address _token, address _treasury) {
        raiGotchiNFT = IRaiGotchi(_raiGotchiNFT);
        token = IToken(_token);
        treasury = _treasury;
        baseBreedTime = 1 days;
        baseBreedFee = 10 ether;
    }

    modifier isApprovedRaiGotchiNFT(uint256 id) {
        require(
            raiGotchiNFT.ownerOf(id) == msg.sender ||
                raiGotchiNFT.getApproved(id) == msg.sender,
            "Pet not approved"
        );
        _;
    }

    function checkConditionBeforeBreed(
        uint256 _nftId,
        uint256 _nftId2,
        uint256 species1,
        uint256 species2
    ) private {
        require(_nftId != _nftId2, "Can't breed with yourself");
        require(raiGotchiNFT.isPetAlive(_nftId), "Pet1 is dead");
        require(raiGotchiNFT.isPetAlive(_nftId2), "Pet2 is dead");
        require(
            raiGotchiNFT.petSex(_nftId) != raiGotchiNFT.petSex(_nftId2),
            "Same sex"
        );
        require(
            raiGotchiNFT.getStatus(_nftId) == PetStatus.HAPPY,
            "Pet1 not happy"
        );
        require(
            raiGotchiNFT.getStatus(_nftId2) == PetStatus.HAPPY,
            "Pet2 not happy"
        );

        require(!raiGotchiNFT.isPetLocked(_nftId), "Pet1 is locked");
        require(!raiGotchiNFT.isPetLocked(_nftId2), "Pet2 is locked");

        require(
            breedCount[_nftId] < MAX_BREED_COUNT,
            "Pet 1 breed count exceed"
        );
        require(
            breedCount[_nftId2] < MAX_BREED_COUNT,
            "Pet 2 breed count exceed"
        );

        raiGotchiNFT.checkPetEvoleAndUpdateIfNeeded(_nftId);
        raiGotchiNFT.checkPetEvoleAndUpdateIfNeeded(_nftId2);

        require(
            raiGotchiNFT.petEvolutionPhaseExternal(_nftId) ==
                raiGotchiNFT.speciesMaxEvolutionPhase(species1),
            "Pet1 not max evolution phase"
        );
        require(
            raiGotchiNFT.petEvolutionPhaseExternal(_nftId2) ==
                raiGotchiNFT.speciesMaxEvolutionPhase(species2),
            "Pet2 not max evolution phase"
        );

        require(
            raiGotchiNFT.currentSpeciesPopulation(species1) <
                raiGotchiNFT.speciesMaxPopulation(species1) &&
                raiGotchiNFT.currentSpeciesPopulation(species2) <
                raiGotchiNFT.speciesMaxPopulation(species2),
            "Species at max population"
        );
    }

    function breed(
        uint256 _nftId,
        uint256 _nftId2
    )
        external
        whenNotPaused
        isApprovedRaiGotchiNFT(_nftId)
        isApprovedRaiGotchiNFT(_nftId2)
    {
        uint256 species1 = raiGotchiNFT.petSpecies(_nftId);
        uint256 species2 = raiGotchiNFT.petSpecies(_nftId2);


        checkConditionBeforeBreed(_nftId, _nftId2, species1, species2);

        raiGotchiNFT.lockPet(_nftId);
        raiGotchiNFT.lockPet(_nftId2);

        uint256 _breedTime = baseBreedTime * breedCount[_nftId];

        breedFinishTime[totalBreeds] = block.timestamp + _breedTime;

        uint256 _breedFee = baseBreedFee * breedCount[_nftId];

        token.transferFrom(msg.sender, treasury, _breedFee);

        breedParentsId[totalBreeds] = [_nftId, _nftId2];
        breedOwner[totalBreeds] = msg.sender;

        emit StartBreed(totalBreeds, _nftId, _nftId2);

        totalBreeds++;
    }

    function claimBreed(uint256 _breedId) external whenNotPaused {
        require(breedFinishTime[_breedId] != 0, "Not in breed");

        require(
            block.timestamp >= breedFinishTime[_breedId],
            "Breed not finish yet"
        );

        require(breedOwner[_breedId] == msg.sender, "Not your breed");

        uint256 parent1 = breedParentsId[_breedId][0];
        uint256 parent2 = breedParentsId[_breedId][1];

        breedCount[parent1]++;
        breedCount[parent2]++;

        uint256 species1 = raiGotchiNFT.petSpecies(parent1);
        uint256 species2 = raiGotchiNFT.petSpecies(parent2);

        uint256 _random = random(parent1 + parent2);

        uint256 _newPetSpecies;

        if (
            raiGotchiNFT.currentSpeciesPopulation(species1) ==
            raiGotchiNFT.speciesMaxPopulation(species1)
        ) {
            _newPetSpecies = species2;
        } else if (
            raiGotchiNFT.currentSpeciesPopulation(species2) ==
            raiGotchiNFT.speciesMaxPopulation(species2)
        ) {
            _newPetSpecies = species1;
        } else {
            _newPetSpecies = _random % 2 == 0 ? species1 : species2;
        }

        raiGotchiNFT.createNewPetAfterBreed(
            _random,
            _newPetSpecies,
            parent1,
            parent2
        );

        raiGotchiNFT.unlockPet(parent1);
        raiGotchiNFT.unlockPet(parent2);

        breedOwner[_breedId] = address(0);
    }

    function random(uint256 seed) private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.prevrandao,
                        block.timestamp,
                        msg.sender
                    )
                )
            );
    }

    /**
     * @dev Pauses the contract.
     * Only the contract owner can call this function.
     */
    function pause() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only the contract owner can call this function.
     */
    function unpause() external onlyOwner {
        super._unpause();
    }
}
