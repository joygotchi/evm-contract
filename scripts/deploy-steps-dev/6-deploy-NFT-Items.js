const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = await RaiGotchiItems.deploy(contracts.raiGotchiV2);
  await raiGotchiItems.waitForDeployment();
  console.log("RaiGotchiItems:", raiGotchiItems.target);

  saveContract(network, "raiGotchiItems", raiGotchiItems.target);
  console.log("RaiGotchiItems contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
