const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const JoyGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "JoyGotchiStakingAndMining"
  );
  const joyGotchiStakingAndMining = await JoyGotchiStakingAndMining.deploy(
    contracts.joyGotchiV2,
    contracts.joyGotchiItems,
    contracts.token,
    contracts.joyGotchiTreasury
  );
  await joyGotchiStakingAndMining.waitForDeployment();
  console.log("JoyGotchiStakingAndMining:", joyGotchiStakingAndMining.target);

  saveContract(
    network,
    "joyGotchiStakingAndMining",
    joyGotchiStakingAndMining.target
  );
  console.log("JoyGotchiStakingAndMining contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
