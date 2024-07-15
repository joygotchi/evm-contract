const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const JoyGotchiV2 = await hre.ethers.getContractFactory("JoyGotchiV2");
  const joyGotchiV2 = await JoyGotchiV2.deploy(
    contracts.token,
    contracts.qrngContract, //airnode rrp on lightlink testnet
    contracts.joyGotchiTreasury
  );
  await joyGotchiV2.waitForDeployment();
  console.log("JoyGotchi Pet:", joyGotchiV2.target);

  saveContract(network, "joyGotchiV2", joyGotchiV2.target);
  console.log("JoyGotchiV2 contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
