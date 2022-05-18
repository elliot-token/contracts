// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const ElliotToken = await hre.ethers.getContractFactory("ElliotToken");
  const elliotTokenDeployTask = await ElliotToken.deploy(
    "1000000000000000000000000"
  );
  await elliotTokenDeployTask.deployed();
  console.log("Token deployed to:", elliotTokenDeployTask.address);

  // We get the contract to deploy
  const Betting = await hre.ethers.getContractFactory("Betting");
  const betDeployTask = await Betting.deploy(elliotTokenDeployTask.address);

  await betDeployTask.deployed();
  console.log("Bet deployed to:", betDeployTask.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
