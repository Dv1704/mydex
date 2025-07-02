// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Usdc is ERC20{
    constructor(uint256 intialSuupply) ERC20("USDC","USDC"){
        _mint(msg.sender, intialSuupply);
    }
}