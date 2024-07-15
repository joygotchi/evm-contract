const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const JoyGotchiV2 = await hre.ethers.getContractFactory("JoyGotchiV2");
  const joyGotchiV2 = JoyGotchiV2.attach(contracts.joyGotchiV2);

  // Settings for system JoyGotchiV2 contract
  await joyGotchiV2.setGenePool(genePool.target);
  console.log("Set GenePool success");
  await joyGotchiV2.setBreedContract(joyGotchiBreed.target);
  console.log("Set BreedContract success");
  await joyGotchiV2.setStakingAndMiningContract(
    joyGotchiStakingAndMining.target
  );
  console.log("Set StakingAndMiningContract success");
  await joyGotchiV2.setAttackContract(joyGotchiAttack.target);
  console.log("Set AttackContract success");
  await joyGotchiV2.setImmidiateUseItemsContract(
    joyGotchiImmidiateUseItems.target
  );
  console.log("Set ImmidiateUseItemsContract success");
  await joyGotchiV2.setJoyGotchiItemsContract(joyGotchiItems.target);
  console.log("Set JoyGotchiItemsContract success");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
