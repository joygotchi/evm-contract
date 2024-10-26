// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../helper/RaiGotchiEnum.sol";

interface IRaiGotchi {
    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function lastAttackUsed(uint256 id) external view returns (uint256);

    function lastAttacked(uint256 id) external view returns (uint256);

    function level(uint256 id) external view returns (uint256);

    function petScore(uint256 id) external view returns (uint256);

    function petRewardDebt(uint256 id) external view returns (uint256);

    function getPetAttackPoints(uint256 _nftId) external view returns (uint256);

    function getPetDefensePoints(
        uint256 _nftId
    ) external view returns (uint256);

    function isPetAlive(uint256 _nftId) external view returns (bool);

    function petSex(uint256 _nftId) external view returns (uint256);

    function timeUntilStarving(uint256 _nftId) external view returns (uint256);

    function speciesMaxPopulation(
        uint256 _species
    ) external view returns (uint256);

    function currentSpeciesPopulation(
        uint256 _species
    ) external view returns (uint256);

    function getStatus(uint256 _nftId) external view returns (PetStatus);

    function checkPetEvoleAndUpdateIfNeeded(uint256 _nftId) external;

    function petSpecies(uint256 _nftId) external view returns (uint256);

    function petEvolutionPhaseExternal(uint256 _nftId) external view returns (uint256);

    function speciesMaxEvolutionPhase(
        uint256 _species
    ) external view returns (uint256);

    function mintPrice() external view returns (uint256);

    function createNewPetAfterBreed(
        uint256 _random,
        uint256 _newPetSpecies,
        uint256 _parent1Id,
        uint256 _parent2Id
    ) external;

    function lockPet(uint256 _nftId) external;
    function unlockPet(uint256 _nftId) external;
    function isPetLocked(uint256 _nftId) external view returns (bool);

    function addPetScoreAfterUsedItem(uint256 _nftId, uint256 _score) external;

    function getWalletSeedAndUpdateIfNeeded() external returns (uint256);

    function petShield(uint256 _nftId) external view returns (uint256);

    function reducePetShield(uint256 _nftId) external;

    function setPetInfoAfterAttack(
        uint256 winnerId,
        uint256 loserId,
        uint256 _score,
        uint256 _debt
    ) external;

    function onConsumeImmidiateUseItem(
        uint256 _nftId,
        uint256 _itemTimeExtension,
        uint256 _itemShield,
        uint256 _itemPoints
    ) external;
}
