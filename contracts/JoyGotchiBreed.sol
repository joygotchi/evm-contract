// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./interfaces/IJoyGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./JoyGotchiEnum.sol";

contract JoyGotchiBreed {
    IJoyGotchi public joyGotchiNFT;
    IJoyGotchiItem public joyGotchiNFTItem;
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
        address _joyGotchiNFT,
        address _joyGotchiNFTItem,
        address _token,
        address _treasury
    ) {
        joyGotchiNFT = IJoyGotchi(_joyGotchiNFT);
        joyGotchiNFTItem = IJoyGotchiItem(_joyGotchiNFTItem);
        token = IToken(_token);
        treasury = _treasury;
        baseBreedTime = 1 days;
        baseBreedFee = 10 ether;
    }

    modifier isApprovedJoyGotchiNFT(uint256 id) {
        require(
            joyGotchiNFT.ownerOf(id) == msg.sender ||
                joyGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    modifier isApprovedJoyGotchiNFTItem(uint256 id) {
        require(
            joyGotchiNFTItem.ownerOf(id) == msg.sender ||
                joyGotchiNFTItem.getApproved(id) == msg.sender,
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
        require(joyGotchiNFT.isPetAlive(_nftId), "Pet1 is dead");
        require(joyGotchiNFT.isPetAlive(_nftId2), "Pet2 is dead");
        require(
            joyGotchiNFT.petSex(_nftId) != joyGotchiNFT.petSex(_nftId2),
            "Same sex"
        );
        require(
            joyGotchiNFT.getStatus(_nftId) == PetStatus.HAPPY,
            "Pet1 not happy"
        );
        require(
            joyGotchiNFT.getStatus(_nftId2) == PetStatus.HAPPY,
            "Pet2 not happy"
        );

        require(!joyGotchiNFT.isPetLocked(_nftId), "Pet1 is locked");
        require(!joyGotchiNFT.isPetLocked(_nftId2), "Pet2 is locked");

        require(
            breedCount[_nftId] < MAX_BREED_COUNT,
            "Pet 1 breed count exceed"
        );
        require(
            breedCount[_nftId2] < MAX_BREED_COUNT,
            "Pet 2 breed count exceed"
        );

        joyGotchiNFT.checkEvolveBeforeBreed(_nftId);
        joyGotchiNFT.checkEvolveBeforeBreed(_nftId2);

        require(
            joyGotchiNFT.petEvolutionPhase(_nftId) ==
                joyGotchiNFT.speciesMaxEvolutionPhase(species1),
            "Pet1 not max evolution phase"
        );
        require(
            joyGotchiNFT.petEvolutionPhase(_nftId2) ==
                joyGotchiNFT.speciesMaxEvolutionPhase(species2),
            "Pet2 not max evolution phase"
        );

        require(
            joyGotchiNFT.currentSpeciesPopulation(species1) <
                joyGotchiNFT.speciesMaxPopulation(species1) &&
                joyGotchiNFT.currentSpeciesPopulation(species2) <
                joyGotchiNFT.speciesMaxPopulation(species2),
            "Species at max population"
        );

        require(
            joyGotchiNFTItem.itemType(_itemId) == ItemType.BREED,
            "Not a breed item"
        );
    }

    function breed(
        uint256 _nftId,
        uint256 _nftId2,
        uint256 _itemId
    )
        external
        isApprovedJoyGotchiNFT(_nftId)
        isApprovedJoyGotchiNFT(_nftId2)
        isApprovedJoyGotchiNFTItem(_itemId)
    {
        uint256 species1 = joyGotchiNFT.petSpecies(_nftId);
        uint256 species2 = joyGotchiNFT.petSpecies(_nftId2);

        checkConditionBeforeBreed(_nftId, _nftId2, _itemId, species1, species2);

        uint256 points = joyGotchiNFTItem.itemPoints(_itemId);

        joyGotchiNFTItem.burn(_itemId);

        joyGotchiNFT.lockPet(_nftId);
        joyGotchiNFT.lockPet(_nftId2);

        uint256 _breedTime = baseBreedTime * breedCount[_nftId];
        uint256 cooldownBreedTime = joyGotchiNFTItem.cooldownBreedTime(_itemId);

        breedFinishTime[totalBreeds] = _breedTime > cooldownBreedTime
            ? block.timestamp + _breedTime - cooldownBreedTime
            : block.timestamp;

        uint256 _breedFee = baseBreedFee * breedCount[_nftId];
        uint256 reduceBreedFee = joyGotchiNFTItem.reduceBreedFee(_itemId);

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

        uint256 species1 = joyGotchiNFT.petSpecies(parent1);
        uint256 species2 = joyGotchiNFT.petSpecies(parent2);

        uint256 _random = random(parent1 + parent2);

        uint256 _newPetSpecies;

        if (
            joyGotchiNFT.currentSpeciesPopulation(species1) ==
            joyGotchiNFT.speciesMaxPopulation(species1)
        ) {
            _newPetSpecies = species2;
        } else if (
            joyGotchiNFT.currentSpeciesPopulation(species2) ==
            joyGotchiNFT.speciesMaxPopulation(species2)
        ) {
            _newPetSpecies = species1;
        } else {
            _newPetSpecies = _random % 2 == 0 ? species1 : species2;
        }

        joyGotchiNFT.addPetScoreAfterUsedItem(
            parent1,
            parent1PendingPoints[_breedId]
        );

        joyGotchiNFT.addPetScoreAfterUsedItem(
            parent2,
            parent2PendingPoints[_breedId]
        );

        joyGotchiNFT.createNewPetAfterBreed(
            _random,
            _newPetSpecies,
            parent1,
            parent2
        );

        joyGotchiNFT.unlockPet(parent1);
        joyGotchiNFT.unlockPet(parent2);

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
