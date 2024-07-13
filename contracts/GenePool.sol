// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GenePool {
    address public nft;
    uint256 public speciesCount;

    uint256 public skinColorGeneNum;
    uint256 public hornStyleGeneNum;
    uint256 public wingStyleGeneNum;
    uint256[] public listAvailableSpecies;

    mapping(uint256 => bool) public isSpeciesGeneInitialized;
    mapping(uint256 => bool) public isSpeciesGeneAvailableInGenePool;

    constructor(
        address _joyGotchiNFT,
        uint256 _skinColorGeneNum,
        uint256 _hornStyleGeneNum,
        uint256 _wingStyleGeneNum
    ) {
        nft = _joyGotchiNFT;
        skinColorGeneNum = _skinColorGeneNum;
        hornStyleGeneNum = _hornStyleGeneNum;
        wingStyleGeneNum = _wingStyleGeneNum;
    }

    modifier onlyNFT() {
        require(msg.sender == nft, "Unauthorized");
        _;
    }

    function addSpeciesToGenePool(uint _id) external onlyNFT returns (uint256) {
        if (!isSpeciesGeneInitialized[_id]) {
            isSpeciesGeneInitialized[_id] = true;
            speciesCount++;
        } else {
            require(!isSpeciesGeneAvailableInGenePool[_id], "Species added");
        }
        isSpeciesGeneAvailableInGenePool[_id] = true;
        listAvailableSpecies.push(_id);

        return speciesCount;
    }

    function removeSpeciesFromGenePool(uint _id) external onlyNFT {
        require(
            isSpeciesGeneInitialized[_id] &&
                isSpeciesGeneAvailableInGenePool[_id],
            "Species not added"
        );
        for (uint256 i = 0; i < listAvailableSpecies.length; i++) {
            if (listAvailableSpecies[i] == _id) {
                listAvailableSpecies[i] = listAvailableSpecies[
                    listAvailableSpecies.length - 1
                ];
                listAvailableSpecies.pop();
                break;
            }
        }
        isSpeciesGeneAvailableInGenePool[_id] = false;
    }

    function generateGene(
        address _account,
        uint _nftId,
        uint seed
    ) external view onlyNFT returns (uint256 species, uint256 sex) {
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

    receive() external payable {
        payable(nft).transfer(msg.value);
    }
}
