Here is your full `README.md` in **pure Markdown format**, fully cleaned and ready to paste into your GitHub repo. This version is GitHub-friendly, properly structured, and contains no embedded backticks or redundant markers—just the Markdown content you need:

---

# 🦄 MyDex - Decentralized Exchange

![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-blue.svg)
A hybrid Decentralized Exchange (DEX) combining **Bonding Curve** mechanics with **Automated Market Maker (AMM)** for optimal price discovery, liquidity, and usability.

---

## 📌 Table of Contents

* [✨ Features](#-features)
* [🏗️ Architecture](#-architecture)
* [🧠 Smart Contracts](#-smart-contracts)
* [🚀 Getting Started](#-getting-started)

  * [📦 Prerequisites](#-prerequisites)
  * [📥 Installation](#-installation)
  * [🧪 Running Tests](#-running-tests)
* [⚙️ How it Works](#-how-it-works)

  * [📈 Bonding Curve](#-bonding-curve)
  * [🔁 Automated Market Maker (AMM)](#-automated-market-maker-amm)
* [📍 Deployed Contracts (Testnet/Local)](#-deployed-contracts-testnetlocal)
* [✅ Testing & Quality Assurance](#-testing--quality-assurance)
* [🚧 Future Enhancements](#-future-enhancements)
* [🤝 Contributing](#-contributing)
* [📜 License](#-license)

---

## ✨ Features

* 🧬 **Hybrid Liquidity Model**: Combines Bonding Curve & AMM
* 🔁 **Token Swapping**: Buy/Sell tokens via smart routing
* 💧 **Liquidity Provision**: Add liquidity to AMM pools
* 🧾 **Withdrawals**: Safe and verified token withdrawal logic
* 🛡️ **Robust Error Handling**: Guards against zero-input, over-withdrawals, slippage

---

## 🏗️ Architecture

MyDex consists of multiple modular smart contracts:

| Contract           | Purpose                                                        |
| ------------------ | -------------------------------------------------------------- |
| `DEX.sol`          | Core contract managing trades, deposits, withdrawals           |
| `BondingCurve.sol` | Handles buy/sell logic based on supply curves                  |
| `AMM.sol`          | Manages constant-product liquidity pools (x \* y = k)          |
| `UsdcToken.sol`    | Mock stablecoin for testing (8 decimals)                       |
| `RandomTokn.sol`   | Custom token representing volatile or new assets (18 decimals) |
| `Lock.sol`         | Time-locked funds for testing withdrawal conditions            |

---

## 🧠 Smart Contracts

* `UsdcToken.sol`: Example ERC-20 stablecoin
* `RandomTokn.sol`: ERC-20 token for bonding curve sales
* `DEX.sol`: Routes trades via BondingCurve or AMM
* `BondingCurve.sol`: Implements price = slope × supply
* `AMM.sol`: Constant-product formula logic (Uniswap-style)
* `Lock.sol`: Time-lock and withdrawal validations

---

## 🚀 Getting Started

### 📦 Prerequisites

* Node.js `>= 18`
* npm
* [Hardhat](https://hardhat.org)

### 📥 Installation

```bash
git clone https://github.com/your-username/mydex.git
cd mydex
npm install
```

### 🧪 Running Tests

```bash
npm test
```

You should see something like:

```
--- DEX FULL TEST ---
Owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
USDC deployed at: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
Random deployed at: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
AMM Liquidity added
DEX Pair Registered
DEX Deposits completed
DEX Liquidity added
Bonding Curve Buy completed
AMM Buy completed
Bonding Curve Sell completed
AMM Sell completed
Withdrawals completed

Final USDC Balance: 998795.71680921  
Final RANDOM Balance: 998814.066108939301491315  

✔ ALL TESTS PASSED!
```

---

## ⚙️ How it Works

### 📈 Bonding Curve

A **bonding curve** dynamically calculates price based on supply using:

```
price = slope × totalSupply
```

* Ideal for **initial token distribution**
* Always available liquidity
* Predictable pricing that increases with demand

### 🔁 Automated Market Maker (AMM)

* Uses **Uniswap-style x\*y=k** model
* Trades occur between pooled pairs
* Liquidity providers earn fees
* Price adjusts based on pool ratios

🧠 *MyDex chooses either Bonding Curve or AMM depending on liquidity depth and token type.*

---

## 📍 Deployed Contracts (Testnet/Local)

| Contract      | Address (example)                            |
| ------------- | -------------------------------------------- |
| USDC Token    | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` |
| Random Token  | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` |
| Owner Address | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |

> ⚠️ These are **local Hardhat** addresses. Do not use on public networks without deployment scripts.

---

## ✅ Testing & Quality Assurance

✅ **Full End-to-End Testing**
✅ **Buy/Sell Logic for Both Modes**
✅ **Liquidity Operations**
✅ **Event Emissions (Bought, Sold)**
✅ **Error Cases:**

* Pair not found
* Zero input
* Over-withdrawals
* Invalid reserves
* Re-registration of pair

**Test stack:**

* [Hardhat](https://hardhat.org)
* [Chai](https://www.chaijs.com/)
* [Ethers.js](https://docs.ethers.org/)

---

## 🚧 Future Enhancements

* ⛽ **Gas Optimization**
* ⚡ **Flash Loans / Flash Swaps**
* 🧑‍⚖️ **Governance Module**
* 🔍 **Routing Optimizer**
* 🌐 **Web Frontend (React + Wagmi)**
* 🔐 **Security Audits**

---

## 🤝 Contributing

Pull requests and forks are welcome! If you have suggestions, open an issue or a PR.

```bash
git checkout -b feature/my-new-feature
git commit -m "Add amazing feature"
git push origin feature/my-new-feature
```

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

### ⭐ If this helped you, star the repo!

```bash
⭐ github.com/dv1704/mydex
```

---
