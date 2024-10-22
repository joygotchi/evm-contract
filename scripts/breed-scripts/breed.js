const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");


/// Noted: 
/// Must create 2 raigotchi 
/// raigotchiv2-scripts/mint.js

async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);
  
    const RaiGotchiBreed = await hre.ethers.getContractFactory(
      "RaiGotchiBreed"
    );
    const raiGotchiBreed = RaiGotchiBreed.attach(
      contracts.raiGotchiBreed
    );

    const RaiGotchiV2 = await hre.ethers.getContractFactory(
        "RaiGotchiV2"
      );
    const raiGotchiV2 = RaiGotchiV2.attach(
        contracts.raiGotchiV2
    );

    const RaiGotchiToken= await hre.ethers.getContractFactory(
        "RaiGotchiToken"
      );
      const raiGotchiToken= RaiGotchiToken.attach(
        contracts.token
      );



    // Aprrove pet 1 with token id = 0 
    const tx1 = await raiGotchiV2.approve(contracts.raiGotchiBreed, 0)
    
    await tx1.wait();
    console.log("Approve NFT successfully 1"); 


    // Approve pet 2 

    const tx2 = await raiGotchiV2.approve(contracts.raiGotchiBreed, 1)
    
    await tx2.wait();
    console.log("Approve NFT successfully 2"); 


    // Approve token 

    const tx = await raiGotchiToken.approve(contracts.raiGotchiBreed, parseUnits("1000", 18))
    
    await tx.wait();
    console.log("Approve token successfully");



    const txBreed = await raiGotchiBreed.breed(0, 1, { gasLimit: 3000000 });
    
    await txBreed.wait();


    console.log("Done");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });


