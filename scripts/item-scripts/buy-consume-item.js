const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");


/// Noted 
/// Before calling buy and consume item 
/// Must create items first 
/// create-and-setting-scripts/create-nft-item.js

async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);
  
    const RaiGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
      "RaiGotchiImmidiateUseItems"
    );
    const raiGotchiImmidiateUseItems = RaiGotchiImmidiateUseItems.attach(
      contracts.raiGotchiImmidiateUseItems
    );


    const RaiGotchiToken= await hre.ethers.getContractFactory(
        "RaiGotchiToken"
      );
      const raiGotchiToken= RaiGotchiToken.attach(
        contracts.token
    );


    const tx = await raiGotchiToken.approve(contracts.raiGotchiImmidiateUseItems, parseUnits("100", 18))
    
    await tx.wait();
    console.log("Approve token successfully for pet 0");


  
    // Buy item with item id = 1 Water for NFT id 0 


    // param1 : nftId
    // param2: itemId 
    const txBuy = await raiGotchiImmidiateUseItems.buyImidiateUseItem(0, 1);
    await txBuy.wait();
    console.log(`Buy item successfully for pet 0`);



    const txConsume = await raiGotchiImmidiateUseItems.consumeItem(0, 1);
    await txConsume.wait();
    console.log("Done consume items for pet id 0");


    const txBuy1 = await raiGotchiImmidiateUseItems.buyImidiateUseItem(1, 1);
    await txBuy1.wait();
    console.log(`Buy item successfully for pet 1`);



    const txConsume1 = await raiGotchiImmidiateUseItems.consumeItem(1, 1);
    await txConsume1.wait();
    console.log("Done consume items for pet id 1");
    
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });






