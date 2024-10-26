require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("hardhat-contract-sizer");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.22",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/RF2vrEEq0BgZ9u8H1gY2nogOTZnEta23",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155111,
      gas: "auto",
    },
    vicTest: {
      url: "https://rpc.testnet.tomochain.com",
      accounts: [process.env.PRIVATE_KEY],
      gas: "auto",
    },
    vicTestNew: {
      url: "https://rpc-testnet.viction.xyz",
      accounts: [process.env.PRIVATE_KEY],
      gas: "auto",
    },
    vicMain: {
      url: "https://rpc.viction.xyz",
      accounts: [process.env.PRIVATE_KEY],
      gas: "auto",
    },
    modeTest: {
      url: "https://sepolia.mode.network",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 919,
      gas: "auto",
    },
    modeMain: {
      url: "https://mainnet.mode.network",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 34443,
      gas: "auto",
    },
    auroraTest: {
      url: "https://testnet.aurora.dev",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 1313161555,
      gas: "auto",
    },
    auroraMain: {
      url: "https://mainnet.aurora.dev",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 1313161554,
      gas: "auto",
    },
    // for mainnet
    lightlinkMain: {
      url: "https://replicator.phoenix.lightlink.io/rpc/v1",
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
    // for testnet
    lightlinkTest: {
      url: "https://replicator.pegasus.lightlink.io/rpc/v1",
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
    moonbase: {
      url: "https://rpc.api.moonbase.moonbeam.network",
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000,
    },
  },
  etherscan: {
    apiKey: { moonbaseAlpha: "VI9UK5ZWEM3TPTV4N49TEMP79WCT83W2QK", auroraTest: "UH96CTNSM4GUIEDDHRE7Y17SVV7ND6W3XV"}
    ,
    customChains: [
      {
        network: "lightlinkMain",
        chainId: 1891,
        urls: {
          apiURL: "https://pegasus.lightlink.io/api",
          browserURL: "https://pegasus.lightlink.io",
        },
      },
      {
        network: "lightlinkTest",
        chainId: 88,
        urls: {
          apiURL: "https://devnet.lightlink.io/api",
          browserURL: "https://devnet.lightlink.io",
        },
      },
      {
        network: "auroraTest",
        chainId: 1313161555,
        urls: {
          apiURL: "https://explorer.testnet.aurora.dev/api",
          browserURL: "https://explorer.testnet.aurora.dev",
        },
      },
    ],
  },
  mocha: {
    timeout: 100000000,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
};
