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

    async function redeemMiningPoints() {
        try {
            const tx = await raiGotchiStaking.redemnMiningPoints();
            await waitForTx(tx);
            console.log("Mining points redeemed successfully");

        } catch (error) {
            console.error("Redeeming mining points failed:", error.message);
        }
    }

    try {
        await redeemMiningPoints();
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
