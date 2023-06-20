// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint amount) external;
}

contract FlashLoan is ReentrancyGuard{
    using SafeMath for uint;

    Token public token;
    uint public poolBalance;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function depositTokens(uint _amount) external nonReentrant{
        require(_amount > 0, "Must deposit atleast one token");
        token.transferFrom(msg.sender, address(this), _amount);
        poolBalance = poolBalance.add(_amount);
    }

    function flashLoan(uint _borrowAmount) external  nonReentrant{
        require(_borrowAmount > 0, "Must borrow at least 1 token");

        uint balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _borrowAmount, "Not enough tokens in the pool");

        // Ensured by the protocol via the 'depositTokens' function
        assert(poolBalance == balanceBefore);

        // Send tokens to receiver
        token.transfer(msg.sender, _borrowAmount);

        // Use loan, Get paid back
        IReceiver(msg.sender).receiveTokens(address(token), _borrowAmount);

        // Ensure loan paid back
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
}