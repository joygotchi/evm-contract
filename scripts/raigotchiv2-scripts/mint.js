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


    // Approve minPrice token to treasury 
    // we set minPrice = 1 Token 
    const tx = await raiGotchiToken.approve(contracts.raiGotchiTreasury, parseUnits("10", 18))
    
    await tx.wait();

    const allowanceAfter = await raiGotchiToken.allowance(user.address, contracts.raiGotchiTreasury);
    console.log("Allowance after approval:", allowanceAfter.toString());

    // desiredSpecies 

    const txMint = await raiGotchiV2.mint(0);
    await txMint.wait();
    console.log("Done");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });




