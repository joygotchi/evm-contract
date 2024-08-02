const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const Token = await hre.ethers.getContractFactory("RaiGotchiToken");
  const token = await Token.deploy(contracts.uniswapV2Router02);
  await token.waitForDeployment();
  console.log("RaiGotchiToken:", token);

  saveContract(network, "token", token);
  console.log("Token contract saved");

  // Settings
  await token.enableTrading();
  console.log("Enable trading success");

  console.log("Completed");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
