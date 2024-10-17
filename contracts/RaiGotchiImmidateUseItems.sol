// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IRaiGotchi.sol";
import "./interfaces/IToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract RaiGotchiImmidiateUseItems is Ownable, Pausable {
    IRaiGotchi public raiGotchiNFT;
    IToken public token;
    address public treasury;

    uint256 public _itemIds;

    // items/benefits for the pet, general so can be food or anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPriceDelta;
    mapping(uint256 => uint256) public itemStock;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;
    mapping(uint256 => uint256) public itemShield;
    mapping(uint256 => bool) public itemIsRevival;

    // Struct to track purchased items that have not been used yet
    struct BagItemUsed {
        uint256 itemId;
        bool isUsed;
    }

    // Mapping from pet ID to its purchased items (bag)
    mapping(uint256 => BagItemUsed[]) public petBag;

    event ImidiateUseItemCreated(
        uint256 id,
        string name,
        uint256 price,
        uint256 points,
        uint256 timeExtension,
        uint256 shield,
        bool isRevival
    );

    event ItemPurchased(uint256 nftId, address buyer, uint256 itemId);
    event ItemConsumed(uint256 nftId, address user, uint256 itemId);

    constructor(address _raiGotchiNFT, address _treasury, address _token) {
        raiGotchiNFT = IRaiGotchi(_raiGotchiNFT);
        treasury = _treasury;
        token = IToken(_token);
    }

    modifier isApproved(uint256 id) {
        require(
            raiGotchiNFT.ownerOf(id) == msg.sender ||
                raiGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    function itemExists(uint256 itemId) public view returns (bool) {
        return bytes(itemName[itemId]).length > 0;
    }

    function getImidiateUseItemInfo(
        uint256 _itemId
    )
        public
        view
        returns (
            string memory _name,
            uint256 _price,
            uint256 _stock,
            uint256 _points,
            uint256 _timeExtension,
            uint256 _shield
        )
    {
        _name = itemName[_itemId];
        _price = itemPrice[_itemId];
        _stock = itemStock[_itemId];
        _timeExtension = itemTimeExtension[_itemId];
        _points = itemPoints[_itemId];
        _shield = itemShield[_itemId];
    }

    function getPetBag(uint256 nftId) public view returns (BagItemUsed[] memory) {
        return petBag[nftId];
    }

    // Function to buy an item and add it to the pet's bag
    function buyImidiateUseItem(
        uint256 nftId,
        uint256 itemId
    ) external payable isApproved(nftId) whenNotPaused {
        require(itemExists(itemId), "This item doesn't exist");
        require(
            raiGotchiNFT.isPetAlive(nftId) ||
                (!raiGotchiNFT.isPetAlive(nftId) && itemIsRevival[itemId]),
            "Pet is dead or not a revival item"
        );
        require(itemStock[itemId] > 0, "Out of stock");

        uint256 amount = itemPrice[itemId];

        itemPrice[itemId] += itemPriceDelta[itemId];
        itemStock[itemId] -= 1;

        token.transferFrom(msg.sender, treasury, amount);

        // Add the purchased item to the pet's bag
        petBag[nftId].push(BagItemUsed(itemId, false));

        emit ItemPurchased(nftId, msg.sender, itemId);
    }

    // Function to consume an item from the pet's bag
    function consumeItem(uint256 nftId, uint256 itemId) external isApproved(nftId) whenNotPaused {
        require(raiGotchiNFT.isPetAlive(nftId), "Pet is dead");
        
        bool itemFound = false;

        for (uint256 i = 0; i < petBag[nftId].length; i++) {
            if (petBag[nftId][i].itemId == itemId && !petBag[nftId][i].isUsed) {
                petBag[nftId][i].isUsed = true;
                itemFound = true;
                break;
            }
        }

        require(itemFound, "Item not found or already used");

        // Apply item effects to the pet
        raiGotchiNFT.onConsumeImmidiateUseItem(
            nftId,
            itemTimeExtension[itemId],
            itemShield[itemId],
            itemPoints[itemId]
        );

        raiGotchiNFT.getWalletSeedAndUpdateIfNeeded();
        raiGotchiNFT.checkPetEvoleAndUpdateIfNeeded(nftId);

        emit ItemConsumed(nftId, msg.sender, itemId);
    }

    // Add items
    function createImidiateUseItem(
        string calldata name,
        uint256 price,
        uint256 priceDelta,
        uint256 stock,
        uint256 points,
        uint256 timeExtension,
        uint256 shield,
        bool isRevival
    ) external onlyOwner whenNotPaused {
        uint256 newItemId = _itemIds;
        itemName[newItemId] = name;
        itemPrice[newItemId] = price;
        itemPriceDelta[newItemId] = priceDelta;
        itemStock[newItemId] = stock;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;
        itemShield[newItemId] = shield;
        itemIsRevival[newItemId] = isRevival;

        _itemIds++;

        emit ImidiateUseItemCreated(
            newItemId,
            name,
            price,
            points,
            timeExtension,
            shield,
            isRevival
        );
    }

    function editImidiateUseItem(
        uint256 _id,
        string calldata _name,
        uint256 _price,
        uint256 _priceDelta,
        uint256 _stock,
        uint256 _points,
        uint256 _timeExtension,
        uint256 _shield,
        bool _isRevival
    ) external onlyOwner whenNotPaused {
        require(_id < _itemIds, "Item doesn't exist");
        itemPrice[_id] = _price;
        itemPriceDelta[_id] = _priceDelta;
        itemStock[_id] = _stock;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
        itemShield[_id] = _shield;
        itemIsRevival[_id] = _isRevival;
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
