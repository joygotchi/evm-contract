// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IJoyGotchiItem {
    function isAccessoryItem(uint256 id) external view returns (bool);

    function isStakeItem(uint256 id) external view returns (bool);

    function isBreedItem(uint256 id) external view returns (bool);

    function isArcadeItem(uint256 id) external view returns (bool);

    function reduceBreedTimePercent(uint256 id) external view returns (uint256);

    function reduceBreedFeePercent(uint256 id) external view returns (uint256);

    function breedSuccessRate(uint256 id) external view returns (uint256);

    function itemSpawnRate(uint256 id) external view returns (uint256);

    function itemPoints(uint256 id) external view returns (uint256);

    function typeItem(uint256 id) external view returns (uint256);

    function burnAfterUsed(uint256 id) external view returns (bool);

    function timePerClaim(uint256 id) external view returns (uint256);

    function mint(address _to, uint256 _prototypeItemId) external;

    function burn(uint256 _tokenId) external;

    function lockToken(uint256 _tokenId) external;

    function unlockToken(uint256 _tokenId) external;

    function getPrototypeForNewItem(
        address _account,
        uint seed,
        uint256 additionalItemSpawnRate
    ) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);
}
