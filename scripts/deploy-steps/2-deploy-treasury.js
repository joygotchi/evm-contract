const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const JoyGotchiTreasury = await hre.ethers.getContractFactory(
    "JoyGotchiTreasury"
  );
  const joyGotchiTreasury = await JoyGotchiTreasury.deploy(token.target);
  await joyGotchiTreasury.waitForDeployment();
  console.log("JoyGotchiTreasury:", joyGotchiTreasury.target);

  saveContract(network, "joyGotchiTreasury", joyGotchiTreasury.target);
  console.log("JoyGotchiTreasury contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
