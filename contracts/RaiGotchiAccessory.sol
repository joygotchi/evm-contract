// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IRaiGotchi.sol";
import "./interfaces/IToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract RaiGotchiAccessory is Ownable, Pausable {
    IRaiGotchi public raiGotchiNFT;
    IToken public token;
    address public treasury;

    uint256 public _itemIds;

    // Accessory items for the pet
    mapping(uint256 => uint256) public typeBackground;
    mapping(uint256 => uint256) public furniture;
    mapping(uint256 => uint256) public itemPrice;

    // Pet accessories struct
    struct PetAccessoryBag {
        uint256 accessoryId;
        bool isUsed;
    }

    // Mapping from pet ID to its accessories bag
    mapping(uint256 => PetAccessoryBag[]) public petAccessories;

    event AccessoryCreated(
        uint256 id,
        uint256 typeBackground,
        uint256 furniture,
        uint256 price
    );

    event AccessoryPurchased(uint256 nftId, address giver, uint256 itemId);

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
        return itemId < _itemIds;
    }

    function getItemInfo(
        uint256 _itemId
    )
        public
        view
        returns (uint256 _typeBackground, uint256 _furniture, uint256 _price)
    {
        require(itemExists(_itemId), "This item doesn't exist");

        _typeBackground = typeBackground[_itemId];
        _furniture = furniture[_itemId];
        _price = itemPrice[_itemId];
    }

    function getPetAccessories(
        uint256 nftId
    ) public view returns (PetAccessoryBag[] memory) {
        return petAccessories[nftId];
    }

    function buyAccessoryItem(
        uint256 nftId,
        uint256 itemId
    ) external payable isApproved(nftId) whenNotPaused {
        require(itemExists(itemId), "This item doesn't exist");
        require(raiGotchiNFT.isPetAlive(nftId), "Pet dead");

        // Check if the pet already owns the accessory
        for (uint256 i = 0; i < petAccessories[nftId].length; i++) {
            require(
                petAccessories[nftId][i].accessoryId != itemId,
                "Pet already has this accessory"
            );
        }

        uint256 amount = itemPrice[itemId];
        token.transferFrom(msg.sender, treasury, amount);

        // Add the accessory to the pet's accessories bag
        petAccessories[nftId].push(PetAccessoryBag(itemId, false));

        emit AccessoryPurchased(nftId, msg.sender, itemId);
    }

    // Add items
    function createAccessory(
        uint256 _typeBackground,
        uint256 _furniture,
        uint256 _price
    ) external onlyOwner whenNotPaused {
        uint256 newItemId = _itemIds;

        require(
            (_typeBackground > 0 && _furniture == 0) ||
                (_typeBackground == 0 && _furniture > 0),
            "Item must be either a background or furniture"
        );

        typeBackground[newItemId] = _typeBackground;
        furniture[newItemId] = _furniture;
        itemPrice[newItemId] = _price;

        _itemIds++;

        emit AccessoryCreated(newItemId, _typeBackground, _furniture, _price);
    }

    function editAccessory(
        uint256 _id,
        uint256 _typeBackground,
        uint256 _furniture,
        uint256 _price
    ) external onlyOwner whenNotPaused {
        require(itemExists(_id), "This item doesn't exist");

        typeBackground[_id] = _typeBackground;
        furniture[_id] = _furniture;
        itemPrice[_id] = _price;
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
