const hre = require("hardhat");
const { getContracts, saveContract } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const GenePool = await hre.ethers.getContractFactory("GenePool");
  const genePool = await GenePool.deploy(contracts.raiGotchiV2, 2, 2, 2); // 2, 2, 2 for testing skinColorGeneNum, wingStyleGeneNum, hornStyleGeneNum, may change on prod
  await genePool.waitForDeployment();
  console.log("GenePool:", genePool.target);

  saveContract(network, "genePool", genePool.target);
  console.log("GenePool contract saved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
