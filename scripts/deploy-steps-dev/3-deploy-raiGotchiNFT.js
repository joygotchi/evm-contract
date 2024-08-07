const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RaiGotchiV2 = await hre.ethers.getContractFactory("RaiGotchiV2");
  const raiGotchiV2 = await RaiGotchiV2.deploy(
    contracts.token,
    contracts.qrngContract, //airnode rrp on lightlink testnet
    contracts.raiGotchiTreasury
  );
  await raiGotchiV2.waitForDeployment();
  console.log("RaiGotchi Pet:", raiGotchiV2.target);

  saveContract(network, "raiGotchiV2", raiGotchiV2.target);
  console.log("RaiGotchiV2 contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
