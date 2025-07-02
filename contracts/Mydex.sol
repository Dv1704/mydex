// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IBondingCurve {
    function calculateBuyReturn(
        uint256 totalSupply,
        uint256 depositAmount,
        uint32 slope
    ) external pure returns (uint256);
}

interface IAMM {
    function getAmountOut(
        uint256 inputAmount,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256);
}

contract Mydex is Ownable {
    struct Pair {
        ERC20 base;
        ERC20 quote;
        uint32 slope;
        uint256 totalSupply;
        uint256 reserveBase;
        uint256 reserveQuote;
    }

    mapping(bytes32 => Pair) public tradingPairs;
    mapping(address => mapping(address => uint256)) public poolBalance;

    IBondingCurve public bondingCurve;
    IAMM public amm;

    event PairRegistered(address base, address quote);
    event Bought(address buyer, address base, address quote, uint256 input, uint256 output);
    event Sold(address seller, address quote, address base, uint256 input, uint256 output);
    event LiquidityAdded(address provider, address base, address quote, uint256 amountBase, uint256 amountQuote);
    event LiquidityRemoved(address provider, address base, address quote, uint256 amountBase, uint256 amountQuote);

    constructor(address _bondingCurve, address _amm) Ownable(msg.sender) {
        bondingCurve = IBondingCurve(_bondingCurve);
        amm = IAMM(_amm);
    }

    function _getPairKey(address base, address quote) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(base, quote));
    }

    function RegisterTradingPair(ERC20 base, ERC20 quote, uint32 slope) public onlyOwner {
        require(slope > 0, "Slope must be greater than 0");
        bytes32 pairKey = _getPairKey(address(base), address(quote));
        require(address(tradingPairs[pairKey].base) == address(0), "Pair exists");

        tradingPairs[pairKey] = Pair({
            base: base,
            quote: quote,
            slope: slope,
            totalSupply: 0,
            reserveBase: 0,
            reserveQuote: 0
        });

        emit PairRegistered(address(base), address(quote));
    }

    function Deposit(ERC20 token, uint256 amount) public {
        require(amount > 0, "Amount must be > 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        poolBalance[msg.sender][address(token)] += amount;
    }

    function withdraw(ERC20 token, uint256 amount) public {
        require(poolBalance[msg.sender][address(token)] >= amount, "Insufficient balance");
        poolBalance[msg.sender][address(token)] -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    function addLiquidity(address base, address quote, uint256 amountBase, uint256 amountQuote) public onlyOwner {
        bytes32 pairKey = _getPairKey(base, quote);
        Pair storage pair = tradingPairs[pairKey];
        require(address(pair.base) != address(0), "Pair not found");

        require(pair.base.transferFrom(msg.sender, address(this), amountBase), "Base transfer failed");
        require(pair.quote.transferFrom(msg.sender, address(this), amountQuote), "Quote transfer failed");

        pair.reserveBase += amountBase;
        pair.reserveQuote += amountQuote;

        emit LiquidityAdded(msg.sender, base, quote, amountBase, amountQuote);
    }

    function removeLiquidity(address base, address quote, uint256 amountBase, uint256 amountQuote) public onlyOwner {
        bytes32 pairKey = _getPairKey(base, quote);
        Pair storage pair = tradingPairs[pairKey];
        require(pair.reserveBase >= amountBase && pair.reserveQuote >= amountQuote, "Insufficient reserves");

        pair.reserveBase -= amountBase;
        pair.reserveQuote -= amountQuote;

        require(pair.base.transfer(msg.sender, amountBase), "Base transfer failed");
        require(pair.quote.transfer(msg.sender, amountQuote), "Quote transfer failed");

        emit LiquidityRemoved(msg.sender, base, quote, amountBase, amountQuote);
    }

function buy(address base, address quote, uint256 amountIn, bool useCurve) external {
    require(amountIn > 0, "Input must be > 0"); 

    bytes32 pairKey = _getPairKey(base, quote);
    Pair storage pair = tradingPairs[pairKey];
    require(address(pair.base) != address(0), "Invalid pair");

    require(pair.base.transferFrom(msg.sender, address(this), amountIn), "Transfer failed");

    uint256 amountOut;
    if (useCurve) {
        amountOut = bondingCurve.calculateBuyReturn(pair.totalSupply, amountIn, pair.slope);
        pair.totalSupply += amountOut;
    } else {
        amountOut = amm.getAmountOut(amountIn, pair.reserveBase, pair.reserveQuote);
        pair.reserveBase += amountIn;
        pair.reserveQuote -= amountOut;
    }

    require(pair.quote.transfer(msg.sender, amountOut), "Transfer failed");

    emit Bought(msg.sender, base, quote, amountIn, amountOut);
}

    function sell(address base, address quote, uint256 amountIn, bool useCurve) public {
        require(amountIn > 0, "Input must be > 0");
        bytes32 pairKey = _getPairKey(base, quote);
        Pair storage pair = tradingPairs[pairKey];
        require(address(pair.base) != address(0), "Invalid pair");

        require(pair.quote.transferFrom(msg.sender, address(this), amountIn), "Transfer failed");

        uint256 amountOut;
        if (useCurve) {
            require(pair.totalSupply >= amountIn, "Insufficient total supply");
            amountOut = bondingCurve.calculateBuyReturn(pair.totalSupply - amountIn, amountIn, pair.slope);
            pair.totalSupply -= amountIn;
        } else {
            amountOut = amm.getAmountOut(amountIn, pair.reserveQuote, pair.reserveBase);
            pair.reserveQuote += amountIn;
            pair.reserveBase -= amountOut;
        }

        require(pair.base.transfer(msg.sender, amountOut), "Transfer failed");

        emit Sold(msg.sender, quote, base, amountIn, amountOut);
    }

    function getPair(address base, address quote) public view returns (Pair memory) {
        return tradingPairs[_getPairKey(base, quote)];
    }
}
