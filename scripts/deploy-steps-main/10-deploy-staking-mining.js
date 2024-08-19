const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const RaiGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "RaiGotchiStakingAndMining"
  );
  const raiGotchiStakingAndMining = await RaiGotchiStakingAndMining.deploy(
    contracts.raiGotchiItems,
    contracts.token,
    contracts.raiGotchiTreasury
  );
  await raiGotchiStakingAndMining.waitForDeployment();
  console.log("RaiGotchiStakingAndMining:", raiGotchiStakingAndMining.target);

  saveContract(
    network,
    "raiGotchiStakingAndMining",
    raiGotchiStakingAndMining.target
  );
  console.log("RaiGotchiStakingAndMining contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
