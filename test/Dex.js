const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UsdcToken", () => {
  it("Should deploy and print address", async () => {
    const [owner, otherAccount] = await ethers.getSigners();
    const UsdcToken = await ethers.getContractFactory("Usdc");
    const usdcDecimals = 6;
    const initialUsdcSupply = ethers.parseUnits("1000000", usdcDecimals);
    const usdcToken = await UsdcToken.deploy(initialUsdcSupply);

    console.log("USDC deployed at:", usdcToken.target);
  });
});

describe("RandomTokn", () => {
  it("Should deploy and print address", async () => {
    const [owner, otherAccount] = await ethers.getSigners();
    const RandomToken = await ethers.getContractFactory("RandomToken");
    const randomDecimals = 18;
    const initialRandomSupply = ethers.parseUnits("1000000", randomDecimals);
    const randomToken = await RandomToken.deploy(initialRandomSupply);
    console.log("RandomToken deployed at:", randomToken.target);
  });
});




describe("DEX Full Test Suite (Buy & Sell with BondingCurve and AMM)", () => {
  it("should test full functionality of the DEX", async () => {
    const [owner] = await ethers.getSigners();
    console.log("\n--- DEX FULL TEST ---");
    console.log("Owner:", owner.address);

    // Deploy USDC token
    const USDC = await ethers.getContractFactory("Usdc");
    const usdcDecimals = 8;
    const usdc = await USDC.deploy(ethers.parseUnits("1000000", usdcDecimals));
    console.log("USDC deployed at:", usdc.target);

    // Deploy RANDOM token
    const Random = await ethers.getContractFactory("RandomToken");
    const randomDecimals = 18;
    const random = await Random.deploy(ethers.parseUnits("1000000", randomDecimals));
    console.log("Random deployed at:", random.target);

    // Deploy BondingCurve and AMM
    const BondingCurve = await ethers.getContractFactory("BondingCurve");
    const bondingCurve = await BondingCurve.deploy();

    const AMM = await ethers.getContractFactory("AMM");
    const amm = await AMM.deploy(owner.address);

    // Create AMM Pair and Add Liquidity
    await amm.createPair(usdc.target, random.target);
    await usdc.approve(amm.target, ethers.parseUnits("1000", usdcDecimals));
    await random.approve(amm.target, ethers.parseUnits("1000", randomDecimals));
    await amm.addLiquidity(
      usdc.target,
      random.target,
      ethers.parseUnits("1000", usdcDecimals),
      ethers.parseUnits("1000", randomDecimals)
    );
    console.log("AMM Liquidity added");

    // Deploy DEX
    const Dex = await ethers.getContractFactory("Mydex");
    const dex = await Dex.deploy(bondingCurve.target, amm.target);

    // Register trading pair on DEX
    await dex.RegisterTradingPair(usdc.target, random.target, 2);
    console.log("DEX Pair Registered");

    // Deposit tokens to DEX
    await usdc.approve(dex.target, ethers.parseUnits("100", usdcDecimals));
    await random.approve(dex.target, ethers.parseUnits("100", randomDecimals));
    await dex.Deposit(usdc.target, ethers.parseUnits("100", usdcDecimals));
    await dex.Deposit(random.target, ethers.parseUnits("100", randomDecimals));
    console.log("DEX Deposits completed");

    // Add Liquidity to DEX
    await usdc.approve(dex.target, ethers.parseUnits("100", usdcDecimals));
    await random.approve(dex.target, ethers.parseUnits("100", randomDecimals));
    await dex.addLiquidity(
      usdc.target,
      random.target,
      ethers.parseUnits("100", usdcDecimals),
      ethers.parseUnits("100", randomDecimals)
    );
    console.log("DEX Liquidity added");

    const buyAmount = ethers.parseUnits("10", usdcDecimals);

    // --- BUY: Bonding Curve ---
    await usdc.approve(dex.target, buyAmount);
    await dex.buy(usdc.target, random.target, buyAmount, true); // useCurve = true
    console.log("Bonding Curve Buy completed");

    // Save totalSupply to determine curve tokens
    const curvePair = await dex.getPair(usdc.target, random.target);
    const curveTokensBought = curvePair.totalSupply;

    // --- BUY: AMM ---
    await usdc.approve(dex.target, buyAmount);
    await dex.buy(usdc.target, random.target, buyAmount, false); // useCurve = false
    console.log("AMM Buy completed");

    // --- SELL: Bonding Curve ---
    const curveSellAmount = curveTokensBought / 2n;
    await random.approve(dex.target, curveSellAmount);
    await dex.sell(usdc.target, random.target, curveSellAmount, true); // useCurve = true
    console.log("Bonding Curve Sell completed");

    // --- SELL: AMM ---
    const ammSellAmount = ethers.parseUnits("5", randomDecimals);
    await random.approve(dex.target, ammSellAmount);
    await dex.sell(usdc.target, random.target, ammSellAmount, false); // useCurve = false
    console.log("AMM Sell completed");

    // --- Withdraw ---
    await dex.withdraw(usdc.target, ethers.parseUnits("10", usdcDecimals));
    await dex.withdraw(random.target, ethers.parseUnits("10", randomDecimals));
    console.log("Withdrawals completed");

    // --- Final Balances ---
    const usdcBal = await usdc.balanceOf(owner.address);
    const randBal = await random.balanceOf(owner.address);
    console.log("Final USDC Balance:", ethers.formatUnits(usdcBal, usdcDecimals));
    console.log("Final RANDOM Balance:", ethers.formatUnits(randBal, randomDecimals));

    console.log("\n--- ALL DEX TESTS COMPLETED SUCCESSFULLY ---\n");
  });
});