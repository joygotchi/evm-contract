const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const JoyGotchiBreed = await hre.ethers.getContractFactory("JoyGotchiBreed");
  const joyGotchiBreed = await JoyGotchiBreed.deploy(
    contracts.joyGotchiV2,
    contracts.joyGotchiItems,
    contracts.token,
    contracts.joyGotchiTreasury
  );
  await joyGotchiBreed.waitForDeployment();
  console.log("JoyGotchiBreed:", joyGotchiBreed.target);

  saveContract(network, "joyGotchiBreed", joyGotchiBreed.target);
  console.log("JoyGotchiBreed contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
