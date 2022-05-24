import { expect } from "chai";
import { ethers } from "hardhat";

describe("Elliot Token contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("ElliotToken");

    const hardhatToken = await Token.deploy(1000);

    const ownerBalance = await hardhatToken.balanceOf(owner.address);
    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });
});
