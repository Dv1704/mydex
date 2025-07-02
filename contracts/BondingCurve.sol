// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract BondingCurve {
    function calculateBuyReturn(
        uint256 totalSupply,
        uint256 depositAmount,
        uint32 slope
    ) public pure returns (uint256) {
        uint256 price = calculatePrice(totalSupply, slope);
        require(price > 0, "Invalid price calculation"); // Prevent divide by zero
        return depositAmount / price;
    }

    function calculatePrice(uint256 totalSupply, uint32 slope) public pure returns (uint256) {
        if (slope == 0 || totalSupply == 0) return 1; // set base price to 1
        uint256 temp = totalSupply * totalSupply;
        return slope * temp;
    }
}
