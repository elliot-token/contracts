// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./elliotToken.sol";
import "hardhat/console.sol";

contract BetContract {
    AggregatorV3Interface internal priceFeed;   
    address payable owner;
    uint256 public balance;
    address public tokenAddress;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed!");
        _;
    }

    event BetPlaced(address sender, uint amount,uint optionId);
    event BetResolved(address better, uint betAmount, uint receivedAmount, uint optionId);
    event Received(address, uint);

    constructor(address tokenAddr, int[][] memory optionValues) payable {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        tokenAddress = tokenAddr;
        for (uint i=0; i < optionValues.length; i++) {
            options.push(Option({
                optionId: getNextOptionId(),
                min: optionValues[i][0],
                max: optionValues[i][1],
                odd: optionValues[i][2]
            }));
        }
    }

    struct Option {
        uint optionId;
        // included minimum
        int min;
        // excluded maximum
        int max;
        // 2 digits, odd = 121 -> 1.21% gain
        int odd;
    }
    Option[] public options;


    struct Bet {
        uint256 betAmount;
        uint optionId;
        uint betId;
        int price;
        bool resolved;
    }

    mapping(address => Bet[]) public placedBets;
    address [] public betters;

    fallback() payable external {
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }

    uint public nextBetId;

    function getNextBetId() public returns (uint) {
        return nextBetId++;
    }

    uint public nextOptionId;

    function getNextOptionId() public returns (uint) {
        return nextOptionId++;
    }


    function placeBet(uint betAmount, uint optionId) payable public {
        require(betAmount > 10000000000000000, "Bet should be at least 0.0001 ELL");
        require(options.length > optionId, "Option does not exist");
        uint betId = getNextBetId();
        placedBets[msg.sender].push(Bet({
            betAmount: betAmount,
            optionId: optionId, 
            betId: betId, 
            price: getLatestPrice(),
            resolved: false
        }));
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), betAmount);
        betters.push(msg.sender);
        emit BetPlaced(msg.sender, betAmount, betId);
    }

    function withdraw(uint amount, address payable destAddress) public {
        require (amount <= balance,"insufficient funds");
        destAddress.transfer(amount);
        balance -= amount;
    }
    
    function transferFrom(address sender,uint amount) public {
        // Then calling this function from remix
        ERC20(tokenAddress).transferFrom(sender, address(this), amount);
        //ERC20(tokenAddress).transferFrom(msg.sender, tokenAddress, amount);
    }

    function transferTo(uint amount) public {
        ERC20(tokenAddress).transfer(msg.sender,amount);
    }


    function getBet(address _address,uint index) public view returns(uint256, uint256, int256) {
        return (
            placedBets[_address][index].betAmount,
            placedBets[_address][index].betId, 
            placedBets[_address][index].price
        );
    }
    
    function resolveBet(uint betId) public {
        require(placedBets[msg.sender].length > betId, "Corresponding bet not found");


        Bet memory correspondingBet = placedBets[msg.sender][betId];

        if (getLatestPrice() > (120 * correspondingBet.price) / 100 ) {
            //betterAddress.transfer(placedBets[betterAddress][betNumberIndex].betAmount * 2);
            this.transferTo(correspondingBet.betAmount * 2);
            emit BetResolved(
                msg.sender, 
                correspondingBet.betAmount,
                correspondingBet.betAmount * 2, 
                correspondingBet.optionId
            );
        } else {
            emit BetResolved(
                msg.sender, 
                correspondingBet.betAmount,
                0,
                correspondingBet.optionId
            );

        }
        placedBets[msg.sender][betId].resolved = true;


    }


    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709562301
     *    
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(uint80 roundId) public view returns (int256) {
        (
            uint80 id, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }
}

