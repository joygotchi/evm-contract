// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GenePool is Ownable {
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

    address public nft;

    uint256 public skinColorGeneNum;
    uint256 public hornStyleGeneNum;
    uint256 public wingStyleGeneNum;
    uint256[] public listAvailableSpecies;

    uint256 public speciesCount;
    mapping(uint256 => mapping(uint256 => Evolution))
        public speciesToEvolutions;
    mapping(uint256 => uint256) public speciesMaxEvolutionPhase;
    mapping(uint256 => uint256) public speciesMaxPopulation;
    mapping(uint256 => SpeciesDefaultAttrs) public speciesDefaultAttrs;
    mapping(uint256 => uint256) public currentSpeciesPopulation;
    mapping(uint256 => bool) public isSpeciesGeneInitialized;
    mapping(uint256 => bool) public isSpeciesGeneAvailableInGenePool;

    event SpeciesCreated(uint256 id, uint256 speciesMaxPopulation);

    constructor(
        address _raiGotchiNFT,
        uint256 _skinColorGeneNum,
        uint256 _hornStyleGeneNum,
        uint256 _wingStyleGeneNum
    ) {
        nft = _raiGotchiNFT;
        skinColorGeneNum = _skinColorGeneNum;
        hornStyleGeneNum = _hornStyleGeneNum;
        wingStyleGeneNum = _wingStyleGeneNum;
    }

    modifier onlyNFT() {
        require(msg.sender == nft, "Unauthorized");
        _;
    }

    function createSpecies(
        Evolution[] memory _evolutions,
        SpeciesDefaultAttrs memory _defaultAttrs,
        uint256 _speciesMaxPopulation
    ) external onlyOwner {
        uint speciesId = speciesCount;
        for (uint256 i = 0; i < _evolutions.length; i++) {
            speciesToEvolutions[speciesId][i] = _evolutions[i];
        }

        speciesMaxEvolutionPhase[speciesId] = _evolutions.length - 1;
        speciesMaxPopulation[speciesId] = _speciesMaxPopulation;
        speciesDefaultAttrs[speciesId] = _defaultAttrs;

        isSpeciesGeneInitialized[speciesId] = true;
        isSpeciesGeneAvailableInGenePool[speciesId] = true;
        listAvailableSpecies.push(speciesId);
        speciesCount++;
        emit SpeciesCreated(speciesId, _speciesMaxPopulation);
    }

    // Call from NFT contract when a species is burned and the population is reduced from max
    function reducePopulationAndAddSpeciesToGenePool(
        uint _speciesId
    ) external onlyNFT returns (uint256) {
        require(
            isSpeciesGeneInitialized[_speciesId],
            "Species not initialized"
        );
        require(!isSpeciesGeneAvailableInGenePool[_speciesId], "Species added");

        currentSpeciesPopulation[_speciesId]--;
        isSpeciesGeneAvailableInGenePool[_speciesId] = true;
        listAvailableSpecies.push(_speciesId);

        return speciesCount;
    }
    // Call from NFT contract when a species is minted and the population is increased to max
    function removeSpeciesFromGenePool(uint _speciesId) external onlyNFT {
        require(
            isSpeciesGeneInitialized[_speciesId] &&
                isSpeciesGeneAvailableInGenePool[_speciesId],
            "Species not added"
        );
        for (uint256 i = 0; i < listAvailableSpecies.length; i++) {
            if (listAvailableSpecies[i] == _speciesId) {
                listAvailableSpecies[i] = listAvailableSpecies[
                    listAvailableSpecies.length - 1
                ];
                listAvailableSpecies.pop();
                break;
            }
        }
        isSpeciesGeneAvailableInGenePool[_speciesId] = false;
    }

    function newMemberJoinSpecies(uint256 _speciesId) external onlyNFT {
        require(
            isSpeciesGeneInitialized[_speciesId],
            "Species not initialized"
        );
        require(
            currentSpeciesPopulation[_speciesId] <
                speciesMaxPopulation[_speciesId],
            "Max population reached"
        );
        currentSpeciesPopulation[_speciesId]++;
    }

    function generateGene(
        address _account,
        uint _nftId,
        uint seed
    ) external view onlyNFT returns (uint256 species, uint256 sex) {
        require(listAvailableSpecies.length > 0, "No species available");

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    _account,
                    _nftId,
                    seed
                )
            )
        );
        uint256 randomSpeciesNum = random % listAvailableSpecies.length;
        species = listAvailableSpecies[randomSpeciesNum];
        sex = (random) % 2;
    }

    function getSpeciesEvolutions(
        uint256 _speciesId
    ) external view returns (Evolution[] memory) {
        Evolution[] memory evolutions = new Evolution[](
            speciesMaxEvolutionPhase[_speciesId] + 1
        );
        for (uint256 i = 0; i <= speciesMaxEvolutionPhase[_speciesId]; i++) {
            evolutions[i] = speciesToEvolutions[_speciesId][i];
        }
        return evolutions;
    }

    function getSpeciesEvolutionPhaseInfo(
        uint256 _speciesId,
        uint256 _phase
    ) external view returns (Evolution memory) {
        return speciesToEvolutions[_speciesId][_phase];
    }

    function setHornStyleGeneNum(uint256 _hornStyleGeneNum) external onlyOwner {
        hornStyleGeneNum = _hornStyleGeneNum;
    }

    function setWingStyleGeneNum(uint256 _wingStyleGeneNum) external onlyOwner {
        wingStyleGeneNum = _wingStyleGeneNum;
    }

    function setSkinColorGeneNum(uint256 _skinColorGeneNum) external onlyOwner {
        skinColorGeneNum = _skinColorGeneNum;
    }

    receive() external payable {
        payable(nft).transfer(msg.value);
    }
}
