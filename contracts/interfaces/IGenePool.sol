// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGenePool {
    struct Evolution {
        string image;
        string name;
        uint256 attackPoints;
        uint256 defensePoints;
        uint256 nextEvolutionLevel;
    }

    struct SpeciesDefaultAttrs {
        uint256 skinColor;
        uint256 hornStyle;
        uint256 wingStyle;
    }
    function nft() external view returns (address);
    function totalGeneNum() external view returns (uint256);
    function speciesCount() external view returns (uint256);
    function eyeColorGeneNum() external view returns (uint256);
    function skinColorGeneNum() external view returns (uint256);
    function hornStyleGeneNum() external view returns (uint256);
    function wingStyleGeneNum() external view returns (uint256);
    function speciesToSpawnCondition(
        uint256 _id
    ) external view returns (uint256 gte, uint256 lte);
    function isSpeciesGeneInitialized(uint256 _id) external view returns (bool);
    function reducePopulationAndAddSpeciesToGenePool(uint _id) external returns (uint256);
    function removeSpeciesFromGenePool(uint _id) external;
    function generateGene(
        address _account,
        uint _nftId,
        uint seed
    ) external view returns (uint256 species, uint256 sex);
    function speciesDefaultAttrs(
        uint256 _id
    ) external view returns (SpeciesDefaultAttrs memory);
    function currentSpeciesPopulation(
        uint256 _id
    ) external view returns (uint256);
    function speciesMaxPopulation(uint256 _id) external view returns (uint256);
    function speciesMaxEvolutionPhase(
        uint256 _id
    ) external view returns (uint256);
    function getSpeciesEvolutionPhaseInfo(
        uint256 _speciesId,
        uint256 _phase
    ) external view returns (Evolution memory);
    function newMemberJoinSpecies(uint256 _speciesId) external;
}
