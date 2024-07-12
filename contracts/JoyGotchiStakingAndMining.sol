// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./interfaces/IJoyGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./JoyGotchiEnum.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract JoyGotchiStaking is Ownable {
    IJoyGotchi public joyGotchiNFT;
    IJoyGotchiItem public joyGotchiNFTItem;
    IToken public token;
    address public treasury;

    struct PoolInfo {
        string name;
        uint256[] rewardNFTIds;
        uint256 stakingStartTime;
        uint256 stakingEndTime;
        uint256 maxSlotsInPool;
        uint256 tokenRewardPerSlot;
        uint256 maxSlotPerWallet;
        uint256 totalStakedSlot;
    }

    uint256 public pricePerSlot;

    uint256 public poolIds;

    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(address => mapping(uint256 => uint256)) public userStakedPetCount;
    mapping(uint256 => address) public stakedPetOwner;

    event StakingPoolCreated(
        uint256 poolId,
        string name,
        uint256 stakingStartTime,
        uint256 stakingEndTime,
        uint256 maxSlotsInPool,
        uint256 tokenRewardPerSlot,
        uint256 maxSlotPerWallet
    );

    event PetStaked(uint256 nftId, uint256 poolId);
    event PetUnstaked(
        uint256 nftId,
        uint256 poolId,
        uint256[] rewardItems,
        uint256 rewardToken
    );

    constructor(
        address _joyGotchiNFT,
        address _joyGotchiNFTItem,
        address _token,
        address _treasury
    ) {
        joyGotchiNFT = IJoyGotchi(_joyGotchiNFT);
        joyGotchiNFTItem = IJoyGotchiItem(_joyGotchiNFTItem);
        token = IToken(_token);
        treasury = _treasury;
        pricePerSlot = 35 ether;
    }

    function createNewStakingPool(
        string memory _name,
        uint256[] memory _rewardNFTIds,
        uint256 _stakingStartTime,
        uint256 _stakingEndTime,
        uint256 _maxSlotsInPool,
        uint256 _tokenRewardPerSlot,
        uint256 _maxSlotPerWallet
    ) public onlyOwner {
        for (uint i = 0; i < _rewardNFTIds.length; i++) {
            require(
                _rewardNFTIds[i] < joyGotchiNFTItem.totalPrototypeItems(),
                "NFT ID not exist"
            );
        }

        require(_maxSlotsInPool > 0, "Max slots must be greater than 0");
        require(
            _tokenRewardPerSlot > 0,
            "Token reward per slot must be greater than 0"
        );
        require(
            _maxSlotPerWallet > 0,
            "Max slot per wallet must be greater than 0"
        );

        uint256 totalTokensForReward = _tokenRewardPerSlot * _maxSlotsInPool;

        token.transferFrom(msg.sender, address(this), totalTokensForReward);

        PoolInfo memory newPool = PoolInfo({
            name: _name,
            rewardNFTIds: _rewardNFTIds,
            stakingStartTime: _stakingStartTime,
            stakingEndTime: _stakingEndTime,
            maxSlotsInPool: _maxSlotsInPool,
            tokenRewardPerSlot: _tokenRewardPerSlot,
            maxSlotPerWallet: _maxSlotPerWallet,
            totalStakedSlot: 0
        });

        poolInfo[poolIds] = newPool;

        poolIds++;
        emit StakingPoolCreated(
            poolIds,
            _name,
            _stakingStartTime,
            _stakingEndTime,
            _maxSlotsInPool,
            _tokenRewardPerSlot,
            _maxSlotPerWallet
        );
    }

    function stake(uint256 _nftId, uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];

        require(_poolId < poolIds, "Pool ID not exist");

        require(
            joyGotchiNFT.ownerOf(_nftId) == msg.sender,
            "You are not the owner of this pet"
        );

        require(
            pool.stakingStartTime > block.timestamp,
            "Staking pool has started"
        );

        require(
            userStakedPetCount[msg.sender][_poolId] < pool.maxSlotPerWallet,
            "You have reached the maximum slot per wallet"
        );

        require(
            pool.totalStakedSlot < pool.maxSlotsInPool,
            "Staking pool is full"
        );

        require(
            joyGotchiNFT.isPetAlive(_nftId),
            "Your pet is dead, you cannot stake it"
        );

        require(
            joyGotchiNFT.isPetLocked(_nftId) == false,
            "Your pet is locked, you cannot stake it"
        );

        token.transferFrom(msg.sender, treasury, pool.tokenRewardPerSlot);

        userStakedPetCount[msg.sender][_poolId]++;

        poolInfo[_poolId].totalStakedSlot++;

        stakedPetOwner[_nftId] = msg.sender;

        joyGotchiNFT.lockPet(_nftId);

        emit PetStaked(_nftId, _poolId);
    }

    function unstake(uint256 _nftId, uint256 _poolId) public {
        PoolInfo memory pool = poolInfo[_poolId];

        require(_poolId < poolIds, "Invalid pool id");

        address _stakedPetOwner = stakedPetOwner[_nftId];

        require(_stakedPetOwner == msg.sender, "Not pet owner");

        require(
            joyGotchiNFT.isPetLocked(_nftId),
            "Your pet is not locked, you cannot unstake it"
        );

        require(
            pool.stakingEndTime < block.timestamp,
            "Staking pool has not ended yet"
        );

        for (uint i = 0; i < pool.rewardNFTIds.length; i++) {
            joyGotchiNFTItem.mint(_stakedPetOwner, pool.rewardNFTIds[i]);
        }

        stakedPetOwner[_nftId] = address(0);

        token.transfer(_stakedPetOwner, pool.tokenRewardPerSlot);
        joyGotchiNFT.unlockPet(_nftId);

        emit PetUnstaked(
            _nftId,
            _poolId,
            pool.rewardNFTIds,
            pool.tokenRewardPerSlot
        );
    }

    function ownerWithdrawRedundantToken(uint256 _poolId) public onlyOwner {
        PoolInfo memory pool = poolInfo[_poolId];

        require(
            pool.stakingEndTime < block.timestamp,
            "Staking pool has not ended yet"
        );

        uint256 totalTokensForReward = pool.tokenRewardPerSlot *
            pool.maxSlotsInPool;
        uint256 tokenDistributed = pool.tokenRewardPerSlot *
            pool.totalStakedSlot;

        uint256 redundantToken = totalTokensForReward - tokenDistributed;

        token.transfer(msg.sender, redundantToken);
    }

    function setPricePerSlot(uint256 _pricePerSlot) public onlyOwner {
        pricePerSlot = _pricePerSlot;
    }

    function convertSecondsToHours(
        uint256 _seconds
    ) public pure returns (uint256) {
        // There are 3600 seconds in one hour
        uint256 _hours = _seconds / 3600;
        return _hours;
    }
}
