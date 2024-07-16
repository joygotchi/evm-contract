// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IRaiGotchi.sol";
import "./interfaces/IRaiGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./helper/RaiGotchiEnum.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract RaiGotchiStakingAndMining is Ownable, Pausable {
    IRaiGotchi public raiGotchiNFT;
    IRaiGotchiItem public raiGotchiNFTItem;
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
        address _raiGotchiNFT,
        address _raiGotchiNFTItem,
        address _token,
        address _treasury
    ) {
        raiGotchiNFT = IRaiGotchi(_raiGotchiNFT);
        raiGotchiNFTItem = IRaiGotchiItem(_raiGotchiNFTItem);
        token = IToken(_token);
        treasury = _treasury;
        pricePerSlot = 35 ether;
    }

    modifier isApprovedraiGotchiNFT(uint256 id) {
        require(
            raiGotchiNFT.ownerOf(id) == msg.sender ||
                raiGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    modifier isApprovedraiGotchiNFTItem(uint256 id) {
        require(
            raiGotchiNFTItem.ownerOf(id) == msg.sender ||
                raiGotchiNFTItem.getApproved(id) == msg.sender,
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
    ) public onlyOwner whenNotPaused {
        for (uint i = 0; i < _rewardNFTIds.length; i++) {
            require(
                _rewardNFTIds[i] < raiGotchiNFTItem.totalPrototypeItems(),
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
    ) public isApprovedraiGotchiNFT(_nftId) whenNotPaused {
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
            raiGotchiNFT.isPetAlive(_nftId),
            "Your pet is dead, you cannot stake it"
        );

        require(
            raiGotchiNFT.isPetLocked(_nftId) == false,
            "Your pet is locked, you cannot stake it"
        );

        token.transferFrom(msg.sender, treasury, pool.tokenRewardPerSlot);

        userStakedPetCount[msg.sender][_poolId]++;

        poolInfo[_poolId].totalStakedSlot++;

        stakedPetOwner[_nftId] = msg.sender;

        raiGotchiNFT.lockPet(_nftId);

        emit PetStaked(_nftId, _poolId);
    }

    function unstake(uint256 _nftId, uint256 _poolId) public whenNotPaused {
        PoolInfo memory pool = poolInfo[_poolId];

        require(_poolId < poolIds, "Invalid pool id");

        address _stakedPetOwner = stakedPetOwner[_nftId];

        require(_stakedPetOwner == msg.sender, "Not pet owner");

        require(
            raiGotchiNFT.isPetLocked(_nftId),
            "Your pet is not locked, you cannot unstake it"
        );

        require(
            pool.stakingEndTime < block.timestamp,
            "Staking pool has not ended yet"
        );

        for (uint i = 0; i < pool.rewardNFTIds.length; i++) {
            raiGotchiNFTItem.mint(_stakedPetOwner, pool.rewardNFTIds[i]);
        }

        stakedPetOwner[_nftId] = address(0);

        token.transfer(_stakedPetOwner, pool.tokenRewardPerSlot);
        raiGotchiNFT.unlockPet(_nftId);

        emit PetUnstaked(
            _nftId,
            _poolId,
            pool.rewardNFTIds,
            pool.tokenRewardPerSlot
        );
    }

    function addMiningTool(
        uint256 _toolId
    ) public isApprovedraiGotchiNFTItem(_toolId) whenNotPaused {
        require(
            raiGotchiNFTItem.itemType(_toolId) == ItemType.MINETOOL,
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
            raiGotchiNFTItem.isItemLock(_toolId) == false,
            "This tool is locked"
        );

        raiGotchiNFTItem.lockItem(_toolId);

        uint256 miningPower = raiGotchiNFTItem.miningPower(_toolId);

        miningToolUsed[msg.sender].push(_toolId);

        totalMiningChargeTime[msg.sender] = _caculateChargeOfTime(
            miningToolUsed[msg.sender].length
        );
        totalMiningPower[msg.sender] += miningPower;
        miningToolOwner[_toolId] = msg.sender;

        if (
            lastMiningTime[msg.sender] == 0 ||
            miningToolUsed[msg.sender].length == 1
        ) {
            lastMiningTime[msg.sender] = block.timestamp;
        }

        emit MiningToolAdded(_toolId, msg.sender);
    }

    function removeMiningTool(uint256 _toolId) public whenNotPaused {
        require(
            miningToolOwner[_toolId] == msg.sender,
            "You are not the owner of this tool"
        );

        raiGotchiNFTItem.unlockItem(_toolId);

        uint256 miningPower = raiGotchiNFTItem.miningPower(_toolId);

        totalMiningPower[msg.sender] -= miningPower;

        miningToolOwner[_toolId] = address(0);

        _removeItemFromListTool(_toolId);

        totalMiningChargeTime[msg.sender] = _caculateChargeOfTime(
            miningToolUsed[msg.sender].length
        );

        emit MiningToolRemoved(_toolId, msg.sender);
    }

    function mining() public whenNotPaused {
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

    function redemnMiningPoints() public whenNotPaused {
        uint256 _miningPoints = miningPoints[msg.sender];

        require(
            _miningPoints >= pointsUsedPerRedemn,
            "You do not have enough mining point"
        );

        miningPoints[msg.sender] -= pointsUsedPerRedemn;

        uint256 prototypeTokenId = raiGotchiNFTItem.getPrototypeForNewItem(
            msg.sender,
            _miningPoints
        );

        raiGotchiNFTItem.mint(msg.sender, prototypeTokenId);

        token.transfer(msg.sender, tokenEarnedPerRedemn);

        emit PointsRedemed(msg.sender, prototypeTokenId);
    }

    function ownerWithdrawRedundantToken(uint256 _poolId) public onlyOwner whenNotPaused {
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

    function setMiningPointsUsedPerRedemn(uint256 _points) public onlyOwner  {
        pointsUsedPerRedemn = _points;
    }

    function setTokenEarnedPerRedemn(uint256 _token) public onlyOwner {
        tokenEarnedPerRedemn = _token;
    }

    function setPricePerSlot(uint256 _pricePerSlot) public onlyOwner {
        pricePerSlot = _pricePerSlot;
    }

    /** 
        @dev Calculate the charge of time for mining
        If user has 1 tool, the charge of time is the charge of time of the tool
        If user has 2 tools, the charge of time is the sum of charge of time of the 2 tools, the shorter charge of time tool will be reduced by half
        If user has 3 tools, the charge of time is the sum of charge of time of the 3 tools, the shortest charge of time tool will be ignored
        @param numberOfTools Number of tools used for mining
        @return uint256 Charge of time for mining 
    */
    function _caculateChargeOfTime(
        uint256 numberOfTools
    ) private view returns (uint256) {
        if (numberOfTools == 1) {
            uint256 _chargeOfTime = raiGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][0]
            );
            return _chargeOfTime;
        } else if (numberOfTools == 2) {
            uint256 firstToolChargeTime = raiGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][0]
            );

            uint256 secondToolChargeTime = raiGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][1]
            );

            uint256 shorterChargeTimeToolId = firstToolChargeTime <
                secondToolChargeTime
                ? miningToolUsed[msg.sender][0]
                : miningToolUsed[msg.sender][1];

            uint256 _reducedChargeTime = raiGotchiNFTItem.miningChargeTime(
                shorterChargeTimeToolId
            ) / 2;

            // Total charge time = first tool charge time + new tool charge time - reduced charge time
            return
                firstToolChargeTime + secondToolChargeTime - _reducedChargeTime;
        } else {
            uint256 firstToolChargeTime = raiGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][0]
            );

            uint256 secondToolChargeTime = raiGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][1]
            );

            uint256 thirdToolChargeTime = raiGotchiNFTItem.miningChargeTime(
                miningToolUsed[msg.sender][2]
            );

            uint256 shorterChargeTimeToolId = firstToolChargeTime <
                secondToolChargeTime
                ? miningToolUsed[msg.sender][0]
                : miningToolUsed[msg.sender][1];

            uint256 shortestChargeTimeToolId = raiGotchiNFTItem
                .miningChargeTime(shorterChargeTimeToolId) < thirdToolChargeTime
                ? shorterChargeTimeToolId
                : miningToolUsed[msg.sender][2];

            uint256 _reducedChargeTime = raiGotchiNFTItem.miningChargeTime(
                shortestChargeTimeToolId
            );

            // Total charge time = first tool charge time + second tool charge time + new tool charge time - reduced charge time
            return
                firstToolChargeTime +
                secondToolChargeTime +
                thirdToolChargeTime -
                _reducedChargeTime;
        }
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
