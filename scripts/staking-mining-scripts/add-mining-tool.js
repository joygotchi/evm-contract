const hre = require("hardhat");
const { getContracts } = require("../utils");

async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);

    const RaiGotchiStaking = await hre.ethers.getContractFactory(
        "RaiGotchiStakingAndMining"
    );
    const raiGotchiStaking = RaiGotchiStaking.attach(
        contracts.raiGotchiStakingAndMining
    );

    const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
    const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

    // Add Mining Tool
    async function addMiningTool(toolId) {
        console.log(`\nAdding mining tool with ID ${toolId}...`);

        const approveTx = await raiGotchiItems.approve(contracts.raiGotchiStakingAndMining, toolId);
        await waitForTx(approveTx);
        console.log("NFT approved for staking contract");

        const tx = await raiGotchiStaking.addMiningTool(toolId);
        await waitForTx(tx);
        console.log("Mining tool added successfully");
    }

    try {
        await addMiningTool(0);
    } catch (error) {
        console.error("Error:", error.message);
    }
}

const waitForTx = async (tx) => {
    console.log(`Transaction hash: ${tx.hash}`);
    await tx.wait();
    console.log("Transaction confirmed");
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
