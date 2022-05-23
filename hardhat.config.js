require("@nomiclabs/hardhat-waffle");

const ALCHEMY_API_KEY = "Sgz6bc2NPV1oA4JLnmgBLEmiRVmlWaxq";
const ROPSTEN_PRIVATE_KEY =
  "efece52df42960b6796df1dcf655550daaf19247b9464bc2b0ba4cd2c4e5fdfb";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.11",
  networks: {
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${ROPSTEN_PRIVATE_KEY}`],
    },
    kovan: {
      url: "https://eth-kovan.alchemyapi.io/v2/2ZKTg8koyehGPbox6erkvZ6GhjtED5P3",
      accounts: [
        "efece52df42960b6796df1dcf655550daaf19247b9464bc2b0ba4cd2c4e5fdfb",
      ],
    },
  },
};
