// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "./elliotToken.sol";

contract BetContract {
    AggregatorV3Interface internal priceFeed;
    ERC20 internal tokenContract;
    address payable owner;
    uint256 public balance;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed!");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }



    event BetPlaced(address sender, uint amount,uint optionId);
    event BetResolved(address better, uint betAmount, uint receivedAmount, uint optionId);
    event Received(address, uint);

    constructor(
        address _priceFeed,
        address tokenAddr, 
        int[][] memory optionValues
    ) payable {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = payable(msg.sender);
        tokenContract = ERC20(tokenAddr);
        for (uint i=0; i < optionValues.length; i++) {
            options.push(Option({
                optionId: getNextOptionId(),
                min: optionValues[i][0],
                max: optionValues[i][1],
                odd: uint(optionValues[i][2]) 
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
        uint odd;
    }
    Option[] public options;


    struct Bet {
        uint256 betAmount;
        uint optionId;
        uint betId;
        int price;
        bool resolved;
        uint odd;
        uint timestamp;

    }

    mapping(address => Bet[]) public bets;
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


        bets[msg.sender].push(Bet({
            betAmount: betAmount,
            optionId: optionId, 
            betId: betId, 
            price: getLatestPrice(),
            resolved: false,
            odd: options[optionId].odd,
            timestamp: block.timestamp
        }));
        tokenContract.transferFrom(msg.sender, address(this), betAmount);
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
        tokenContract.transferFrom(sender, address(this), amount);
        //tokenContract.transferFrom(msg.sender, tokenAddress, amount);
    }

    function transferTo(uint amount) public {
        tokenContract.transfer(msg.sender,amount);
    }


    function getBet(address _address,uint index) public view returns(uint256, uint256, int256) {
        return (
            bets[_address][index].betAmount,
            bets[_address][index].betId, 
            bets[_address][index].price
        );
    }
    
    function resolveBet(uint betId, uint80 roundId) public {
        require(bets[msg.sender].length > betId, "Corresponding bet not found");        

        Bet memory correspondingBet = bets[msg.sender][betId];
        Option memory correspondingOption = options[correspondingBet.optionId];

        require(!correspondingBet.resolved, "Bet already resolved");
        int price = getHistoricalPrice(roundId);

        if (
            correspondingBet.price * (100 + correspondingOption.max) / 100 > price
            && correspondingBet.price * (100 + correspondingOption.min) / 100 <= price
        ) {
            tokenContract.transfer(msg.sender, correspondingBet.betAmount * correspondingBet.odd / 100);
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
        bets[msg.sender][betId].resolved = true;


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

    function getHistoricalPrice(uint80 roundId) private view returns (int256) {
        (
            , 
            int price,
            ,
            uint timeStamp,
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }
}

