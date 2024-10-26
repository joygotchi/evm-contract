const hre = require("hardhat");
const { getContracts } = require("../utils");
const { parseEther } = require("ethers");


async function main() {
    const network = hre.network.name;
    const contracts = getContracts(network);

    const RaiGotchiStaking = await hre.ethers.getContractFactory(
        "RaiGotchiStakingAndMining"
    );
    const raiGotchiStaking = RaiGotchiStaking.attach(
        contracts.raiGotchiStakingAndMining
    );

    const RaiGotchiToken = await hre.ethers.getContractFactory(
        "RaiGotchiToken"
    );
    const raiGotchiToken = RaiGotchiToken.attach(
        contracts.token
    );
    // Stake
    async function stake(poolId) {
        console.log(`\nStaking in pool ${poolId}...`);

        // Approve tokens first
        const approveTx = await raiGotchiToken.approve(contracts.raiGotchiStakingAndMining, parseEther("1000"));
        await waitForTx(approveTx);

        const tx = await raiGotchiStaking.stake(poolId);
        await waitForTx(tx);
        console.log("Staking successful");
    }

    try {

        await stake(1);

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