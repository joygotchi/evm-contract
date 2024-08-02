const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = await RaiGotchiItems.deploy(contracts.raiGotchiV2);
  await raiGotchiItems.waitForDeployment();
  console.log("RaiGotchiItems:", raiGotchiItems.target);

  saveContract(network, "raiGotchiItems", raiGotchiItems.target);
  console.log("RaiGotchiItems contract saved");

  // Settings allow contract to mint NFT for RaiGotchiItems contract
  await raiGotchiItems.setAllowAddress(
    contracts.raiGotchiStakingAndMining,
    true
  );
  console.log("Allow RaiGotchiStakingAndMining for NFT items success");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
