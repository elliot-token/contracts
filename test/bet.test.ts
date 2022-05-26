import { ethers, network } from "hardhat";
import { Contract, Signer } from "ethers";
import chai, { expect, assert } from "chai";
chai;
import BN from "bn.js";
import testUtils from "./utils";
import { addDays } from "date-fns";

chai.use(require("chai-as-promised"));

const DECIMALS = "18";
const INITIAL_PRICE = "200000000000000000000";
const BULLISH_PRICE = "203000000000000000000";

describe("Bet contract", function () {
  let contract: Contract;
  let tokenContract: Contract;
  let mockAggregatorContract: Contract;
  let datetimeContract: Contract;

  const setResolverRound = async (resolverTime: Date) => {
    const timestamp = Math.floor(resolverTime.getTime() / 1000);
    await mockAggregatorContract.updateRoundData(
      123,
      BULLISH_PRICE,
      timestamp,
      "2"
    );
    await contract.setResolverRound(timestamp, 123);
  };
  beforeEach(async () => {
    const BetContract = await ethers.getContractFactory("BetContract");
    const TokenContract = await ethers.getContractFactory("ElliotToken");

    const DateTimeContract = await ethers.getContractFactory("DateTime");
    const MockV3Aggregator = await ethers.getContractFactory(
      "MockV3Aggregator"
    );

    mockAggregatorContract = await MockV3Aggregator.deploy(
      DECIMALS,
      INITIAL_PRICE
    );
    datetimeContract = await DateTimeContract.deploy();
    tokenContract = await TokenContract.deploy("10000000000000000000");
    contract = await BetContract.deploy(
      mockAggregatorContract.address,
      tokenContract.address,
      datetimeContract.address,
      [
        [-2, 0, 121],
        [0, 2, 154],
      ]
    );
    tokenContract.transfer(contract.address, "5000000000000000000");

    const [owner, addr1] = await ethers.getSigners();
  });
  afterEach(async () => {
    await network.provider.send("hardhat_reset");
  });

  it("deployment should assign owner", async function () {
    const [owner] = await ethers.getSigners();
    expect(await contract.getOwner()).to.equal(owner.address);
  });

  it("deployment should create Options", async function () {
    assert.deepEqual(
      (await contract.options(0)).map((v: BN) => v.toNumber()),
      [0, -2, 0, 121]
    );
    assert.deepEqual(
      (await contract.options(1)).map((v: BN) => v.toNumber()),
      [1, 0, 2, 154]
    );
  });

  it("placeBet should fail if insufficient bet amount", () => {
    return assert.isRejected(
      contract.placeBet(20, 1),
      /Bet should be at least/
    );
  });

  it("placeBet should fail if insufficient ELL", async () => {
    const [, addr1] = await ethers.getSigners();
    return assert.isRejected(
      contract.connect(addr1).placeBet("100000000000000001", 1),
      /insufficient allowance/
    );
  });

  it("placeBet should fail if insufficient ELL allowance", () => {
    return assert.isRejected(
      contract.placeBet("100000000000000001", 1),
      /insufficient allowance/
    );
  });

  it("placeBet should fail if invalid optionId", async () => {
    await tokenContract.approve(contract.address, "100000000000000002");
    return assert.isRejected(
      contract.placeBet("100000000000000001", 3),
      /Option does not exist/
    );
  });

  it("placeBet should add Bet to mapping if sufficient ELL", async () => {
    const [owner] = await ethers.getSigners();
    await tokenContract.approve(contract.address, "100000000000000002");
    await testUtils.setBlockTimestamp(new Date("2030-04-11T12:22:10"));
    await contract.placeBet("100000000000000001", 1);
    const newBet = await contract.bets(owner.address, 0);
    expect(newBet[0]).to.equal("100000000000000001");
    expect(newBet[1]).to.equal("1");
    expect(newBet[2]).to.equal("0");
    expect(newBet[4]).to.equal(false);
    expect(newBet[5]).to.equal("154");
    expect(newBet[7]).to.equal(
      Math.floor(new Date("2030-04-11T23:00:00").getTime() / 1000).toString()
    );
  });

  it("setResolverRound must fail if timestamp is in the future", () => {
    return assert.isRejected(contract.setResolverRound(1902171600, 123));
  });

  it("setResolverRound must fail if roundId does not correspond to stuff", async () => {
    const resolverTimeStamp = Math.floor(
      new Date("2019-04-11T12:22:10").getTime() / 1000
    );
    await mockAggregatorContract.updateRoundData(
      123,
      BULLISH_PRICE,
      Math.floor(new Date("2019-04-11T13:22:10").getTime() / 1000),
      "2"
    );
    return assert.isRejected(
      contract.setResolverRound(resolverTimeStamp, 123),
      /Round timestamp does not match timestamp/
    );
  });

  it("setResolverRound must set resolvedPrices mapping", async () => {
    const resolverTimeStamp = Math.floor(
      new Date("2019-04-11T12:22:10").getTime() / 1000
    );
    await mockAggregatorContract.updateRoundData(
      123,
      BULLISH_PRICE,
      resolverTimeStamp,
      "2"
    );
    await contract.setResolverRound(resolverTimeStamp, 123);
    expect(await contract.resolvedPrices(resolverTimeStamp)).to.equal(
      BULLISH_PRICE
    );
  });

  it("resolveBet should fail if betId does not exists", () => {
    return assert.isRejected(
      contract.resolveBet(2, 0),
      /Corresponding bet not found/
    );
  });

  it("resolveBet should fail if corresponding bet does not belong to caller", async () => {
    const [, addr1] = await ethers.getSigners();
    await tokenContract.approve(contract.address, "100000000000000002");
    await contract.placeBet("100000000000000001", 1);
    return assert.isRejected(
      contract.connect(addr1).resolveBet(0, 1),
      /Corresponding bet not found/
    );
  });

  it("resolveBet should fail if try to resolve before date", async () => {
    await tokenContract.approve(contract.address, "100000000000000001");
    await testUtils.setBlockTimestamp(new Date("3030-04-11T12:22:00"));
    await contract.placeBet("100000000000000001", 1);
    await testUtils.setBlockTimestamp(new Date("3030-04-11T14:22:00"));
    return assert.isRejected(
      contract.resolveBet(0, 1),
      /Too soon to resolve bet/
    );
  });

  it("resolveBet should fail if no resolved price found", async () => {
    const tomorrow = addDays(new Date(), 1);
    console.log(tomorrow.getTime());
    testUtils.setBlockTimestamp(new Date("3030-04-11T12:22:00"));
    await tokenContract.approve(contract.address, "100000000000000001");
    await contract.placeBet("100000000000000001", 1);
    testUtils.setBlockTimestamp(new Date("3030-04-11T23:22:00"));
    return assert.isRejected(contract.resolveBet(0, 1), /No resolved price/);
  });

  it("resolveBet should mark placed bet as resolved", async () => {
    const [owner] = await ethers.getSigners();
    await tokenContract.approve(contract.address, "100000000000000002");
    await testUtils.setBlockTimestamp(new Date("3030-04-11T14:22:00"));
    await contract.placeBet("100000000000000001", 1);

    let correspondingBet = await contract.bets(owner.address, 0);
    expect(correspondingBet[4]).to.be.false;
    await testUtils.setBlockTimestamp(new Date("3030-04-11T23:22:00"));
    await setResolverRound(new Date("3030-04-11T21:00:00+0000"));
    await contract.resolveBet(0, 1);
    correspondingBet = await contract.bets(owner.address, 0);
    expect(correspondingBet[4]).to.be.true;
  });

  it("resolveBet should fail if bet resolved", async () => {
    const [owner] = await ethers.getSigners();
    await tokenContract.approve(contract.address, "100000000000000002");
    await testUtils.setBlockTimestamp(new Date("3030-04-11T12:22:00"));
    await contract.placeBet("100000000000000001", 1);

    await testUtils.setBlockTimestamp(new Date("3030-04-11T23:28:00"));
    await setResolverRound(new Date("3030-04-11T21:00:00+00:00"));

    await testUtils.setBlockTimestamp(new Date("3030-04-11T23:30:00"));
    await contract.resolveBet(0, 1);

    testUtils.setBlockTimestamp(new Date("3030-04-11T23:45:00"));
    return assert.isRejected(contract.resolveBet(0, 1), /Bet already resolved/);
  });

  it("resolveBet should transfer ELL to address if bet won", async () => {
    const [_, addr1] = await ethers.getSigners();
    await tokenContract.transfer(addr1.address, "100000000000000002");
    await tokenContract
      .connect(addr1)
      .approve(contract.address, "100000000000000002");
    expect(await tokenContract.balanceOf(addr1.address)).to.equal(
      "100000000000000002"
    );
    await testUtils.setBlockTimestamp(new Date("3030-04-11T12:22:00+00:00"));
    await contract.connect(addr1).placeBet("100000000000000001", 1);
    expect(await tokenContract.balanceOf(addr1.address)).to.equal(1);

    await testUtils.setBlockTimestamp(new Date("3030-04-11T23:22:00+00:00"));
    await setResolverRound(new Date("3030-04-11T21:00:00+00:00"));

    await testUtils.setBlockTimestamp(new Date("3030-04-11T23:52:00+00:00"));
    await contract.connect(addr1).resolveBet(0, 1235);

    expect(await tokenContract.balanceOf(addr1.address)).to.equal(
      "154000000000000002"
    );
  });
});
