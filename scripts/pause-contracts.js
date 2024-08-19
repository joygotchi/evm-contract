const hre = require("hardhat");
const { getContracts } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiV2 = await hre.ethers.getContractFactory("RaiGotchiV2");
  const raiGotchiV2 = RaiGotchiV2.attach(contracts.raiGotchiV2);

  const RaiGotchiAttack = await hre.ethers.getContractFactory(
    "RaiGotchiAttack"
  );
  const raiGotchiAttack = RaiGotchiAttack.attach(contracts.raiGotchiAttack);

  const RaiGotchiBreed = await hre.ethers.getContractFactory("RaiGotchiBreed");
  const raiGotchiBreed = RaiGotchiBreed.attach(contracts.raiGotchiBreed);

  const RaiGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
    "RaiGotchiImmidiateUseItems"
  );
  const raiGotchiImmidiateUseItems = RaiGotchiImmidiateUseItems.attach(
    contracts.raiGotchiImmidiateUseItems
  );

  const RaiGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "RaiGotchiStakingAndMining"
  );
  const raiGotchiStakingAndMining = RaiGotchiStakingAndMining.attach(
    contracts.raiGotchiStakingAndMining
  );

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

  const RaiGotchiAccessory = await hre.ethers.getContractFactory(
    "RaiGotchiAccessory"
  );
  const raiGotchiAccessory = RaiGotchiAccessory.attach(contracts.raiGotchiAccessory);

  // Pause all the contract in case emergency
  await raiGotchiAttack.pause();
  console.log("RaiGotchiAttack paused");

  await raiGotchiBreed.pause();
  console.log("RaiGotchiBreed paused");

  await raiGotchiImmidiateUseItems.pause();
  console.log("RaiGotchiImmidiateUseItems paused");

  await raiGotchiStakingAndMining.pause();
  console.log("RaiGotchiStakingAndMining paused");

  await raiGotchiItems.pause();
  console.log("RaiGotchiItems paused");

  await raiGotchiV2.pause();
  console.log("RaiGotchiV2 paused");

  await raiGotchiAccessory.pause();
  console.log("RaiGotchiAccessory paused");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
