// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AMM is Ownable {
    struct Pair {
        ERC20 token0;
        ERC20 token1;
        uint256 reserve0;
        uint256 reserve1;
    }

    mapping(bytes32 => Pair) public pairs;

    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed provider, address token0, address token1, uint256 amount0, uint256 amount1);
    event LiquidityRemoved(address indexed provider, address token0, address token1, uint256 amount0, uint256 amount1);
    event Swapped(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function getPairKey(address token0, address token1) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token1));
    }

    function createPair(address token0, address token1) external onlyOwner {
        require(token0 != token1, "Tokens must be different");
        bytes32 key = getPairKey(token0, token1);
        require(address(pairs[key].token0) == address(0), "Pair exists");

        pairs[key] = Pair({
            token0: ERC20(token0),
            token1: ERC20(token1),
            reserve0: 0,
            reserve1: 0
        });
    }

    function addLiquidity(address token0, address token1, uint256 amount0, uint256 amount1) external onlyOwner {
        require(amount0 > 0 && amount1 > 0, "Invalid amounts");
        bytes32 key = getPairKey(token0, token1);
        Pair storage pair = pairs[key];
        require(address(pair.token0) != address(0), "Pair not found");

        pair.token0.transferFrom(msg.sender, address(this), amount0);
        pair.token1.transferFrom(msg.sender, address(this), amount1);

        pair.reserve0 += amount0;
        pair.reserve1 += amount1;

        emit LiquidityAdded(msg.sender, token0, token1, amount0, amount1);
    }

    function removeLiquidity(address token0, address token1, uint256 amount0, uint256 amount1) external onlyOwner {
        bytes32 key = getPairKey(token0, token1);
        Pair storage pair = pairs[key];
        require(address(pair.token0) != address(0), "Pair not found");
        require(amount0 <= pair.reserve0 && amount1 <= pair.reserve1, "Insufficient reserves");

        pair.reserve0 -= amount0;
        pair.reserve1 -= amount1;

        pair.token0.transfer(msg.sender, amount0);
        pair.token1.transfer(msg.sender, amount1);

        emit LiquidityRemoved(msg.sender, token0, token1, amount0, amount1);
    }

    function getAmountOut(uint256 inputAmount, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(inputAmount > 0, "Input must be > 0");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        uint256 inputAmountWithFee = inputAmount * FEE_NUMERATOR;
        uint256 numerator = inputAmountWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DENOMINATOR) + inputAmountWithFee;
        return numerator / denominator;
    }

    function swap(address tokenIn, address tokenOut, uint256 inputAmount) external returns (uint256 outputAmount) {
        require(inputAmount > 0, "Input must be > 0");

        bytes32 key = getPairKey(tokenIn, tokenOut);
        Pair storage pair = pairs[key];

        require(
            address(pair.token0) == tokenIn || address(pair.token1) == tokenIn,
            "Token not part of pair"
        );

        ERC20 input = ERC20(tokenIn);
        ERC20 output = ERC20(tokenOut);

        uint256 reserveIn = tokenIn == address(pair.token0) ? pair.reserve0 : pair.reserve1;
        uint256 reserveOut = tokenIn == address(pair.token0) ? pair.reserve1 : pair.reserve0;

        input.transferFrom(msg.sender, address(this), inputAmount);

        uint256 inputWithFee = inputAmount * FEE_NUMERATOR;
        uint256 numerator = inputWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DENOMINATOR) + inputWithFee;
        outputAmount = numerator / denominator;

        require(outputAmount > 0, "Output too low");
        output.transfer(msg.sender, outputAmount);

        if (tokenIn == address(pair.token0)) {
            pair.reserve0 += inputAmount;
            pair.reserve1 -= outputAmount;
        } else {
            pair.reserve1 += inputAmount;
            pair.reserve0 -= outputAmount;
        }

        emit Swapped(msg.sender, tokenIn, inputAmount, tokenOut, outputAmount);
    }
}
