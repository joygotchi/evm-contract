// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../helper/RaiGotchiEnum.sol";

interface IRaiGotchiItem {
    function itemType(uint256 id) external view returns (ItemType);

    function miningPower(uint256 id) external view returns (uint256);

    function miningChargeTime(uint256 id) external view returns (uint256);

    function mint(address _to, uint256 _prototypeItemId) external;

    function burn(uint256 _tokenId) external;

    function lockItem(uint256 _tokenId) external;

    function unlockItem(uint256 _tokenId) external;

    function getPrototypeForNewItem(
        address _account,
        uint seed
    ) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function totalPrototypeItems() external view returns (uint256);

    function isItemLock(uint256 tokenId) external view returns (bool);
}
