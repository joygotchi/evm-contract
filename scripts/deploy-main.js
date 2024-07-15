const hre = require("hardhat");
const { getContracts, saveContract } = require("./utils");

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token contract
  const Token = await hre.ethers.getContractFactory("JoyGotchiToken");
  const token = await Token.deploy(contracts.uniswapV2Router02);
  await token.waitForDeployment();
  console.log("JoyGotchiToken:", token.target);

  saveContract(network, "token", token.target);
  console.log("Token contract saved");

  // Deploy JoyGotchi Treasury contract
  const JoyGotchiTreasury = await hre.ethers.getContractFactory(
    "JoyGotchiTreasury"
  );
  const joyGotchiTreasury = await JoyGotchiTreasury.deploy(token.target);
  await joyGotchiTreasury.waitForDeployment();
  console.log("JoyGotchiTreasury:", joyGotchiTreasury.target);

  saveContract(network, "joyGotchiTreasury", joyGotchiTreasury.target);
  console.log("JoyGotchiTreasury contract saved");

  // Deploy JoyGotchi NFT contract (Pet)
  const JoyGotchiV2 = await hre.ethers.getContractFactory("JoyGotchiV2");
  const joyGotchiV2 = await JoyGotchiV2.deploy(
    token.target,
    contracts.qrngContract, //airnode rrp on lightlink testnet
    joyGotchiTreasury.target
  );
  await joyGotchiV2.waitForDeployment();
  console.log("JoyGotchi Pet:", joyGotchiV2.target);

  saveContract(network, "joyGotchiV2", joyGotchiV2.target);
  console.log("JoyGotchiV2 contract saved");

  // Deploy JoyGotchi Gene Pool contract
  const GenePool = await hre.ethers.getContractFactory("GenePool");
  const genePool = await GenePool.deploy(joyGotchiV2.target, 2, 2, 2); // 2, 2, 2 for testing skinColorGeneNum, wingStyleGeneNum, hornStyleGeneNum, may change on prod
  await genePool.waitForDeployment();
  console.log("GenePool:", genePool.target);

  saveContract(network, "genePool", genePool.target);
  console.log("GenePool contract saved");

  // Deploy JoyGotchi Faucet contract
  const Faucet = await hre.ethers.getContractFactory("JoyGotchiFaucet");
  const faucet = await Faucet.deploy(token.target);
  await faucet.waitForDeployment();
  console.log("Faucet:", faucet.target);

  saveContract(network, "joyGotchiFaucet", faucet.target);
  console.log("Faucet contract saved");

  // Deploy JoyGotchi NFT Items contract
  const JoyGotchiItems = await hre.ethers.getContractFactory("JoyGotchiItems");
  const joyGotchiItems = await JoyGotchiItems.deploy(joyGotchiV2.target);
  await joyGotchiItems.waitForDeployment();
  console.log("JoyGotchiItems:", joyGotchiItems.target);

  saveContract(network, "joyGotchiItems", joyGotchiItems.target);
  console.log("JoyGotchiItems contract saved");

  // Deploy JoyGotchi Attack contract
  const JoyGotchiAttack = await hre.ethers.getContractFactory(
    "JoyGotchiAttack"
  );
  const joyGotchiAttack = await JoyGotchiAttack.deploy(joyGotchiV2.target);
  await joyGotchiAttack.waitForDeployment();
  console.log("JoyGotchiAttack:", joyGotchiAttack.target);

  saveContract(network, "joyGotchiAttack", joyGotchiAttack.target);
  console.log("JoyGotchiAttack contract saved");

  // Deploy JoyGotchi Breed contract
  const JoyGotchiBreed = await hre.ethers.getContractFactory("JoyGotchiBreed");
  const joyGotchiBreed = await JoyGotchiBreed.deploy(
    joyGotchiV2.target,
    joyGotchiItems.target,
    token.target,
    joyGotchiTreasury.target
  );
  await joyGotchiBreed.waitForDeployment();
  console.log("JoyGotchiBreed:", joyGotchiBreed.target);

  saveContract(network, "joyGotchiBreed", joyGotchiBreed.target);
  console.log("JoyGotchiBreed contract saved");

  // Deploy JoyGotchi Immidiate Use Items contract
  const JoyGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
    "JoyGotchiImmidiateUseItems"
  );
  const joyGotchiImmidiateUseItems = await JoyGotchiImmidiateUseItems.deploy(
    joyGotchiV2.target,
    joyGotchiTreasury.target,
    token.target
  );
  await joyGotchiImmidiateUseItems.waitForDeployment();
  console.log("JoyGotchiImmidiateUseItems:", joyGotchiImmidiateUseItems.target);

  saveContract(
    network,
    "joyGotchiImmidiateUseItems",
    joyGotchiImmidiateUseItems.target
  );
  console.log("JoyGotchiImmidiateUseItems contract saved");

  // Deploy JoyGotchi Staking And Mining contract
  const JoyGotchiStakingAndMining = await hre.ethers.getContractFactory(
    "JoyGotchiStakingAndMining"
  );
  const joyGotchiStakingAndMining = await JoyGotchiStakingAndMining.deploy(
    joyGotchiV2.target,
    joyGotchiItems.target,
    token.target,
    joyGotchiTreasury.target
  );
  await joyGotchiStakingAndMining.waitForDeployment();
  console.log("JoyGotchiStakingAndMining:", joyGotchiStakingAndMining.target);

  saveContract(
    network,
    "joyGotchiStakingAndMining",
    joyGotchiStakingAndMining.target
  );
  console.log("JoyGotchiStakingAndMining contract saved");

  console.log("Start Settings");

  // Settings for system JoyGotchiV2 contract
  await joyGotchiV2.setGenePool(genePool.target);
  console.log("Set GenePool success");
  await joyGotchiV2.setBreedContract(joyGotchiBreed.target);
  console.log("Set BreedContract success");
  await joyGotchiV2.setStakingAndMiningContract(
    joyGotchiStakingAndMining.target
  );
  console.log("Set StakingAndMiningContract success");
  await joyGotchiV2.setAttackContract(joyGotchiAttack.target);
  console.log("Set AttackContract success");
  await joyGotchiV2.setImmidiateUseItemsContract(
    joyGotchiImmidiateUseItems.target
  );
  console.log("Set ImmidiateUseItemsContract success");
  await joyGotchiV2.setJoyGotchiItemsContract(joyGotchiItems.target);
  console.log("Set JoyGotchiItemsContract success");

  // Settings allow contract to mint NFT for JoyGotchiItems contract
  await joyGotchiItems.setAllowAddress(joyGotchiV2.target, true);
  console.log("Allow JoyGotchiV2 for NFT items success");
  await joyGotchiItems.setAllowAddress(joyGotchiBreed.target, true);
  console.log("Allow JoyGotchiBreed for NFT items success");
  await joyGotchiItems.setAllowAddress(joyGotchiStakingAndMining.target, true);
  console.log("Allow JoyGotchiStakingAndMining for NFT items success");

  await token.transfer(faucet.target, ethers.parseEther("1000000"));
  console.log("Transfer token to faucet success");
  await token.enableTrading();
  console.log("Enable trading success");

  console.log("Done setting");
  // enable trading

  console.log("Done deploy");

  //Verify contract
  await hre.run("verify:verify", {
    address: token.target,
    constructorArguments: [contracts.uniswapV2Router02],
  });

  await hre.run("verify:verify", {
    address: joyGotchiTreasury.target,
    constructorArguments: [token.target],
  });

  await hre.run("verify:verify", {
    address: joyGotchiV2.target,
    constructorArguments: [
      token.target,
      contracts.qrngContract,
      joyGotchiTreasury.target,
    ],
  });

  await hre.run("verify:verify", {
    address: genePool.target,
    constructorArguments: [joyGotchiV2.target, 2, 2, 2],
  });

  await hre.run("verify:verify", {
    address: faucet.target,
    constructorArguments: [token.target],
  });

  await hre.run("verify:verify", {
    address: joyGotchiItems.target,
    constructorArguments: [joyGotchiV2.target],
  });

  await hre.run("verify:verify", {
    address: joyGotchiAttack.target,
    constructorArguments: [joyGotchiV2.target],
  });

  await hre.run("verify:verify", {
    address: joyGotchiBreed.target,
    constructorArguments: [
      joyGotchiV2.target,
      joyGotchiItems.target,
      token.target,
      joyGotchiTreasury.target,
    ],
  });

  await hre.run("verify:verify", {
    address: joyGotchiImmidiateUseItems.target,
    constructorArguments: [
      joyGotchiV2.target,
      joyGotchiTreasury.target,
      token.target,
    ],
  });

  await hre.run("verify:verify", {
    address: joyGotchiStakingAndMining.target,
    constructorArguments: [
      joyGotchiV2.target,
      joyGotchiItems.target,
      token.target,
      joyGotchiTreasury.target,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
