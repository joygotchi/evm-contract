const { parseUnits, formatEther, parseEther } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");

const stakingPoolData = [
  {
    name: "Staking Pool 1", // Staking pool name
    rewardNFTIds: [0, 1, 2, 3], // List of reward NFT ids
    stakingStartTime: "1723042800", // Staking start time
    stakingEndTime: "1723044600", // Staking end time
    maxSlotsInPool: 20, // Maximum slots in this pool
    tokenRewardPerSlot: parseUnits("1", 18), // User receive back 1  raigotchi token after unstake from this pool
    maxSlotPerWallet: 3, // Maximum slots per wallet
  },
];

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "RaiGotchiStakingAndMining"
  );

  const raiGotchiStakingAndMining = RaiGotchiStakingAndMining.attach(
    contracts.raiGotchiStakingAndMining
  );

  const raigotchiToken = await hre.ethers.getContractAt(
    "RaiGotchiToken",
    contracts.token
  );

  let totalAmountTransferToStakingContract = 0;

  for (let i = 0; i < stakingPoolData.length; i++) {
    const stakingPool = stakingPoolData[i];

    const amountToTransfer =
      formatEther(stakingPool.tokenRewardPerSlot) *
      Number(stakingPool.maxSlotsInPool);
    totalAmountTransferToStakingContract += amountToTransfer;
  }

  // Approve token to staking contract
  const tx = await raigotchiToken.approve(
    contracts.raiGotchiStakingAndMining,
    parseEther(totalAmountTransferToStakingContract.toString())
  );

  console.log("Approve succeed");

  await tx.wait();

  // Need to wait for approve transaction to be success first before creating staking pool
  // In case of approve transaction failed you can run this script again
  if (tx.status === 1) {
    console.log("Approve transaction hash: ", tx.hash);

    // Create staking pool
    for (let i = 0; i < stakingPoolData.length; i++) {
      const stakingPool = stakingPoolData[i];

      await raiGotchiStakingAndMining.createNewStakingPool(
        stakingPool.name,
        stakingPool.rewardNFTIds,
        stakingPool.stakingStartTime,
        stakingPool.stakingEndTime,
        stakingPool.maxSlotsInPool,
        stakingPool.tokenRewardPerSlot,
        stakingPool.maxSlotPerWallet
      );

      console.log("Staking pool created: ", stakingPool.name);
    }
  }

  /**
   * @dev In case approve is submited but waiting time too long or approve has success but create staking pool failed
   * Uncomment code below and comment the approve code above then run this script again
   */

  // for (let i = 0; i < stakingPoolData.length; i++) {
  //   const stakingPool = stakingPoolData[i];

  //   await raiGotchiStakingAndMining.createNewStakingPool(
  //     stakingPool.name,
  //     stakingPool.rewardNFTIds,
  //     stakingPool.stakingStartTime,
  //     stakingPool.stakingEndTime,
  //     stakingPool.maxSlotsInPool,
  //     stakingPool.tokenRewardPerSlot,
  //     stakingPool.maxSlotPerWallet
  //   );

  //   console.log("Staking pool created: ", stakingPool.name);
  // }

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
