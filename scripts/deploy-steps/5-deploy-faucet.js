const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const Faucet = await hre.ethers.getContractFactory("RaiGotchiFaucet");
  const faucet = await Faucet.deploy(contracts.token);
  await faucet.waitForDeployment();
  console.log("Faucet:", faucet.target);

  saveContract(network, "raiGotchiFaucet", faucet.target);
  console.log("Faucet contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
