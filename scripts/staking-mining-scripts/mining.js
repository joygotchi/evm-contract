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

    async function performMining() {

        try {
            const tx = await raiGotchiStaking.mining();
            await waitForTx(tx);
            console.log("Mining operation completed successfully");

        } catch (error) {
            console.error("Mining operation failed:", error.message);
        }
    }

    try {
        await performMining();
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
