const hre = require("hardhat");

const NAME = "ITEM 1";
const PRICE = parseUnits("1000", 18); // 1000 tokens with 18 decimals
const POINTS = parseUnits("1", 12); // 1*(10^12)
const TIME = "86400"; // 1 day

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const JoyGotchiItems = await hre.ethers.getContractFactory("JoyGotchiItems");
  const joyGotchiItems = JoyGotchiItems.attach(contracts.joyGotchiItems);

  // Create prototype items

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
