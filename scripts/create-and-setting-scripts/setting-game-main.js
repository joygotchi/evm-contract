const hre = require("hardhat");
const { getContracts } = require("../utils");
const { parseEther } = require("ethers");

const MINING_POOL_NAME = "Mining Pool";
const TOKEN_EARNED_PER_REDEEM = parseEther("1"); // 1 token Raigotchi earned per redeem
const POINTS_USED_PER_REDEEM = 10_000; // 10000 point used per redeem
const MINING_POWER_MULTIPLIER = 1500; // 1.5X Mining power multiplier
const CHARGE_TIME_MULTIPLIER = 2000; // 2X Charge time multiplier

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiV2 = await hre.ethers.getContractFactory("RaiGotchiV2");
  const raiGotchiV2 = RaiGotchiV2.attach(contracts.raiGotchiV2);

  // Settings for system RaiGotchiV2 contract
  // await raiGotchiV2.setGenePool(contracts.genePool);
  // console.log("Set GenePool success");
  // await raiGotchiV2.setBreedContract(contracts.raiGotchiBreed);
  // console.log("Set BreedContract success");
  await raiGotchiV2.setAttackContract(contracts.raiGotchiAttack);
  console.log("Set AttackContract success");
  await raiGotchiV2.setImmidiateUseItemsContract(
    contracts.raiGotchiImmidiateUseItems
  );
  console.log("Set ImmidiateUseItemsContract success");

  // Settings QRNG contract (need to change sponsor wallet in config file correspondingly to the raigotchiV2 contract)
  await raiGotchiV2.setRequestParameters(
    contracts.airnodeAddress,
    contracts.endpointIdUint256,
    contracts.sponsorWallet
  );

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

  // Settings allow contract to mint NFT for RaiGotchiItems contract
  await raiGotchiItems.setAllowAddress(
    contracts.raiGotchiStakingAndMining,
    true
  );
  console.log("Allow RaiGotchiStakingAndMining for NFT items success");

  const RaiGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "RaiGotchiStakingAndMining"
  );
  const raiGotchiStakingAndMining = RaiGotchiStakingAndMining.attach(
    contracts.raiGotchiStakingAndMining
  );

  // Set mining pool settings
  await raiGotchiStakingAndMining.configureMiningPool(
    MINING_POOL_NAME,
    MINING_POWER_MULTIPLIER,
    CHARGE_TIME_MULTIPLIER
  );

  console.log("Set mining pool settings success");

  // Set mining pool redeem settings
  await raiGotchiStakingAndMining.setMiningPointsUsedPerRedemn(
    POINTS_USED_PER_REDEEM
  );

  console.log("Set mining pool redeem settings success");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
