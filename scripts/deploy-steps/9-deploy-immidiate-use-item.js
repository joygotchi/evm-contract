const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const JoyGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
    "JoyGotchiImmidiateUseItems"
  );
  const joyGotchiImmidiateUseItems = await JoyGotchiImmidiateUseItems.deploy(
    contracts.joyGotchiV2,
    contracts.joyGotchiTreasury,
    contracts.token
  );
  await joyGotchiImmidiateUseItems.waitForDeployment();
  console.log("JoyGotchiImmidiateUseItems:", joyGotchiImmidiateUseItems.target);

  saveContract(
    network,
    "joyGotchiImmidiateUseItems",
    joyGotchiImmidiateUseItems.target
  );
  console.log("JoyGotchiImmidiateUseItems contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
