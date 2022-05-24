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
    event BetWon(address better, uint amount,uint optionId);
    event Received(address, uint);

    constructor(address tokenAddr, int[][] memory optionValues) payable {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        tokenAddress = tokenAddr;
        for (uint i=0; i < optionValues.length; i++) {
            options.push(Option({
                optionId: getOptionId(),
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

    uint public betId;

    function getBetId() public returns (uint) {
        return betId++;
    }

    uint public optId;

    function getOptionId() public returns (uint) {
        return optId++;
    }


    function placeBet(uint betAmount, uint optionId) payable public {
        require(betAmount > 10000000000000000, "Bet should be at least 0.0001 ELL");
        require(options.length > optionId, "Option does not exist");
        uint currentBetId = getBetId();
        placedBets[msg.sender].push(Bet({
            betAmount: betAmount,
            optionId: optionId, 
            betId: currentBetId, 
            price: getLatestPrice()
        }));
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), betAmount);
        betters.push(msg.sender);
        emit BetPlaced(msg.sender, betAmount, currentBetId);
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

    function resolveBetsAll(address payable betterAddress) public onlyOwner {
        for (uint i = placedBets[betterAddress].length -1 ; i >=0; i--) {
            if ( getLatestPrice() > (120 * placedBets[betterAddress][i].price) / 100 ) {
             //betterAddress.transfer(placedBets[betterAddress][betNumberIndex].betAmount * 2);
              this.transferTo(placedBets[betterAddress][i].betAmount * 2);
              emit BetWon(betterAddress, placedBets[betterAddress][i].betAmount * 2,placedBets[betterAddress][i].optionId);
            }
        removeBets(betterAddress);
        }
    }

    function resolveBetsIndividual(address payable betterAddress,uint betNumberIndex) public onlyOwner {
        
        if ( getLatestPrice() > (120 * placedBets[betterAddress][betNumberIndex].price) / 100 ) {
            //betterAddress.transfer(placedBets[betterAddress][betNumberIndex].betAmount * 2);
            this.transferTo(placedBets[betterAddress][betNumberIndex].betAmount * 2);
            emit BetWon(betterAddress, placedBets[betterAddress][betNumberIndex].betAmount * 2,placedBets[betterAddress][betNumberIndex].optionId);
        }
        removeBets(betterAddress);
        
    }

    function removeBets(address _address) public onlyOwner {
        // Remove last element from array
        // This will decrease the array length by 1
        placedBets[_address].pop();
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

