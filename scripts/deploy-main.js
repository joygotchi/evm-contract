const hre = require("hardhat");
const { getContracts, saveContract } = require("./utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const Token = await hre.ethers.getContractFactory("RaiGotchiToken");
  const token = await Token.deploy(contracts.uniswapV2Router02);
  await token.waitForDeployment();
  console.log("RaiGotchiToken:", token.target);

  saveContract(network, "token", token.target);
  console.log("Token contract saved");

  // Deploy faucet testing token contract 
  const Faucet = await hre.ethers.getContractFactory("RaiGotchiFaucet");
  const faucet = await Faucet.deploy(token.target);
  await faucet.waitForDeployment();
  console.log("RaiGotchiFaucet:", faucet.target);

  saveContract(network, "faucet", faucet.target);
  console.log("Faucet Testing Token contract saved");

  // Deploy RaiGotchi Treasury contract
  const RaiGotchiTreasury = await hre.ethers.getContractFactory(
    "RaiGotchiTreasury"
  );
  const raiGotchiTreasury = await RaiGotchiTreasury.deploy(token.target);
  await raiGotchiTreasury.waitForDeployment();
  console.log("RaiGotchiTreasury:", raiGotchiTreasury.target);

  saveContract(network, "raiGotchiTreasury", raiGotchiTreasury.target);
  console.log("RaiGotchiTreasury contract saved");

  // Deploy RaiGotchi NFT contract (Pet)
  const RaiGotchiV2 = await hre.ethers.getContractFactory("RaiGotchiV2");
  const raiGotchiV2 = await RaiGotchiV2.deploy(
    token.target,
    contracts.qrngContract, //airnode rrp on lightlink testnet
    raiGotchiTreasury.target
  );
  await raiGotchiV2.waitForDeployment();
  console.log("RaiGotchi Pet:", raiGotchiV2.target);

  saveContract(network, "raiGotchiV2", raiGotchiV2.target);
  console.log("RaiGotchiV2 contract saved");

  // Deploy RaiGotchi Gene Pool contract
  const GenePool = await hre.ethers.getContractFactory("GenePool");
  const genePool = await GenePool.deploy(raiGotchiV2.target, 2, 2, 2); // 2, 2, 2 for testing skinColorGeneNum, wingStyleGeneNum, hornStyleGeneNum, may change on prod
  await genePool.waitForDeployment();
  console.log("GenePool:", genePool.target);

  saveContract(network, "genePool", genePool.target);
  console.log("GenePool contract saved");

  // Deploy RaiGotchi NFT Items contract
  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = await RaiGotchiItems.deploy(raiGotchiV2.target);
  await raiGotchiItems.waitForDeployment();
  console.log("RaiGotchiItems:", raiGotchiItems.target);

  saveContract(network, "raiGotchiItems", raiGotchiItems.target);
  console.log("RaiGotchiItems contract saved");

  // Deploy RaiGotchi Attack contract
  const RaiGotchiAttack = await hre.ethers.getContractFactory(
    "RaiGotchiAttack"
  );
  const raiGotchiAttack = await RaiGotchiAttack.deploy(raiGotchiV2.target);
  await raiGotchiAttack.waitForDeployment();
  console.log("RaiGotchiAttack:", raiGotchiAttack.target);

  saveContract(network, "raiGotchiAttack", raiGotchiAttack.target);
  console.log("RaiGotchiAttack contract saved");

  // Deploy RaiGotchi Breed contract
  const RaiGotchiBreed = await hre.ethers.getContractFactory("RaiGotchiBreed");
  const raiGotchiBreed = await RaiGotchiBreed.deploy(
    raiGotchiV2.target,
    token.target,
    raiGotchiTreasury.target
  );
  await raiGotchiBreed.waitForDeployment();
  console.log("RaiGotchiBreed:", raiGotchiBreed.target);

  saveContract(network, "raiGotchiBreed", raiGotchiBreed.target);
  console.log("RaiGotchiBreed contract saved");

  // Deploy RaiGotchi Immidiate Use Items contract
  const RaiGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
    "RaiGotchiImmidiateUseItems"
  );
  const raiGotchiImmidiateUseItems = await RaiGotchiImmidiateUseItems.deploy(
    raiGotchiV2.target,
    raiGotchiTreasury.target,
    token.target
  );
  await raiGotchiImmidiateUseItems.waitForDeployment();
  console.log("RaiGotchiImmidiateUseItems:", raiGotchiImmidiateUseItems.target);

  saveContract(
    network,
    "raiGotchiImmidiateUseItems",
    raiGotchiImmidiateUseItems.target
  );
  console.log("RaiGotchiImmidiateUseItems contract saved");

  // Deploy RaiGotchi Accessory contract
  const RaiGotchiAccessory = await hre.ethers.getContractFactory(
    "RaiGotchiAccessory"
  );
  const raiGotchiAccessory = await RaiGotchiAccessory.deploy(
    raiGotchiV2.target,
    raiGotchiTreasury.target,
    token.target
  );
  await raiGotchiAccessory.waitForDeployment();
  console.log("RaiGotchiAccessory:", raiGotchiAccessory.target);

  saveContract(network, "raiGotchiAccessory", raiGotchiAccessory.target);
  console.log("RaiGotchiAccessory contract saved");

  // Deploy RaiGotchi Staking And Mining contract
  const RaiGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "RaiGotchiStakingAndMining"
  );
  const raiGotchiStakingAndMining = await RaiGotchiStakingAndMining.deploy(
    raiGotchiItems.target,
    token.target,
    raiGotchiTreasury.target
  );
  await raiGotchiStakingAndMining.waitForDeployment();
  console.log("RaiGotchiStakingAndMining:", raiGotchiStakingAndMining.target);

  saveContract(
    network,
    "raiGotchiStakingAndMining",
    raiGotchiStakingAndMining.target
  );
  console.log("RaiGotchiStakingAndMining contract saved");

  console.log("Start Settings");

  // Settings for system RaiGotchiV2 contract
  await raiGotchiV2.setGenePool(genePool.target);
  console.log("Set GenePool success");
  await raiGotchiV2.setBreedContract(raiGotchiBreed.target);
  console.log("Set BreedContract success");
  await raiGotchiV2.setAttackContract(raiGotchiAttack.target);
  console.log("Set AttackContract success");
  await raiGotchiV2.setImmidiateUseItemsContract(
    raiGotchiImmidiateUseItems.target
  );
  console.log("Set ImmidiateUseItemsContract success");

  // Settings allow contract to mint NFT for RaiGotchiItems contract
  await raiGotchiItems.setAllowAddress(raiGotchiStakingAndMining.target, true);
  console.log("Allow RaiGotchiStakingAndMining for NFT items success");

  // enable trading for RaiGotchiToken
  await token.enableTrading();
  console.log("Enable trading success");

  // Set mining pool settings
  const MINING_POOL_NAME = "Mining Pool Test";
  const MINING_POWER_MULTIPLIER = 1500; // 1.5X Mining power multiplier
  const CHARGE_TIME_MULTIPLIER = 2000; // 2X Charge time multiplier

  await raiGotchiStakingAndMining.configureMiningPool(
    MINING_POOL_NAME,
    MINING_POWER_MULTIPLIER,
    CHARGE_TIME_MULTIPLIER
  );

  console.log("Set mining pool settings success");

  // Set mining pool redeem settings
  const POINTS_USED_PER_REDEEM = 10_000; // 10000 point used per redeem

  await raiGotchiStakingAndMining.setMiningPointsUsedPerRedemn(
    POINTS_USED_PER_REDEEM
  );

  console.log("Set mining pool redeem settings success");

  console.log("Done setting");

  console.log("Done deploy");

  //Verify contract
  await hre.run("verify:verify", {
    address: token.target,
    constructorArguments: [contracts.uniswapV2Router02],
  });

  await hre.run("verify:verify", {
    address: raiGotchiTreasury.target,
    constructorArguments: [token.target],
  });

  await hre.run("verify:verify", {
    address: raiGotchiV2.target,
    constructorArguments: [
      token.target,
      contracts.qrngContract,
      raiGotchiTreasury.target,
    ],
  });

  await hre.run("verify:verify", {
    address: genePool.target,
    constructorArguments: [raiGotchiV2.target, 2, 2, 2],
  });

  await hre.run("verify:verify", {
    address: faucet.target,
    constructorArguments: [token.target],
  });

  await hre.run("verify:verify", {
    address: raiGotchiItems.target,
    constructorArguments: [raiGotchiV2.target],
  });

  await hre.run("verify:verify", {
    address: raiGotchiAttack.target,
    constructorArguments: [raiGotchiV2.target],
  });

  await hre.run("verify:verify", {
    address: raiGotchiBreed.target,
    constructorArguments: [
      raiGotchiV2.target,
      token.target,
      raiGotchiTreasury.target,
    ],
  });

  await hre.run("verify:verify", {
    address: raiGotchiImmidiateUseItems.target,
    constructorArguments: [
      raiGotchiV2.target,
      raiGotchiTreasury.target,
      token.target,
    ],
  });

  await hre.run("verify:verify", {
    address: raiGotchiStakingAndMining.target,
    constructorArguments: [
      raiGotchiItems.target,
      token.target,
      raiGotchiTreasury.target,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
