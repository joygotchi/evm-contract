// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RaiGotchiTreasury is Ownable {
    IToken public token;

    constructor(address _token) {
        token = IToken(_token);
    }

    function setTokenAddress(address _token) public onlyOwner {
        token = IToken(_token);
    }

    function withdrawTokenToOwner() public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function sendTokenToAddress(address to, uint256 amount) public onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= amount, "Not enough balance");
        token.transfer(to, amount);
    }
}
