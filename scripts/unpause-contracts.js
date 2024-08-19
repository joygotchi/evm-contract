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
  const raiGotchiAccessory = RaiGotchiAccessory.attach(
    contracts.raiGotchiAccessory
  );

  // Pause all the contract in case emergency
  await raiGotchiAttack.unpause();
  console.log("RaiGotchiAttack unpaused");

  await raiGotchiBreed.unpause();
  console.log("RaiGotchiBreed unpaused");

  await raiGotchiImmidiateUseItems.unpause();
  console.log("RaiGotchiImmidiateUseItems unpaused");

  await raiGotchiStakingAndMining.unpause();
  console.log("RaiGotchiStakingAndMining unpaused");

  await raiGotchiItems.unpause();
  console.log("RaiGotchiItems unpaused");

  await raiGotchiV2.unpause();
  console.log("RaiGotchiV2 unpaused");

  await raiGotchiAccessory.unpause();
  console.log("RaiGotchiAccessory unpaused");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
