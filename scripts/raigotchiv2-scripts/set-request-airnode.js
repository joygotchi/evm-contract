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
  // Settings QRNG contract (need to change sponsor wallet in config file correspondingly to the raigotchiV2 contract)
    await raiGotchiV2.setRequestParameters(
        contracts.airnodeAddress,
        contracts.endpointIdUint256,
        contracts.sponsorWallet
    );
    console.log("Done set request Parameters Airnode");


  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });





