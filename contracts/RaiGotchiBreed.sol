// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IRaiGotchi.sol";
import "./interfaces/IRaiGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./helper/RaiGotchiEnum.sol";

contract RaiGotchiBreed {
    IRaiGotchi public raiGotchiNFT;
    IRaiGotchiItem public raiGotchiNFTItem;
    IToken public token;

    uint256 constant MAX_BREED_COUNT = 7;

    uint256 baseBreedTime;
    uint256 baseBreedFee;

    address treasury;

    // Breed info
    uint256 totalBreeds;
    mapping(uint256 => uint256) public breedFinishTime;
    mapping(uint256 => uint256) public breedCount;
    mapping(uint256 => address) public breedOwner;
    mapping(uint256 => uint256[2]) public breedParentsId;
    mapping(uint256 => uint256) public parent1PendingPoints;
    mapping(uint256 => uint256) public parent2PendingPoints;

    event StartBreed(
        uint256 breedId,
        uint256 nftId,
        uint256 nftId2,
        uint256 itemId
    );

    constructor(
        address _raiGotchiNFT,
        address _raiGotchiNFTItem,
        address _token,
        address _treasury
    ) {
        raiGotchiNFT = IRaiGotchi(_raiGotchiNFT);
        raiGotchiNFTItem = IRaiGotchiItem(_raiGotchiNFTItem);
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

    modifier isApprovedRaiGotchiNFTItem(uint256 id) {
        require(
            raiGotchiNFTItem.ownerOf(id) == msg.sender ||
                raiGotchiNFTItem.getApproved(id) == msg.sender,
            "Item not approved"
        );
        _;
    }

    function checkConditionBeforeBreed(
        uint256 _nftId,
        uint256 _nftId2,
        uint256 _itemId,
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
            raiGotchiNFT.petEvolutionPhase(_nftId) ==
                raiGotchiNFT.speciesMaxEvolutionPhase(species1),
            "Pet1 not max evolution phase"
        );
        require(
            raiGotchiNFT.petEvolutionPhase(_nftId2) ==
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

        require(
            raiGotchiNFTItem.itemType(_itemId) == ItemType.BREED,
            "Not a breed item"
        );
    }

    function breed(
        uint256 _nftId,
        uint256 _nftId2,
        uint256 _itemId
    )
        external
        isApprovedRaiGotchiNFT(_nftId)
        isApprovedRaiGotchiNFT(_nftId2)
        isApprovedRaiGotchiNFTItem(_itemId)
    {
        uint256 species1 = raiGotchiNFT.petSpecies(_nftId);
        uint256 species2 = raiGotchiNFT.petSpecies(_nftId2);

        checkConditionBeforeBreed(_nftId, _nftId2, _itemId, species1, species2);

        uint256 points = raiGotchiNFTItem.itemPoints(_itemId);

        raiGotchiNFTItem.burn(_itemId);

        raiGotchiNFT.lockPet(_nftId);
        raiGotchiNFT.lockPet(_nftId2);

        uint256 _breedTime = baseBreedTime * breedCount[_nftId];
        uint256 cooldownBreedTime = raiGotchiNFTItem.cooldownBreedTime(_itemId);

        breedFinishTime[totalBreeds] = _breedTime > cooldownBreedTime
            ? block.timestamp + _breedTime - cooldownBreedTime
            : block.timestamp;

        uint256 _breedFee = baseBreedFee * breedCount[_nftId];
        uint256 reduceBreedFee = raiGotchiNFTItem.reduceBreedFee(_itemId);

        if (_breedFee > reduceBreedFee) {
            token.transferFrom(
                msg.sender,
                treasury,
                _breedFee - reduceBreedFee
            );
        }

        parent1PendingPoints[totalBreeds] = points / 2;
        parent2PendingPoints[totalBreeds] =
            points -
            parent1PendingPoints[totalBreeds];
        breedParentsId[totalBreeds] = [_nftId, _nftId2];
        breedOwner[totalBreeds] = msg.sender;

        emit StartBreed(totalBreeds, _nftId, _nftId2, _itemId);

        totalBreeds++;
    }

    function claimBreed(uint256 _breedId) external {
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

        raiGotchiNFT.addPetScoreAfterUsedItem(
            parent1,
            parent1PendingPoints[_breedId]
        );

        raiGotchiNFT.addPetScoreAfterUsedItem(
            parent2,
            parent2PendingPoints[_breedId]
        );

        raiGotchiNFT.createNewPetAfterBreed(
            _random,
            _newPetSpecies,
            parent1,
            parent2
        );

        raiGotchiNFT.unlockPet(parent1);
        raiGotchiNFT.unlockPet(parent2);

        parent1PendingPoints[_breedId] = 0;
        parent2PendingPoints[_breedId] = 0;
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
}
