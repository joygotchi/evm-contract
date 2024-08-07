const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");

// Example of creating an item prototype (keep in mind that the attributes for breed and mining only set if the item is for breed or mining)
const IMAGE = "https://www.pinterest.com/pin/695735842470093598/"; // image url of the item
// const RARITY = 1; // 0 - Common, 1 - Rare, 2 - Legendary, 3 - Epic
const TYPE = 0; // CREATE MINE TOOL ONLY, 1 is for PETCARD
// const MINING_POWER = "300"; // Mining power of the item (used to calculate mining points earned each mining), set to 0 if item is not for mining
// const MINING_CHARGE_TIME = "86400"; // 1 day, set to 0 if item is not for mining

const listNFTItems = [
  {
    image: IMAGE,
    rarity: 0,
    type: TYPE,
    miningPower: "300",
    miningChargeTime: "3600", // 1 hour
  },
  {
    image: IMAGE,
    rarity: 1,
    type: TYPE,
    miningPower: "500",
    miningChargeTime: "1800", // 30 minutes
  },
  {
    image: IMAGE,
    rarity: 2,
    type: TYPE,
    miningPower: "1000",
    miningChargeTime: "900", // 15 minutes
  },
  {
    image: IMAGE,
    rarity: 3,
    type: TYPE,
    miningPower: "2000",
    miningChargeTime: "600", // 10 minutes
  },
];

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

  // Create prototype items
  // Prototype items are the base items that will be used to create the actual items that will be distribute to the users
  for (let i = 0; i < listNFTItems.length; i++) {
    const item = listNFTItems[i];

    await raiGotchiItems.createPrototypeItem(
      item.image,
      item.rarity,
      item.type,
      item.miningPower,
      item.miningChargeTime
    );

    console.log("Item created: ", i);
  }

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
