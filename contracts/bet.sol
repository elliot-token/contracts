// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./ownable.sol";
import "./atm.sol";
import "./console.sol";

contract bet is ATM, Ownable {

    event NewBet(
        address addy, 
        uint amount, 
        uint securityId
    );

    struct Security {
        uint id;
        string name;
    }

    struct Bet {
        uint id;
        address addy;
        bytes32 betAmount;
        uint256 createdAt;
        uint securityId;
        bytes32 betPrice;
    }


    Bet[] public bets;
    Security[] public security;
    
    address payable conOwner;
    uint public totalBetMoney = 0;

    mapping (address => uint) public numBetsAddress;


    constructor() payable {
        conOwner = payable(msg.sender);
    }
}