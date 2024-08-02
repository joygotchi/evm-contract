const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
    "RaiGotchiImmidiateUseItems"
  );
  const raiGotchiImmidiateUseItems = await RaiGotchiImmidiateUseItems.deploy(
    contracts.raiGotchiV2,
    contracts.raiGotchiTreasury,
    contracts.token
  );
  await raiGotchiImmidiateUseItems.waitForDeployment();
  console.log("RaiGotchiImmidiateUseItems:", raiGotchiImmidiateUseItems.target);

  saveContract(
    network,
    "raiGotchiImmidiateUseItems",
    raiGotchiImmidiateUseItems.target
  );
  console.log("RaiGotchiImmidiateUseItems contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
