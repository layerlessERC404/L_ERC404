// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract 404CommunityIncentive  is Ownable {

    event withdrawn(address from, address to,uint256 amount);
  
    constructor () Ownable(msg.sender) {}

    function withDrawTokens(IERC20 token,address receiver, uint256 amount ) external onlyOwner {
        token.transfer(receiver,amount);
        emit withdrawn(msg.sender,receiver,amount);
    }
}