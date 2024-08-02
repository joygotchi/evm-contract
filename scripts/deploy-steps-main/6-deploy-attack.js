const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiAttack = await hre.ethers.getContractFactory(
    "RaiGotchiAttack"
  );
  const raiGotchiAttack = await RaiGotchiAttack.deploy(contracts.raiGotchiV2);
  await raiGotchiAttack.waitForDeployment();
  console.log("RaiGotchiAttack:", raiGotchiAttack.target);

  saveContract(network, "raiGotchiAttack", raiGotchiAttack.target);
  console.log("RaiGotchiAttack contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
