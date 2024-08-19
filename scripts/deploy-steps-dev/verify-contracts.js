const hre = require("hardhat");
const { getContracts } = require("../utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  //Verify contract
  await hre.run("verify:verify", {
    address: contracts.token,
    constructorArguments: [contracts.uniswapV2Router02],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiTreasury,
    constructorArguments: [contracts.token],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiV2,
    constructorArguments: [
      contracts.token,
      contracts.qrngContract,
      contracts.raiGotchiTreasury,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.genePool,
    constructorArguments: [contracts.raiGotchiV2, 2, 2, 2],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiFaucet,
    constructorArguments: [contracts.token],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiItems,
    constructorArguments: [contracts.raiGotchiV2],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiAttack,
    constructorArguments: [contracts.raiGotchiV2],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiBreed,
    constructorArguments: [
      contracts.raiGotchiV2,
      contracts.token,
      contracts.raiGotchiTreasury,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiImmidiateUseItems,
    constructorArguments: [
      contracts.raiGotchiV2,
      contracts.raiGotchiTreasury,
      contracts.token,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiAccessory,
    constructorArguments: [
      contracts.raiGotchiV2,
      contracts.raiGotchiTreasury,
      contracts.token,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.raiGotchiStakingAndMining,
    constructorArguments: [
      contracts.raiGotchiItems,
      contracts.token,
      contracts.raiGotchiTreasury,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
