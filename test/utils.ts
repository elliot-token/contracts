import { network } from "hardhat";

const setBlockTimestamp = async (date: Date) => {
  await network.provider.send("evm_setNextBlockTimestamp", [
    Math.floor(date.getTime() / 1000),
  ]);
  await network.provider.send("evm_mine");
};

const testUtils = {
  setBlockTimestamp,
};

export default testUtils;
