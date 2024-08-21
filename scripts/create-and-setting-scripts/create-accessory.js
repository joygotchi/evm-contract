const { parseUnits } = require("ethers");
const hre = require("hardhat");
const { getContracts } = require("../utils");

const listItems = [
  {
    typeBackground: 1,
    furniture: 0,
    price: parseUnits("1", 18), // 1 token with 18 decimals
  },
  {
    typeBackground: 2,
    furniture: 0,
    price: parseUnits("1", 18),
  },
  {
    typeBackground: 0,
    furniture: 1,
    price: parseUnits("2", 18), // 2 token with 18 decimals
  },
  {
    typeBackground: 0,
    furniture: 2,
    price: parseUnits("2", 18),
  },
];

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const RaiGotchiAccessory = await hre.ethers.getContractFactory(
    "RaiGotchiAccessory"
  );
  const raiGotchiAccessory = RaiGotchiAccessory.attach(
    contracts.raiGotchiAccessory
  );

  // Create prototype items
  for (let i = 0; i < listItems.length; i++) {
    const item = listItems[i];

    await raiGotchiAccessory.createAccessory(
      item.typeBackground,
      item.furniture,
      item.price
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
