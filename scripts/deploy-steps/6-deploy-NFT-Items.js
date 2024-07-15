const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const JoyGotchiItems = await hre.ethers.getContractFactory("JoyGotchiItems");
  const joyGotchiItems = await JoyGotchiItems.deploy(contracts.joyGotchiV2);
  await joyGotchiItems.waitForDeployment();
  console.log("JoyGotchiItems:", joyGotchiItems.target);

  saveContract(network, "joyGotchiItems", joyGotchiItems.target);
  console.log("JoyGotchiItems contract saved");

  // Settings allow contract to mint NFT for JoyGotchiItems contract
  await joyGotchiItems.setAllowAddress(contracts.joyGotchiV2, true);
  console.log("Allow JoyGotchiV2 for NFT items success");
  await joyGotchiItems.setAllowAddress(contracts.joyGotchiBreed, true);
  console.log("Allow JoyGotchiBreed for NFT items success");
  await joyGotchiItems.setAllowAddress(
    contracts.joyGotchiStakingAndMining,
    true
  );
  console.log("Allow JoyGotchiStakingAndMining for NFT items success");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
