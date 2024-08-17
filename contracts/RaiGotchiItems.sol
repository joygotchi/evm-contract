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
    mapping(uint256 => bool) public isPetMintToCard;

    // Species attributes
    uint256 speciesCount;
    mapping(uint256 => uint256) public speciesAttackPoints;
    mapping(uint256 => uint256) public speciesDefensePoints;

    // Item properties
    uint256 public totalItems;
    mapping(uint256 => string) public itemImage;
    mapping(uint256 => ItemType) public itemType;
    mapping(uint256 => ItemRarity) public itemRarity;
    mapping(uint256 => uint256) public miningPower;
    mapping(uint256 => uint256) public miningChargeTime;
    mapping(uint256 => uint256) public nftPetType;
    mapping(uint256 => uint256) public petAttack;
    mapping(uint256 => uint256) public petDefense;
    mapping(uint256 => uint256) public petStar;

    // Prototype Item (this logic is for later add more item types)
    // For current logic there is only 2 type item: mineTool and petCard and these 2 logic is seperate
    uint256 public totalPrototypeItems;
    mapping(uint256 => uint256) public itemRarityAmount;
    mapping(uint256 => uint256[]) listPrototypeItemsOfRarity;
    mapping(uint256 => string) prototypeItemImage;
    mapping(uint256 => ItemType) prototypeItemType;
    mapping(uint256 => ItemRarity) prototypeItemRarity;
    mapping(uint256 => uint256) prototypeItemminingPower;
    mapping(uint256 => uint256) prototypeItemminingChargeTime;

    // Item chance
    uint256 public constant MAX_CHANCE = 100;
    uint256 public epicDropRate = 5;
    uint256 public legendaryDropRate = 10;
    uint256 public rareDropRate = 20;
    uint256 public commonDropRate = 100;

    mapping(uint256 => bool) public isItemLock;

    event PrototypeItemCreated(
        uint256 indexed prototypeId,
        address indexed owner
    );
    event ItemMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed prototypeId
    );

    event PetCardMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 petType,
        uint256 petAttack,
        uint256 petDefense,
        uint256 petStar
    );

    constructor(address _raiGotchiNFT) ERC721("Rai Gotchi Items", "RGCItems") {
        raiGotchiNFT = IRaiGotchi(_raiGotchiNFT);
    }

    modifier isValid() {
        require(_allowAddress[msg.sender], "not authorize");
        _;
    }

    modifier isApprovedRaiGotchiNFT(uint256 id) {
        require(
            raiGotchiNFT.ownerOf(id) == msg.sender ||
                raiGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    function getSpeciesAttribute(
        uint256 _speciesId
    ) public view returns (uint256 _attackPoints, uint256 _defensePoints) {
        _attackPoints = speciesAttackPoints[_speciesId];
        _defensePoints = speciesDefensePoints[_speciesId];
    }

    function getPetCardAttribute(
        uint256 _id
    )
        public
        view
        returns (
            uint256 _nftPetType,
            uint256 _petAttack,
            uint256 _petDefense,
            uint256 _petStar
        )
    {
        _nftPetType = nftPetType[_id];
        _petAttack = petAttack[_id];
        _petDefense = petDefense[_id];
        _petStar = petStar[_id];
    }

    function getMiningItemAttribute(
        uint256 _id
    )
        public
        view
        returns (
            ItemType _itemType,
            ItemRarity _itemRarity,
            uint256 _miningPower,
            uint256 _miningChargeTime
        )
    {
        _itemType = itemType[_id];
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

    // Pet card is an NFT that is transform from your NFT Pet
    function mintPetCard(
        uint256 _petId
    ) public isApprovedRaiGotchiNFT(_petId) whenNotPaused {
        require(!isPetMintToCard[_petId], "Pet card already minted");
        uint256 speciesId = raiGotchiNFT.petSpecies(_petId);
        uint256 currentTokenId = totalItems;
        isPetMintToCard[_petId] = true;
        itemType[currentTokenId] = ItemType.PETCARD;
        itemImage[currentTokenId] = "";
        itemRarity[currentTokenId] = ItemRarity.Common;
        nftPetType[currentTokenId] = speciesId;
        petAttack[currentTokenId] = speciesAttackPoints[speciesId];
        petDefense[currentTokenId] = speciesDefensePoints[speciesId];
        petStar[currentTokenId] = 1;
        _mint(msg.sender, totalItems);
        totalItems++;

        emit PetCardMinted(
            currentTokenId,
            msg.sender,
            speciesId,
            speciesAttackPoints[speciesId],
            speciesDefensePoints[speciesId],
            1
        );
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
        ItemType _prototypeItemType,
        uint256 _prototypeItemminingPower,
        uint256 _prototypeItemminingChargeTime
    ) public onlyOwner whenNotPaused {
        if (_prototypeItemRarity > ItemRarity.Epic) {
            revert("Invalid item type");
        }

        // Pet card can't be created here
        require(_prototypeItemType != ItemType.PETCARD, "Invalid item type");

        uint256 currentPrototypeId = totalPrototypeItems;
        prototypeItemImage[currentPrototypeId] = _prototypeItemImage;
        prototypeItemRarity[currentPrototypeId] = _prototypeItemRarity;
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
        uint256 _prototypeItemminingPower,
        uint256 _prototypeItemminingChargeTime
    ) public onlyOwner whenNotPaused {
        require(_prototypeId < totalPrototypeItems, "Invalid prototype id");
        prototypeItemImage[_prototypeId] = _prototypeItemImage;
        prototypeItemminingPower[_prototypeId] = _prototypeItemminingPower;
        prototypeItemminingChargeTime[
            _prototypeId
        ] = _prototypeItemminingChargeTime;
    }

    /**
        @notice Keep in mind that each time new species is created in gene pool, this function should be invoke by owner
        In order to keep the consistency between species contracts and items contract
        Or else the pet card will not be able to mint
    */
    function addSpeciesAttackAndDefensePoints(
        uint256 _attackPoints,
        uint256 _defensePoints
    ) public onlyOwner whenNotPaused {
        uint256 currentSpeciesId = speciesCount;
        speciesAttackPoints[currentSpeciesId] = _attackPoints;
        speciesDefensePoints[currentSpeciesId] = _defensePoints;
        speciesCount++;
    }

    function editSpeciesAttackAndDefensePoints(
        uint256 _speciesId,
        uint256 _attackPoints,
        uint256 _defensePoints
    ) public onlyOwner whenNotPaused {
        require(_speciesId < speciesCount, "Invalid species id");
        speciesAttackPoints[_speciesId] = _attackPoints;
        speciesDefensePoints[_speciesId] = _defensePoints;
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
                '{"trait_type": "itemType","value":"',
                _uint2str(uint256(itemType[id])),
                '"},{"trait_type": "itemRarity","value":"',
                _uint2str(uint256(itemRarity[id])),
                '"},{"trait_type": "miningPower","value":"',
                _uint2str(miningPower[id]),
                '"},{"trait_type": "miningChargeTime","value":"',
                _uint2str(miningChargeTime[id])
            ),
            abi.encodePacked(
                '"},{"trait_type": "nftPetType","value":"',
                _uint2str(nftPetType[id]),
                '"},{"trait_type": "petAttack","value":"',
                _uint2str(petAttack[id]),
                '"},{"trait_type": "petDefense","value":"',
                _uint2str(petDefense[id]),
                '"},{"trait_type": "petStar","value":"',
                _uint2str(petStar[id]),
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

    // Use to set allow for contract mining
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
