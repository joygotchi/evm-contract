const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiTreasury = await hre.ethers.getContractFactory(
    "RaiGotchiTreasury"
  );
  const raiGotchiTreasury = await RaiGotchiTreasury.deploy(contracts.token);
  await raiGotchiTreasury.waitForDeployment();
  console.log("RaiGotchiTreasury:", raiGotchiTreasury.target);

  saveContract(network, "raiGotchiTreasury", raiGotchiTreasury.target);
  console.log("RaiGotchiTreasury contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
