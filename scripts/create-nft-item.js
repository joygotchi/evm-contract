const { parseUnits } = require("ethers");
const hre = require("hardhat");

// Example of creating an item prototype (keep in mind that the attributes for breed and mining only set if the item is for breed or mining)
const IMAGE = "https://www.pinterest.com/pin/695735842470093598/"; // image url of the item
const RARITY = 1; // 0 - Common, 1 - Rare, 2 - Legendary, 3 - Epic
const COOL_DOWN_BREED_TIME = "86400"; // 1 day, set to 0 if item is not for breed
const REDUCE_BREED_FEE = parseUnits("1", 18); // 1 tokens, set to 0 if item not for breed
const POINTS = parseUnits("1", 12); // Points earned by using the item (Pet's XP) (Unit is multiplied by 10^12)
const TYPE = 0; // 0 - Accessory Item, 1 - Breed Item, 2 - Mining Item
const MINING_POWER = "300"; // Mining power of the item (used to calculate mining points earned each mining), set to 0 if item is not for mining
const MINING_CHARGE_TIME = "86400"; // 1 day, set to 0 if item is not for mining

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

  // Create prototype items
  // Prototype items are the base items that will be used to create the actual items that will be distribute to the users
  await raiGotchiItems.createPrototypeItem(
    IMAGE,
    RARITY,
    COOL_DOWN_BREED_TIME,
    REDUCE_BREED_FEE,
    POINTS,
    TYPE,
    MINING_POWER,
    MINING_CHARGE_TIME
  );

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
