const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const JoyGotchiAttack = await hre.ethers.getContractFactory(
    "JoyGotchiAttack"
  );
  const joyGotchiAttack = await JoyGotchiAttack.deploy(contracts.joyGotchiV2);
  await joyGotchiAttack.waitForDeployment();
  console.log("JoyGotchiAttack:", joyGotchiAttack.target);

  saveContract(network, "joyGotchiAttack", joyGotchiAttack.target);
  console.log("JoyGotchiAttack contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
