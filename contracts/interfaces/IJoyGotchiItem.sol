// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../JoyGotchiEnum.sol";

interface IJoyGotchiItem {
    function itemType(uint256 id) external view returns (ItemType);

    function cooldownBreedTime(uint256 id) external view returns (uint256);

    function reduceBreedFee(uint256 id) external view returns (uint256);

    function breedSuccessRate(uint256 id) external view returns (uint256);

    function itemSpawnRate(uint256 id) external view returns (uint256);

    function itemPoints(uint256 id) external view returns (uint256);

    function typeItem(uint256 id) external view returns (uint256);

    function burnAfterUsed(uint256 id) external view returns (bool);

    function timePerClaim(uint256 id) external view returns (uint256);

    function mint(address _to, uint256 _prototypeItemId) external;

    function burn(uint256 _tokenId) external;

    function lockItem(uint256 _tokenId) external;

    function unlockItem(uint256 _tokenId) external;

    function getPrototypeForNewItem(
        address _account,
        uint seed,
        uint256 additionalItemSpawnRate
    ) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function totalPrototypeItems() external view returns (uint256);
}
