const { parseUnits, formatEther, parseEther } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");

const stakingPoolData = [
  {
    name: "Staking Pool 1", // Staking pool name
    rewardNFTId: 1, // Reward NFT id
    pricePerSlot: parseUnits("1", 18), // User need to pay 1 raigotchi token to stake in this pool
    stakingStartTime: "1723885200", // Staking start time
    stakingEndTime: "1723888800", // Staking end time
    maxSlotsInPool: 20, // Maximum slots in this pool
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

  // Create staking pool
  for (let i = 0; i < stakingPoolData.length; i++) {
    const stakingPool = stakingPoolData[i];

    await raiGotchiStakingAndMining.createNewStakingPool(
      stakingPool.name,
      stakingPool.rewardNFTId,
      stakingPool.pricePerSlot,
      stakingPool.stakingStartTime,
      stakingPool.stakingEndTime,
      stakingPool.maxSlotsInPool,
      stakingPool.maxSlotPerWallet
    );

    console.log("Staking pool created: ", stakingPool.name);
  }

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
