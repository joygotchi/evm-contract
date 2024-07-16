// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {ERC721} from "solmate/src/tokens/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "./helper/RaiGotchiEnum.sol";
import "./interfaces/IRaiGotchi.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract RaiGotchiItems is ERC721, Ownable, Pausable {
    enum ItemRarity {
        Common,
        Rare,
        Legendary,
        Epic
    }

    IRaiGotchi public raiGotchiNFT;

    mapping(address => bool) _allowAddress;

    // Item properties
    uint256 public totalItems;
    mapping(uint256 => string) itemImage;
    mapping(uint256 => ItemType) itemType;
    mapping(uint256 => uint256) cooldownBreedTime;
    mapping(uint256 => uint256) reduceBreedFee;
    mapping(uint256 => uint256) itemPoints;
    mapping(uint256 => ItemRarity) itemRarity;
    mapping(uint256 => uint256) miningPower;
    mapping(uint256 => uint256) miningChargeTime;

    // Prototype Item
    uint256 public totalPrototypeItems;
    mapping(uint256 => uint256) public itemRarityAmount;
    mapping(uint256 => uint256[]) listPrototypeItemsOfRarity;
    mapping(uint256 => string) prototypeItemImage;
    mapping(uint256 => ItemType) prototypeItemType;
    mapping(uint256 => uint256) prototypeItemCooldownBreedTime;
    mapping(uint256 => uint256) prototypeItemReduceBreedFee;
    mapping(uint256 => uint256) prototypeItemPoints;
    mapping(uint256 => ItemRarity) prototypeItemRarity;
    mapping(uint256 => uint256) prototypeItemminingPower;
    mapping(uint256 => uint256) prototypeItemminingChargeTime;

    // Item chance
    uint256 public constant MAX_CHANCE = 100;
    uint256 public epicDropRate = 5;
    uint256 public legendaryDropRate = 10;
    uint256 public rareDropRate = 20;
    uint256 public commonDropRate = 100;

    mapping(uint256 => bool) isItemLock;

    event PrototypeItemCreated(
        uint256 indexed prototypeId,
        address indexed owner
    );
    event ItemMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed prototypeId
    );

    constructor(address _raiGotchiNFT) ERC721("Rai Gotchi Items", "JGCItems") {
        raiGotchiNFT = IRaiGotchi(_raiGotchiNFT);
    }

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
            ItemType _itemType,
            uint256 _cooldownBreedTime,
            uint256 _reduceBreedFee,
            uint256 _itemPoints,
            ItemRarity _itemRarity,
            uint256 _miningPower,
            uint256 _miningChargeTime
        )
    {
        _itemType = itemType[_id];
        _reduceBreedFee = reduceBreedFee[_id];
        _cooldownBreedTime = cooldownBreedTime[_id];
        _itemPoints = itemPoints[_id];
        _itemRarity = itemRarity[_id];
        _miningPower = miningPower[_id];
        _miningChargeTime = miningChargeTime[_id];
    }

    function getItemImage(uint256 _id) public view returns (string memory) {
        return itemImage[_id];
    }

    function mint(
        address _to,
        uint256 _prototypeItemId
    ) public isValid whenNotPaused {
        require(_prototypeItemId < totalPrototypeItems, "Invalid prototype id");
        uint256 currentTokenId = totalItems;
        itemImage[currentTokenId] = prototypeItemImage[_prototypeItemId];
        itemType[currentTokenId] = itemType[_prototypeItemId];
        reduceBreedFee[currentTokenId] = prototypeItemReduceBreedFee[
            _prototypeItemId
        ];
        cooldownBreedTime[currentTokenId] = prototypeItemCooldownBreedTime[
            _prototypeItemId
        ];
        itemPoints[currentTokenId] = prototypeItemPoints[_prototypeItemId];
        itemRarity[currentTokenId] = prototypeItemRarity[_prototypeItemId];
        miningPower[currentTokenId] = prototypeItemminingPower[
            _prototypeItemId
        ];
        miningChargeTime[currentTokenId] = prototypeItemminingChargeTime[
            _prototypeItemId
        ];
        _mint(_to, totalItems);
        totalItems++;

        emit ItemMinted(currentTokenId, _to, _prototypeItemId);
    }

    function burn(uint256 _tokenId) public isValid whenNotPaused {
        delete itemImage[_tokenId];
        delete itemType[_tokenId];
        delete cooldownBreedTime[_tokenId];
        delete reduceBreedFee[_tokenId];
        delete itemPoints[_tokenId];
        delete itemRarity[_tokenId];
        delete miningPower[_tokenId];
        delete miningChargeTime[_tokenId];
        _burn(_tokenId);
    }

    function lockItem(uint256 _tokenId) public isValid whenNotPaused {
        isItemLock[_tokenId] = true;
    }

    function unlockItem(uint256 _tokenId) public isValid whenNotPaused {
        isItemLock[_tokenId] = false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        require(!isItemLock[tokenId], "Item is locked");
        super.transferFrom(from, to, tokenId);
    }

    function createPrototypeItem(
        string memory _prototypeItemImage,
        ItemRarity _prototypeItemRarity,
        uint256 _prototypeItemCooldownBreedTime,
        uint256 _prototypeItemReduceBreedFee,
        uint256 _prototypeItemPoints,
        ItemType _prototypeItemType,
        uint256 _prototypeItemminingPower,
        uint256 _prototypeItemminingChargeTime
    ) public onlyOwner whenNotPaused {
        if (_prototypeItemRarity > ItemRarity.Epic) {
            revert("Invalid item type");
        }

        uint256 currentPrototypeId = totalPrototypeItems;
        prototypeItemImage[currentPrototypeId] = _prototypeItemImage;
        prototypeItemRarity[currentPrototypeId] = _prototypeItemRarity;
        prototypeItemCooldownBreedTime[
            currentPrototypeId
        ] = _prototypeItemCooldownBreedTime;
        prototypeItemReduceBreedFee[
            currentPrototypeId
        ] = _prototypeItemReduceBreedFee;
        prototypeItemPoints[currentPrototypeId] = _prototypeItemPoints;
        prototypeItemType[currentPrototypeId] = _prototypeItemType;
        prototypeItemminingPower[
            currentPrototypeId
        ] = _prototypeItemminingPower;
        prototypeItemminingChargeTime[
            currentPrototypeId
        ] = _prototypeItemminingChargeTime;

        itemRarityAmount[uint256(_prototypeItemRarity)]++;
        listPrototypeItemsOfRarity[uint256(_prototypeItemRarity)].push(
            currentPrototypeId
        );
        totalPrototypeItems++;
        emit PrototypeItemCreated(currentPrototypeId, msg.sender);
    }

    // Can edit attribute but can't change type of item
    function editItems(
        uint256 _prototypeId,
        string memory _prototypeItemImage,
        ItemRarity _prototypeItemRarity,
        uint256 _prototypeItemCooldownBreedTime,
        uint256 _prototypeItemReduceBreedFee,
        uint256 _prototypeItemPoints,
        uint256 _prototypeItemminingPower,
        uint256 _prototypeItemminingChargeTime
    ) public onlyOwner whenNotPaused {
        require(_prototypeId < totalPrototypeItems, "Invalid prototype id");
        prototypeItemImage[_prototypeId] = _prototypeItemImage;
        prototypeItemRarity[_prototypeId] = _prototypeItemRarity;
        prototypeItemCooldownBreedTime[
            _prototypeId
        ] = _prototypeItemCooldownBreedTime;
        prototypeItemReduceBreedFee[
            _prototypeId
        ] = _prototypeItemReduceBreedFee;
        prototypeItemPoints[_prototypeId] = _prototypeItemPoints;
        prototypeItemminingPower[_prototypeId] = _prototypeItemminingPower;
        prototypeItemminingChargeTime[
            _prototypeId
        ] = _prototypeItemminingChargeTime;
    }

    function getPrototypeForNewItem(
        address _account,
        uint seed
    ) external isValid whenNotPaused returns (uint256 prototypeItemId) {
        uint256 walletSeed = raiGotchiNFT.getWalletSeedAndUpdateIfNeeded();

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    _account,
                    seed,
                    walletSeed
                )
            )
        );
        uint256 randomChance = random % (MAX_CHANCE + 1);
        if (randomChance < epicDropRate) {
            prototypeItemId = listPrototypeItemsOfRarity[
                uint256(ItemRarity.Epic)
            ][random % itemRarityAmount[uint256(ItemRarity.Epic)]];
        } else if (randomChance < legendaryDropRate) {
            prototypeItemId = listPrototypeItemsOfRarity[
                uint256(ItemRarity.Legendary)
            ][random % itemRarityAmount[uint256(ItemRarity.Legendary)]];
        } else if (randomChance < rareDropRate) {
            prototypeItemId = listPrototypeItemsOfRarity[
                uint256(ItemRarity.Rare)
            ][random % itemRarityAmount[uint256(ItemRarity.Rare)]];
        } else {
            prototypeItemId = listPrototypeItemsOfRarity[
                uint256(ItemRarity.Common)
            ][random % itemRarityAmount[uint256(ItemRarity.Common)]];
        }
    }

    function setEpicItemDropRate(uint256 _rate) public onlyOwner {
        require(_rate <= MAX_CHANCE, "Invalid rate");
        epicDropRate = _rate;
    }

    function LegendaryItemDropRate(uint256 _rate) public onlyOwner {
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
                '{"trait_type": "itemType","value":"',
                _uint2str(uint256(itemType[id])),
                '"},{"trait_type": "cooldownBreedTime","value":"',
                _uint2str(cooldownBreedTime[id]),
                '"},{"trait_type": "reduceBreedFee","value":"',
                _uint2str(reduceBreedFee[id])
            ),
            abi.encodePacked(
                '"},{"trait_type": "itemPoints","value":"',
                _uint2str(itemPoints[id]),
                '"},{"trait_type": "itemRarity","value":"',
                _uint2str(uint256(itemRarity[id])),
                '"},{"trait_type": "miningPower","value":"',
                _uint2str(miningPower[id]),
                '"},{"trait_type": "miningChargeTime","value":"',
                _uint2str(miningChargeTime[id]),
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
                                '{"name":"Rai Gotchi Item#',
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

    // Use to set allow for contract breed, stake, raigotchi
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
