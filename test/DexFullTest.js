const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DEX Full Test Suite (Buy & Sell with BondingCurve and AMM)", function () {
  let usdc, random, dex, bondingCurve, amm;
  let owner, user;
  const usdcDecimals = 8;
  const randomDecimals = 18;

  before(async () => {
    [owner, user] = await ethers.getSigners();

    // Deploy USDC token
    const USDC = await ethers.getContractFactory("Usdc");
    usdc = await USDC.deploy(ethers.parseUnits("1000000", usdcDecimals));

    // Deploy RANDOM token
    const Random = await ethers.getContractFactory("RandomToken");
    random = await Random.deploy(ethers.parseUnits("1000000", randomDecimals));

    // Deploy BondingCurve and AMM
    const BondingCurve = await ethers.getContractFactory("BondingCurve");
    bondingCurve = await BondingCurve.deploy();

    const AMM = await ethers.getContractFactory("AMM");
    amm = await AMM.deploy(owner.address);

    // Create AMM pair and add liquidity
    await amm.createPair(usdc.target, random.target);
    await usdc.approve(amm.target, ethers.parseUnits("1000", usdcDecimals));
    await random.approve(amm.target, ethers.parseUnits("1000", randomDecimals));
    await amm.addLiquidity(
      usdc.target,
      random.target,
      ethers.parseUnits("1000", usdcDecimals),
      ethers.parseUnits("1000", randomDecimals)
    );

    // Deploy DEX
    const Dex = await ethers.getContractFactory("Mydex");
    dex = await Dex.deploy(bondingCurve.target, amm.target);

    // Register trading pair
    await dex.RegisterTradingPair(usdc.target, random.target, 2);

    // Deposit to DEX
    await usdc.approve(dex.target, ethers.parseUnits("100", usdcDecimals));
    await random.approve(dex.target, ethers.parseUnits("100", randomDecimals));
    await dex.Deposit(usdc.target, ethers.parseUnits("100", usdcDecimals));
    await dex.Deposit(random.target, ethers.parseUnits("100", randomDecimals));

    // Add liquidity to DEX
    await usdc.approve(dex.target, ethers.parseUnits("100", usdcDecimals));
    await random.approve(dex.target, ethers.parseUnits("100", randomDecimals));
    await dex.addLiquidity(
      usdc.target,
      random.target,
      ethers.parseUnits("100", usdcDecimals),
      ethers.parseUnits("100", randomDecimals)
    );
  });

  // ✅ Success Scenarios
  it("should allow buying with bonding curve", async () => {
    const amountIn = ethers.parseUnits("10", usdcDecimals);
    await usdc.approve(dex.target, amountIn);
    await expect(dex.buy(usdc.target, random.target, amountIn, true)).to.emit(dex, "Bought");
  });

  it("should allow buying with AMM", async () => {
    const amountIn = ethers.parseUnits("10", usdcDecimals);
    await usdc.approve(dex.target, amountIn);
    await expect(dex.buy(usdc.target, random.target, amountIn, false)).to.emit(dex, "Bought");
  });

  it("should allow selling with bonding curve", async () => {
    const pair = await dex.getPair(usdc.target, random.target);
    const amountIn = pair.totalSupply / 4n;
    await random.approve(dex.target, amountIn);
    await expect(dex.sell(usdc.target, random.target, amountIn, true)).to.emit(dex, "Sold");
  });

  it("should allow selling with AMM", async () => {
    const amountIn = ethers.parseUnits("5", randomDecimals);
    await random.approve(dex.target, amountIn);
    await expect(dex.sell(usdc.target, random.target, amountIn, false)).to.emit(dex, "Sold");
  });

  it("should allow token withdrawals", async () => {
    await expect(dex.withdraw(usdc.target, ethers.parseUnits("10", usdcDecimals))).to.not.be.reverted;
    await expect(dex.withdraw(random.target, ethers.parseUnits("10", randomDecimals))).to.not.be.reverted;
  });

  // ❌ Failure Cases
  it("should revert if pair is not found on addLiquidity", async () => {
    const fakeToken = await ethers.deployContract("RandomToken", [ethers.parseUnits("100000", 18)]);
    await fakeToken.approve(dex.target, ethers.parseUnits("10", 18));
    await expect(dex.addLiquidity(fakeToken.target, random.target, 1, 1)).to.be.revertedWith("Pair not found");
  });

  it("should revert on zero input buy", async () => {
    await expect(dex.buy(usdc.target, random.target, 0, true)).to.be.revertedWith("Input must be > 0");
  });

  it("should revert on zero input sell", async () => {
    await expect(dex.sell(usdc.target, random.target, 0, false)).to.be.revertedWith("Input must be > 0");
  });

  it("should revert on over-withdrawal", async () => {
    const bigAmount = ethers.parseUnits("10000000", usdcDecimals);
    await expect(dex.withdraw(usdc.target, bigAmount)).to.be.revertedWith("Insufficient balance");
  });

  it("should revert on adding existing pair", async () => {
    await expect(
      dex.RegisterTradingPair(usdc.target, random.target, 2)
    ).to.be.revertedWith("Pair exists");
  });

  it("should revert if AMM reserves are zero", async () => {
    const TokenX = await ethers.getContractFactory("RandomToken");
    const x = await TokenX.deploy(ethers.parseUnits("100000", 18));
    const y = await TokenX.deploy(ethers.parseUnits("100000", 18));

    await dex.RegisterTradingPair(x.target, y.target, 1);
    await x.approve(dex.target, ethers.parseUnits("1", 18));
    await expect(
      dex.buy(x.target, y.target, ethers.parseUnits("1", 18), false)
    ).to.be.revertedWith("Invalid reserves");
  });
});
