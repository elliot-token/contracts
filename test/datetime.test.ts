import { assert, expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("Datetime contract", () => {
  let contract: Contract;
  beforeEach(async () => {
    const DateTimeContract = await ethers.getContractFactory("DateTime");
    contract = await DateTimeContract.deploy();
  });
  it("should return 9pm current day if before 3pm", async () => {
    const date = new Date("1995-04-10T12:40:20+01:00");
    const resolvedAfter = await contract.getResolvedAfter(
      date.getTime() / 1000
    );
    expect(resolvedAfter).to.equal(
      `${new Date("1995-04-10T21:00:00+00:00").getTime() / 1000}`
    );
  });
  it("should return 9pm next day if after 3pm", async () => {
    const date = new Date("1995-04-10T22:40:20+01:00");
    const resolvedAfter = await contract.getResolvedAfter(
      date.getTime() / 1000
    );
    expect(resolvedAfter).to.equal(
      `${new Date("1995-04-11T21:00:00+00:00").getTime() / 1000}`
    );
  });
});
