const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");


/// Noted: 
/// Must breed before claim breed
/// breed-scripts/breed.js


async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);
  
    const RaiGotchiBreed = await hre.ethers.getContractFactory(
      "RaiGotchiBreed"
    );
    const raiGotchiBreed = RaiGotchiBreed.attach(
      contracts.raiGotchiBreed
    );

    const txclaimBreed = await raiGotchiBreed.claimBreed(1, { gasLimit: 3000000 });
    
    await txclaimBreed.wait();


    console.log("Done claim breed");
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });




