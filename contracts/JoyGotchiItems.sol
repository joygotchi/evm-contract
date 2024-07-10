// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {ERC721} from "solmate/src/tokens/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract JoyGotchiItems is ERC721, Ownable {
    enum ItemType {
        Common,
        Rare,
        Legendary,
        Epic
    }

    mapping(address => bool) _allowAddress;

    // Item properties
    uint256 public totalItems;
    mapping(uint256 => string) itemImage;
    mapping(uint256 => bool) isAccessoryItem;
    mapping(uint256 => bool) isStakeItem;
    mapping(uint256 => bool) isBreedItem;
    mapping(uint256 => bool) isArcadeItem;
    mapping(uint256 => uint256) reduceBreedTimePercent;
    mapping(uint256 => uint256) reduceBreedFeePercent;
    mapping(uint256 => uint256) breedSuccessRate;
    mapping(uint256 => uint256) itemSpawnRate;
    mapping(uint256 => uint256) itemPoints;
    mapping(uint256 => uint256) typeItem;
    mapping(uint256 => bool) burnAfterUsed;
    mapping(uint256 => uint256) timePerClaim;

    // Prototype Item
    uint256 totalPrototypeItems;
    mapping(uint256 => uint256) public itemTypeAmount;
    mapping(uint256 => uint256[]) listPrototypeItemsOfType;
    mapping(uint256 => string) prototypeItemImage;
    mapping(uint256 => bool) isAccessoryPrototypeItem;
    mapping(uint256 => bool) isStakePrototypeItem;
    mapping(uint256 => bool) isBreedPrototypeItem;
    mapping(uint256 => bool) isArcadePrototypeItem;
    mapping(uint256 => uint256) prototypeItemReduceBreedTimePercent;
    mapping(uint256 => uint256) prototypeItemReduceBreedFeePercent;
    mapping(uint256 => uint256) prototypeItemBreedSuccessRate;
    mapping(uint256 => uint256) prototypeItemSpawnRate;
    mapping(uint256 => uint256) prototypeItemPoints;
    mapping(uint256 => uint256) typePrototypeItem;
    mapping(uint256 => bool) burnAfterUsedPrototypeItem;
    mapping(uint256 => uint256) timePerClaimPrototypeItem;

    // Item chance
    uint256 public constant MAX_CHANCE = 1000;
    uint256 public epicDropRate = 50;
    uint256 public legendaryDropRate = 100;
    uint256 public rareDropRate = 200;
    uint256 public commonDropRate = 1000;

    mapping(uint256 => bool) isItemLock;

    event ItemCreated(uint256 indexed prototypeId, address indexed owner);

    constructor() ERC721("Joy Gotchi Items", "JGCItems") {}

    modifier isValid() {
        require(_allowAddress[msg.sender], "not authorize");
        _;
    }

    function getItemAttribute(
        uint256 _id
    )
        public
        view
        returns (
            uint256 _reduceBreedTimePercent,
            uint256 _reduceBreedFeePercent,
            uint256 _breedSuccessRate,
            uint256 _itemSpawnRate,
            uint256 _itemPoints,
            uint256 _typeItem,
            bool _burnAfterUsed,
            uint256 _timePerClaim
        )
    {
        _reduceBreedFeePercent = reduceBreedFeePercent[_id];
        _reduceBreedTimePercent = reduceBreedTimePercent[_id];
        _breedSuccessRate = breedSuccessRate[_id];
        _itemSpawnRate = itemSpawnRate[_id];
        _itemPoints = itemPoints[_id];
        _typeItem = typeItem[_id];
        _burnAfterUsed = burnAfterUsed[_id];
        _timePerClaim = timePerClaim[_id];
    }

    function getItemImage(uint256 _id) public view returns (string memory) {
        return itemImage[_id];
    }

    function getItemFunctionType(
        uint256 _id
    ) public view returns (bool, bool, bool, bool) {
        return (
            isAccessoryItem[_id],
            isStakeItem[_id],
            isBreedItem[_id],
            isArcadeItem[_id]
        );
    }

    function mint(address _to, uint256 _prototypeItemId) public isValid {
        require(_prototypeItemId < totalPrototypeItems, "Invalid prototype id");
        uint256 currentTokenId = totalItems;
        itemImage[currentTokenId] = prototypeItemImage[_prototypeItemId];
        isAccessoryItem[currentTokenId] = isAccessoryPrototypeItem[
            _prototypeItemId
        ];
        isStakeItem[currentTokenId] = isStakePrototypeItem[_prototypeItemId];
        isBreedItem[currentTokenId] = isBreedPrototypeItem[_prototypeItemId];
        isArcadeItem[currentTokenId] = isArcadePrototypeItem[_prototypeItemId];
        reduceBreedTimePercent[
            currentTokenId
        ] = prototypeItemReduceBreedTimePercent[_prototypeItemId];
        reduceBreedFeePercent[
            currentTokenId
        ] = prototypeItemReduceBreedFeePercent[_prototypeItemId];
        breedSuccessRate[currentTokenId] = prototypeItemBreedSuccessRate[
            _prototypeItemId
        ];
        itemSpawnRate[currentTokenId] = prototypeItemSpawnRate[
            _prototypeItemId
        ];
        itemPoints[currentTokenId] = prototypeItemPoints[_prototypeItemId];
        typeItem[currentTokenId] = typePrototypeItem[_prototypeItemId];
        burnAfterUsed[currentTokenId] = burnAfterUsedPrototypeItem[
            _prototypeItemId
        ];
        timePerClaim[currentTokenId] = timePerClaimPrototypeItem[
            _prototypeItemId
        ];
        _mint(_to, totalItems);
        totalItems++;
    }

    function burn(uint256 _tokenId) public isValid {
        delete itemImage[_tokenId];
        delete isAccessoryItem[_tokenId];
        delete isStakeItem[_tokenId];
        delete isBreedItem[_tokenId];
        delete isArcadeItem[_tokenId];
        delete reduceBreedTimePercent[_tokenId];
        delete reduceBreedFeePercent[_tokenId];
        delete breedSuccessRate[_tokenId];
        delete itemSpawnRate[_tokenId];
        delete itemPoints[_tokenId];
        delete typeItem[_tokenId];
        delete burnAfterUsed[_tokenId];
        delete timePerClaim[_tokenId];
        _burn(_tokenId);
    }

    function lockToken(uint256 _tokenId) public isValid {
        isItemLock[_tokenId] = true;
    }

    function unlockToken(uint256 _tokenId) public isValid {
        isItemLock[_tokenId] = false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(!isItemLock[tokenId], "Item is locked");
        super.transferFrom(from, to, tokenId);
    }

    function createPrototypeItem(
        string memory _prototypeItemImage,
        bool[4] memory _itemForFunction, // 0 - isAccessory, 1 - isStake, 2 - isBreed, 3 - isArcade
        uint256[6] memory _itemAttribute, // 0 - reduceBreedTimePercent, 1 - reduceBreedFeePercent, 2 - breedSuccessRate, 3 - itemSpawnRate, 4 - itemPoints, 5 - typeItem
        bool _burnAfterUsedPrototypeItem,
        uint256 _timePerClaimPrototypeItem
    ) public onlyOwner {
        if (_itemAttribute[5] > uint256(ItemType.Epic)) {
            revert("Invalid item type");
        }
        if (_itemAttribute[3] > MAX_CHANCE) {
            revert("Invalid item spawn rate");
        }
        uint256 currentPrototypeId = totalPrototypeItems;
        prototypeItemImage[currentPrototypeId] = _prototypeItemImage;
        isAccessoryPrototypeItem[currentPrototypeId] = _itemForFunction[0];
        isStakePrototypeItem[currentPrototypeId] = _itemForFunction[1];
        isBreedPrototypeItem[currentPrototypeId] = _itemForFunction[2];
        isArcadePrototypeItem[currentPrototypeId] = _itemForFunction[3];
        prototypeItemReduceBreedTimePercent[
            currentPrototypeId
        ] = _itemAttribute[0];
        prototypeItemReduceBreedFeePercent[currentPrototypeId] = _itemAttribute[
            1
        ];
        prototypeItemBreedSuccessRate[currentPrototypeId] = _itemAttribute[2];
        prototypeItemSpawnRate[currentPrototypeId] = _itemAttribute[3];
        prototypeItemPoints[currentPrototypeId] = _itemAttribute[4];
        typePrototypeItem[currentPrototypeId] = _itemAttribute[5];
        burnAfterUsedPrototypeItem[
            currentPrototypeId
        ] = _burnAfterUsedPrototypeItem;
        timePerClaimPrototypeItem[
            currentPrototypeId
        ] = _timePerClaimPrototypeItem;

        itemTypeAmount[_itemAttribute[5]]++;
        listPrototypeItemsOfType[_itemAttribute[5]].push(currentPrototypeId);
        totalPrototypeItems++;
        emit ItemCreated(currentPrototypeId, msg.sender);
    }

    // Can edit attribute but can't change type of item
    function editItems(
        uint256 _prototypeId,
        string memory _prototypeItemImage,
        bool[4] memory _itemForFunction, // 0 - isAccessory, 1 - isStake, 2 - isBreed, 3 - isArcade
        uint256[5] memory _itemAttribute, // 0 - reduceBreedTimePercent, 1 - reduceBreedFeePercent, 2 - breedSuccessRate, 3 - itemSpawnRate, 4 - itemPoints
        bool _burnAfterUsedPrototypeItem,
        uint256 _timePerClaimPrototypeItem
    ) public onlyOwner {
        require(_prototypeId < totalPrototypeItems, "Invalid prototype id");
        if (_itemAttribute[3] > MAX_CHANCE) {
            revert("Invalid item spawn rate");
        }
        prototypeItemImage[_prototypeId] = _prototypeItemImage;
        isAccessoryPrototypeItem[_prototypeId] = _itemForFunction[0];
        isStakePrototypeItem[_prototypeId] = _itemForFunction[1];
        isBreedPrototypeItem[_prototypeId] = _itemForFunction[2];
        isArcadePrototypeItem[_prototypeId] = _itemForFunction[3];
        prototypeItemReduceBreedTimePercent[_prototypeId] = _itemAttribute[0];
        prototypeItemReduceBreedFeePercent[_prototypeId] = _itemAttribute[1];
        prototypeItemBreedSuccessRate[_prototypeId] = _itemAttribute[2];
        prototypeItemSpawnRate[_prototypeId] = _itemAttribute[3];
        prototypeItemPoints[_prototypeId] = _itemAttribute[4];
        burnAfterUsedPrototypeItem[_prototypeId] = _burnAfterUsedPrototypeItem;
        timePerClaimPrototypeItem[_prototypeId] = _timePerClaimPrototypeItem;
    }

    function getPrototypeForNewItem(
        address _account,
        uint seed,
        uint256 additionalItemSpawnRate
    ) external view isValid returns (uint256 prototypeItemId) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    _account,
                    seed,
                    additionalItemSpawnRate
                )
            )
        );
        uint256 randomChance = random % (MAX_CHANCE + 1);
        if (randomChance < epicDropRate + additionalItemSpawnRate) {
            prototypeItemId = listPrototypeItemsOfType[uint256(ItemType.Epic)][
                random % itemTypeAmount[uint256(ItemType.Epic)]
            ];
        } else if (randomChance < legendaryDropRate + additionalItemSpawnRate) {
            prototypeItemId = listPrototypeItemsOfType[
                uint256(ItemType.Legendary)
            ][random % itemTypeAmount[uint256(ItemType.Legendary)]];
        } else if (randomChance < rareDropRate + additionalItemSpawnRate) {
            prototypeItemId = listPrototypeItemsOfType[uint256(ItemType.Rare)][
                random % itemTypeAmount[uint256(ItemType.Rare)]
            ];
        } else {
            prototypeItemId = listPrototypeItemsOfType[
                uint256(ItemType.Common)
            ][random % itemTypeAmount[uint256(ItemType.Common)]];
        }
    }

    function setEpicItemDropRate(uint256 _rate) public onlyOwner {
        require(_rate <= MAX_CHANCE, "Invalid rate");
        epicDropRate = _rate;
    }

    function setLegendaryItemDropRate(uint256 _rate) public onlyOwner {
        require(_rate <= MAX_CHANCE && _rate > epicDropRate, "Invalid rate");
        legendaryDropRate = _rate;
    }

    function setRareItemDropRate(uint256 _rate) public onlyOwner {
        require(
            _rate <= MAX_CHANCE && _rate > legendaryDropRate,
            "Invalid rate"
        );
        rareDropRate = _rate;
    }

    function setCommonItemDropRate(uint256 _rate) public onlyOwner {
        require(_rate <= MAX_CHANCE && _rate > rareDropRate, "Invalid rate");
        commonDropRate = _rate;
    }

    /*//////////////////////////////////////////////////////////////
                        Metadata
    //////////////////////////////////////////////////////////////*/
    function _generateMetadata(
        uint256 id
    ) internal view returns (string memory) {
        bytes memory dataURI = bytes.concat(
            abi.encodePacked(
                '{"trait_type": "isAccessoryItem","value":"',
                isAccessoryItem[id] ? "true" : "false",
                '"},{"trait_type": "isStakeItem[id]","value":"',
                isStakeItem[id] ? "true" : "false",
                '"},{"trait_type": "isBreedItem","value":"',
                isBreedItem[id] ? "true" : "false",
                '"},{"trait_type": "isArcadeItem","value":"',
                isArcadeItem[id] ? "true" : "false",
                '"},{"trait_type": "reduceBreedTimePercent","value":"',
                '"},{"trait_type": "reduceBreedTimePercent","value":"',
                _uint2str(reduceBreedTimePercent[id]),
                '"},{"trait_type": "reduceBreedFeePercent","value":"',
                _uint2str(reduceBreedFeePercent[id])
            ),
            abi.encodePacked(
                '"},{"trait_type": "breedSuccessRate","value":"',
                _uint2str(breedSuccessRate[id]),
                '"},{"trait_type": "itemSpawnRate","value":"',
                _uint2str(itemSpawnRate[id]),
                '"},{"trait_type": "itemPoints","value":"',
                _uint2str(itemPoints[id]),
                '"},{"trait_type": "typeItem","value":"',
                _uint2str(uint256(typeItem[id])),
                '"},{"trait_type": "burnAfterUsed","value":"',
                burnAfterUsed[id] ? "true" : "false",
                '"},{"trait_type": "timePerClaim","value":"',
                _uint2str(timePerClaim[id]),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory image = itemImage[id];
        string memory attributes = string(
            abi.encodePacked('", "attributes":[', _generateMetadata(id), "]}")
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    (
                        (
                            abi.encodePacked(
                                '{"name":"Joy Gotchi Item#',
                                _uint2str(id),
                                '","image": ',
                                '"',
                                image,
                                attributes
                            )
                        )
                    )
                )
            );
    }

    // Use to set allow for contract breed, stake, gacha, joygotchi
    function setAllowAddress(address _address, bool _allow) public onlyOwner {
        _allowAddress[_address] = _allow;
    }

    function _uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
