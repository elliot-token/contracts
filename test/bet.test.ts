import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import chai, { expect, assert } from "chai";
import BN from "bn.js";

chai.use(require("chai-as-promised"));

describe("Bet contract", function () {
  let contract: Contract;
  let tokenContract: Contract;
  beforeEach(async () => {
    const BetContract = await ethers.getContractFactory("BetContract");
    const TokenContract = await ethers.getContractFactory("ElliotToken");

    tokenContract = await TokenContract.deploy("10000000000000000000");
    contract = await BetContract.deploy(tokenContract.address, [
      [-2, 0, 121],
      [0, 2, 154],
    ]);
  });
  it("deployment should assign the token address", async function () {
    expect(await contract.tokenAddress()).to.equal(tokenContract.address);
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

  it("placeBet should fail if insufficient bet amount", async () => {
    (await expect(contract.placeBet(20, 1, "toto"))).to.be
      /* @ts-ignore */
      .rejectedWith(Error);
  });

  it("placeBet should fail if insufficient ELL", async () => {
    // TODO
    // how to create another caller address ?
  });

  it("placeBet should fail if insufficient ELL allowance", async () => {
    await expect(contract.placeBet("100000000000000001", 1))
      .to.be /* @ts-ignore */
      .rejectedWith(Error);
  });

  it("placeBet should fail if invalid optionId", async () => {
    await tokenContract.approve(contract.address, "100000000000000002");
    await expect(contract.placeBet("100000000000000001", 3))
      .to.be /* @ts-ignore */
      .rejectedWith(Error);
  });

  it("placeBet should add Bet to mapping if sufficient ELL", async () => {
    const [owner] = await ethers.getSigners();
    await tokenContract.approve(contract.address, "100000000000000002");
    await contract.placeBet("100000000000000001", 1);
    const newBet = await contract.placedBets(owner.address, 0);
    expect(newBet[0]).to.equal("100000000000000001");
    expect(newBet[1]).to.equal("1");
    expect(newBet[2]).to.equal("0");
    // ETH is worth $ 1966 at the time of writing
    // it can only go higher right ?
    // RIGHT ?
    expect(newBet[3] >= "196617000000").to.be.true;
  });
});
