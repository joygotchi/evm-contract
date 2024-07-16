const hre = require("hardhat");
const { getContracts } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiV2 = await hre.ethers.getContractFactory("RaiGotchiV2");
  const raiGotchiV2 = RaiGotchiV2.attach(contracts.raiGotchiV2);

  // Settings for system RaiGotchiV2 contract
  await raiGotchiV2.setGenePool(contracts.genePool);
  console.log("Set GenePool success");
  await raiGotchiV2.setBreedContract(contracts.raiGotchiBreed);
  console.log("Set BreedContract success");
  await raiGotchiV2.setStakingAndMiningContract(
    contracts.raiGotchiStakingAndMining
  );
  console.log("Set StakingAndMiningContract success");
  await raiGotchiV2.setAttackContract(contracts.raiGotchiAttack);
  console.log("Set AttackContract success");
  await raiGotchiV2.setImmidiateUseItemsContract(
    contracts.raiGotchiImmidiateUseItems
  );
  console.log("Set ImmidiateUseItemsContract success");
  await raiGotchiV2.setRaiGotchiItemsContract(contracts.raiGotchiItems);
  console.log("Set RaiGotchiItemsContract success");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
