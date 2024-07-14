// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./interfaces/IToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract JoyGotchiImmidiateUseItems is Ownable {
    IJoyGotchi public joyGotchiNFT;
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
    mapping(uint256 => uint256) public itemAttackBoost;
    mapping(uint256 => uint256) public itemDefenseBoost;
    mapping(uint256 => bool) public itemIsRevival;

    event ImidiateUseItemCreated(
        uint256 id,
        string name,
        uint256 price,
        uint256 points,
        uint256 timeExtension,
        uint256 shield,
        uint256 itemAttackBoost,
        uint256 itemDefenseBoost,
        bool isRevival
    );

    event ItemConsumed(uint256 nftId, address giver, uint256 itemId);

    constructor(address _joyGotchiNFT, address _treasury, address _token) {
        joyGotchiNFT = IJoyGotchi(_joyGotchiNFT);
        treasury = _treasury;
        token = IToken(_token);
    }

    modifier isApproved(uint256 id) {
        require(
            joyGotchiNFT.ownerOf(id) == msg.sender ||
                joyGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    function itemExists(uint256 itemId) public view returns (bool) {
        if (bytes(itemName[itemId]).length > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getImidiateUseItemInfo(
        uint256 _itemId
    )
        public
        view
        returns (
            string memory _name,
            uint256 _price,
            uint256 _points,
            uint256 _timeExtension
        )
    {
        _name = itemName[_itemId];
        _price = itemPrice[_itemId];
        _timeExtension = itemTimeExtension[_itemId];
        _points = itemPoints[_itemId];
    }

    function buyImidiateUseItem(
        uint256 nftId,
        uint256 itemId
    ) external payable isApproved(nftId) {
        require(itemExists(itemId), "This item doesn't exist");
        require(
            joyGotchiNFT.isPetAlive(nftId) ||
                (!joyGotchiNFT.isPetAlive(nftId) && itemIsRevival[itemId]),
            "pet dead or not revival item"
        ); //no revives
        require(itemStock[itemId] > 0, "Out of stock");

        // if (!shouldContinue) return;

        uint256 amount = itemPrice[itemId];

        joyGotchiNFT.onComsumeImmidiateUseItem(
            nftId,
            itemTimeExtension[itemId],
            itemShield[itemId]
        );

        joyGotchiNFT.addPetScoreAfterUsedItem(nftId, itemPoints[itemId]);

        itemPrice[itemId] += itemPriceDelta[itemId];
        itemStock[itemId] -= 1;

        token.transferFrom(msg.sender, treasury, amount);

        joyGotchiNFT.getWalletSeedAndUpdateIfNeeded();
        joyGotchiNFT.checkPetEvoleAndUpdateIfNeeded(nftId);

        emit ItemConsumed(nftId, msg.sender, itemId);
    }

    // add items
    function createImidiateUseItem(
        string calldata name,
        uint256 price,
        uint256 priceDelta,
        uint256 stock,
        uint256 points,
        uint256 timeExtension,
        uint256 shield,
        uint256 attackBoost,
        uint256 defenseBoost,
        bool isRevival
    ) external onlyOwner {
        uint256 newItemId = _itemIds;
        itemName[newItemId] = name;
        itemPrice[newItemId] = price;
        itemPriceDelta[newItemId] = priceDelta;
        itemStock[newItemId] = stock;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;
        itemShield[newItemId] = shield;
        itemAttackBoost[newItemId] = attackBoost;
        itemDefenseBoost[newItemId] = defenseBoost;
        itemIsRevival[newItemId] = isRevival;

        _itemIds++;

        emit ImidiateUseItemCreated(
            newItemId,
            name,
            price,
            points,
            timeExtension,
            shield,
            attackBoost,
            defenseBoost,
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
    ) external onlyOwner {
        itemPrice[_id] = _price;
        itemPriceDelta[_id] = _priceDelta;
        itemStock[_id] = _stock;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
        itemShield[_id] = _shield;
        itemIsRevival[_id] = _isRevival;
    }
}
