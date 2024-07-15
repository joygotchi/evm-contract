const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const JoyGotchiItems = await hre.ethers.getContractFactory("JoyGotchiItems");
  const joyGotchiItems = await JoyGotchiItems.deploy(contracts.joyGotchiV2);
  await joyGotchiItems.waitForDeployment();
  console.log("JoyGotchiItems:", joyGotchiItems.target);

  saveContract(network, "joyGotchiItems", joyGotchiItems.target);
  console.log("JoyGotchiItems contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
