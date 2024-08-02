const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiBreed = await hre.ethers.getContractFactory("RaiGotchiBreed");
  const raiGotchiBreed = await RaiGotchiBreed.deploy(
    contracts.raiGotchiV2,
    contracts.token,
    contracts.raiGotchiTreasury
  );
  await raiGotchiBreed.waitForDeployment();
  console.log("RaiGotchiBreed:", raiGotchiBreed.target);

  saveContract(network, "raiGotchiBreed", raiGotchiBreed.target);
  console.log("RaiGotchiBreed contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
