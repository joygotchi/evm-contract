const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");

// const NAME = "ITEM 1";
// const PRICE = parseUnits("1000", 18); // 1000 tokens with 18 decimals
// const PRICE_DELTA = parseUnits("1", 18); // Each time an item is sold, the price increases by 1 token
// const POINTS = parseUnits("1", 12); // Points earned by using the item (Pet's XP) (Unit is multiplied by 10^12)
// const STOCK = "100"; // Maximum number of items available
// const TIME = "86400"; // 1 day, time extension for the pet starving time
// const SHIELD = "1"; // 1 shield, Shield boost for the pet to avoid attacks
// const IS_REVIVAL = false; // Define if item can revive a dead pet

const listItems = [
  {
    name: "Beef",
    price: parseUnits("1", 18), // 1 token with 18 decimals
    price_delta: 0,
    stock: 9993,
    points: parseUnits("1000", 12), // 1000 point (Pet's XP) (Unit is multiplied by 10^12)
    time_extension: "10800000",
    shield: 0,
    is_revival: false,
  },
  {
    name: "Water",
    price: parseUnits("1", 18), // 1 token with 18 decimals
    price_delta: parseUnits("1", 18), // Each time an item is sold, the price increases by 1 token
    stock: 9998,
    points: parseUnits("10000", 12), // 10000 point (Pet's XP) (Unit is multiplied by 10^12)
    time_extension: "10800000",
    shield: 0,
    is_revival: false,
  },
  {
    name: "Shield",
    price: parseUnits("1", 18), // 1 token with 18 decimals
    price_delta: parseUnits("1", 18), // Each time an item is sold, the price increases by 1 token
    stock: 9998,
    points: parseUnits("100", 12), // 100 point (Pet's XP) (Unit is multiplied by 10^12)
    time_extension: 0,
    shield: 1,
    is_revival: false,
  },
  {
    name: "Revive water",
    price: parseUnits("10", 18), // 10 token with 18 decimals
    price_delta: parseUnits("10", 18), // Each time an item is sold, the price increases by 1 token
    stock: 9998,
    points: parseUnits("10000", 12), // 10000 point (Pet's XP) (Unit is multiplied by 10^12)
    time_extension: "10800000",
    shield: 0,
    is_revival: true,
  },
];

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiImmidiateUseItems = await hre.ethers.getContractFactory(
    "RaiGotchiImmidiateUseItems"
  );
  const raiGotchiImmidiateUseItems = RaiGotchiImmidiateUseItems.attach(
    contracts.raiGotchiImmidiateUseItems
  );

  // Create prototype items
  for (let i = 0; i < listItems.length; i++) {
    const item = listItems[i];

    await raiGotchiImmidiateUseItems.createImidiateUseItem(
      item.name,
      item.price,
      item.price_delta,
      item.stock,
      item.points,
      item.time_extension,
      item.shield,
      item.is_revival
    );

    console.log("Item created: ", item.name);
  }

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
