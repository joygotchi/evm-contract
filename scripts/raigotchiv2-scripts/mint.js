const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");


/// Noted 
/// Before calling mint pet 
/// Must create species and items first 
/// create-and-setting-scripts/create-species.js
/// create-and-setting-scripts/create-nft-item.js

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

    const RaiGotchiToken= await hre.ethers.getContractFactory(
      "RaiGotchiToken"
    );
    const raiGotchiToken= RaiGotchiToken.attach(
      contracts.token
    );


    // Approve minPrice token to raiGotchiV2 contract address 
    // we set minPrice = 1 Token 
    const tx = await raiGotchiToken.approve(contracts.raiGotchiV2, parseUnits("1", 18))
    
    await tx.wait();
    console.log("Approve token successfully for pet 1");
    // desiredSpecies 

    const txMintPet1 = await raiGotchiV2.mint(0);
    await txMintPet1.wait();
    console.log("Done Pet 1");

    const tx2 = await raiGotchiToken.approve(contracts.raiGotchiV2, parseUnits("1", 18))
    
    await tx2.wait();
    console.log("Approve token successfully for pet 2");

    const txMintPet2 = await raiGotchiV2.mint(1);
    await txMintPet2.wait();

    console.log("Done Pet 2");

  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });




