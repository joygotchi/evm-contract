const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiAccessory = await hre.ethers.getContractFactory(
    "RaiGotchiAccessory"
  );
  const raiGotchiAccessory = await RaiGotchiAccessory.deploy(
    contracts.raiGotchiV2,
    contracts.raiGotchiTreasury,
    contracts.token
  );
  await raiGotchiAccessory.waitForDeployment();
  console.log("RaiGotchiAccessory:", raiGotchiAccessory.target);

  saveContract(
    network,
    "raiGotchiAccessory",
    raiGotchiAccessory.target
  );
  console.log("RaiGotchiAccessory contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
