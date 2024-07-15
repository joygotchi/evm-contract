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
    address: contracts.joyGotchiTreasury,
    constructorArguments: [contracts.token],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiV2,
    constructorArguments: [
      contracts.token,
      contracts.qrngContract,
      contracts.joyGotchiTreasury,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.genePool,
    constructorArguments: [contracts.joyGotchiV2, 2, 2, 2],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiFaucet,
    constructorArguments: [contracts.token],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiItems,
    constructorArguments: [contracts.joyGotchiV2],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiAttack,
    constructorArguments: [contracts.joyGotchiV2],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiBreed,
    constructorArguments: [
      contracts.joyGotchiV2,
      contracts.joyGotchiItems,
      contracts.token,
      contracts.joyGotchiTreasury,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiImmidiateUseItems,
    constructorArguments: [
      contracts.joyGotchiV2,
      contracts.joyGotchiTreasury,
      contracts.token,
    ],
  });

  await hre.run("verify:verify", {
    address: contracts.joyGotchiStakingAndMining,
    constructorArguments: [
      contracts.joyGotchiV2,
      contracts.joyGotchiItems,
      contracts.token,
      contracts.joyGotchiTreasury,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
