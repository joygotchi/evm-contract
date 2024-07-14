// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./interfaces/IJoyGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./JoyGotchiEnum.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract JoyGotchiStakingAndMining is Ownable {
    IJoyGotchi public joyGotchiNFT;
    IJoyGotchiItem public joyGotchiNFTItem;
    IToken public token;
    address public treasury;

    // Staking pool info
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

    // Mining pool
    string public miningPoolName;
    uint256 public miningPowerMultiplier;
    uint256 public chargeOfTimeMultiplier;
    uint256 public pointsUsedPerRedemn;
    uint256 public tokenEarnedPerRedemn;
    mapping(address => uint256) public miningPoints;
    mapping(uint256 => address) public miningToolOwner;
    mapping(address => uint256) public totalMiningPower;
    mapping(address => uint256) public totalMiningChargeTime;
    mapping(address => uint256) public lastMiningTime;
    mapping(address => uint256[]) public miningToolUsed;

    uint256 public constant MAX_MINING_TOOL = 3;
    uint256 public constant BASE_DENOMINAOR = 1000;

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

    event MiningToolAdded(uint256 toolId, address owner);

    event MiningToolRemoved(uint256 toolId, address owner);

    event Mined(address owner, uint256 pointsEarned);

    event PointsRedemed(address owner, uint256 prototypeTokenIds);

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

    modifier isApprovedJoyGotchiNFT(uint256 id) {
        require(
            joyGotchiNFT.ownerOf(id) == msg.sender ||
                joyGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    modifier isApprovedJoyGotchiNFTItem(uint256 id) {
        require(
            joyGotchiNFTItem.ownerOf(id) == msg.sender ||
                joyGotchiNFTItem.getApproved(id) == msg.sender,
            "Item not approved"
        );
        _;
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

    function stake(
        uint256 _nftId,
        uint256 _poolId
    ) public isApprovedJoyGotchiNFT(_nftId) {
        PoolInfo storage pool = poolInfo[_poolId];

        require(_poolId < poolIds, "Pool ID not exist");

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

    function addMiningTool(
        uint256 _toolId
    ) public isApprovedJoyGotchiNFTItem(_toolId) {
        require(
            joyGotchiNFTItem.itemType(_toolId) == ItemType.MINETOOL,
            "This item is not a mining tool"
        );

        require(
            miningToolUsed[msg.sender].length < MAX_MINING_TOOL,
            "You have reached the maximum mining tool"
        );

        require(
            miningToolOwner[_toolId] == address(0),
            "Mining tool is already used"
        );

        require(
            joyGotchiNFTItem.isItemLock(_toolId) == false,
            "This tool is locked"
        );

        joyGotchiNFTItem.lockItem(_toolId);

        uint256 miningPower = joyGotchiNFTItem.miningPower(_toolId);
        uint256 newToolChargeTime = joyGotchiNFTItem.miningChargeTime(_toolId);

        miningToolUsed[msg.sender].push(_toolId);

        if (miningToolUsed[msg.sender].length == 2) {
            uint256 firstToolChargeTime = joyGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][0]
            );

            uint256 shorterChargeTimeToolId = firstToolChargeTime <
                newToolChargeTime
                ? miningToolUsed[msg.sender][0]
                : _toolId;
            uint256 reducedChargeTime = joyGotchiNFTItem.miningChargeTime(
                shorterChargeTimeToolId
            ) / 2;

            totalMiningChargeTime[msg.sender] =
                totalMiningChargeTime[msg.sender] -
                reducedChargeTime +
                newToolChargeTime;
        } else if (miningToolUsed[msg.sender].length == 3) {
            uint256 firstToolChargeTime = joyGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][0]
            );
            uint256 secondToolChargeTime = joyGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][1]
            );

            uint256 shorterChargeTimeToolId = firstToolChargeTime <
                secondToolChargeTime
                ? miningToolUsed[msg.sender][0]
                : miningToolUsed[msg.sender][1];
            uint256 shortestChargeTimeToolId = joyGotchiNFTItem
                .miningChargeTime(shorterChargeTimeToolId) < newToolChargeTime
                ? shorterChargeTimeToolId
                : _toolId;

            uint256 reducedChargeTime = joyGotchiNFTItem.miningChargeTime(
                shortestChargeTimeToolId
            );

            totalMiningChargeTime[msg.sender] =
                totalMiningChargeTime[msg.sender] -
                reducedChargeTime +
                newToolChargeTime;
        } else {
            totalMiningChargeTime[msg.sender] += joyGotchiNFTItem
                .miningChargeTime(_toolId);
        }

        totalMiningPower[msg.sender] += miningPower;
        miningToolOwner[_toolId] = msg.sender;

        if (lastMiningTime[msg.sender] == 0) {
            lastMiningTime[msg.sender] = block.timestamp;
        }

        emit MiningToolAdded(_toolId, msg.sender);
    }

    function removeMiningTool(uint256 _toolId) public {
        require(
            miningToolOwner[_toolId] == msg.sender,
            "You are not the owner of this tool"
        );

        joyGotchiNFTItem.unlockItem(_toolId);

        uint256 miningPower = joyGotchiNFTItem.miningPower(_toolId);

        uint256 chargeOfTime = joyGotchiNFTItem.miningChargeTime(_toolId);

        totalMiningPower[msg.sender] -= miningPower;

        if (totalMiningChargeTime[msg.sender] < chargeOfTime) {
            totalMiningChargeTime[msg.sender] = 0;
        } else {
            totalMiningChargeTime[msg.sender] -= chargeOfTime;
        }

        miningToolOwner[_toolId] = address(0);

        _removeItemFromListTool(_toolId);

        emit MiningToolRemoved(_toolId, msg.sender);
    }

    function mining() public {
        require(
            totalMiningPower[msg.sender] > 0,
            "You do not have any mining tool"
        );

        uint256 totalMiningChargeOfTime = (chargeOfTimeMultiplier *
            totalMiningPower[msg.sender]) / BASE_DENOMINAOR;

        require(
            lastMiningTime[msg.sender] + totalMiningChargeOfTime >
                block.timestamp,
            "You need to wait for the mining tool to be charged"
        );

        lastMiningTime[msg.sender] = block.timestamp;

        uint256 totalPointsMined = miningPowerMultiplier *
            totalMiningPower[msg.sender];

        miningPoints[msg.sender] += totalPointsMined;

        emit Mined(msg.sender, totalPointsMined);
    }

    function redemnMiningPoints() public {
        uint256 _miningPoints = miningPoints[msg.sender];

        require(
            _miningPoints >= pointsUsedPerRedemn,
            "You do not have enough mining point"
        );

        miningPoints[msg.sender] -= pointsUsedPerRedemn;

        uint256 prototypeTokenId = joyGotchiNFTItem.getPrototypeForNewItem(
            msg.sender,
            _miningPoints
        );

        joyGotchiNFTItem.mint(msg.sender, prototypeTokenId);

        token.transfer(msg.sender, tokenEarnedPerRedemn);

        emit PointsRedemed(msg.sender, prototypeTokenId);
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

    function configureMiningPool(
        string memory _name,
        uint256 _miningPowerMultiplier,
        uint256 _chargeOfTimeMultiplier
    ) public onlyOwner {
        miningPoolName = _name;
        miningPowerMultiplier = _miningPowerMultiplier;
        chargeOfTimeMultiplier = _chargeOfTimeMultiplier;
    }

    function setMiningPointsUsedPerRedemn(uint256 _points) public onlyOwner {
        pointsUsedPerRedemn = _points;
    }

    function setTokenEarnedPerRedemn(uint256 _token) public onlyOwner {
        tokenEarnedPerRedemn = _token;
    }

    function setPricePerSlot(uint256 _pricePerSlot) public onlyOwner {
        pricePerSlot = _pricePerSlot;
    }

    function _removeItemFromListTool(uint256 _value) private {
        uint256[] memory userListMiningTool = miningToolUsed[msg.sender];
        for (uint256 i = 0; i < userListMiningTool.length; i++) {
            if (userListMiningTool[i] == _value) {
                miningToolUsed[msg.sender][i] = userListMiningTool[
                    userListMiningTool.length - 1
                ];
                miningToolUsed[msg.sender].pop();
                break;
            }
        }
    }
}
