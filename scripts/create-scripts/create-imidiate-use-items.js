const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");

const NAME = "ITEM 1";
const PRICE = parseUnits("1000", 18); // 1000 tokens with 18 decimals
const PRICE_DELTA = parseUnits("1", 18); // Each time an item is sold, the price increases by 1 token
const POINTS = parseUnits("1", 12); // Points earned by using the item (Pet's XP) (Unit is multiplied by 10^12)
const STOCK = "100"; // Maximum number of items available
const TIME = "86400"; // 1 day, time extension for the pet starving time
const SHIELD = "1"; // 1 shield, Shield boost for the pet to avoid attacks
const ATTACK_BOOST = "1"; // 1 attack boost, boost attack attribute for the pet
const DEFENSE_BOOST = "1"; // 1 defense boost, boost defense attribute for the pet
const IS_REVIVAL = false; // Define if item can revive a dead pet
const IS_ACCESSORY = false; // Define if item is an accessory

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
  await raiGotchiImmidiateUseItems.createImidiateUseItem(
    NAME,
    PRICE,
    PRICE_DELTA,
    STOCK,
    POINTS,
    TIME,
    SHIELD,
    ATTACK_BOOST,
    DEFENSE_BOOST,
    IS_REVIVAL,
    IS_ACCESSORY
  );

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
