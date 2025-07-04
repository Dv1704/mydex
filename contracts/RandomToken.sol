// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract RandomToken is ERC20{
    constructor(uint256 initialSuplpy) ERC20("RandomTokn","RAND"){
        _mint(msg.sender, initialSuplpy);
    }
}