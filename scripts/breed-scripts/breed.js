const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");



async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);
  
    const RaiGotchiBreed = await hre.ethers.getContractFactory(
      "RaiGotchiBreed"
    );
    const raiGotchiBreed = RaiGotchiBreed.attach(
      contracts.raiGotchiBreed
    );

    // Aprrove pet 1 

    // Approve pet 2 

    
  
    console.log("Done");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });


