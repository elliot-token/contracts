import { network } from "hardhat";

const setBlockTimestamp = async (value: number) => {
  await network.provider.send("evm_setNextBlockTimestamp", [1625097600]);
  await network.provider.send("evm_mine");
};

const testUtils = {
  setBlockTimestamp,
};

export default testUtils;
