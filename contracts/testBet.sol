// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./elliotToken.sol";

contract Betting {

    AggregatorV3Interface internal priceFeed;   
    address payable owner;
    uint256 public balance;
    address tokenAddress ;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed!");
        _;
    }

    event Bet(address sender, uint amount,uint securityId);
    event BetWon(address better, uint amount,uint securityId);

    constructor(address tokenAddr) payable{
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        tokenAddress = tokenAddr;
    }

    struct Betters {
        uint256 betAmount;
        uint securityId;
        uint uniqueTransactionId;
        int price;
        string securityName;
    }



    mapping(address => Betters[]) public mappingBetters;
    address [] public betters;
    //event Received(address, uint);
    //receive() external payable {
    //    emit Received(msg.sender, msg.value);
    //}
    fallback() payable external {
    //function() payable external {

    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }

    
    function  testBet (uint betAmount, uint id, uint txid, string memory name) payable public {
        emit Bet(msg.sender, betAmount,id);
    }


    
    function  placeBets (uint betAmount, uint id, uint txid, string memory name) payable public {
        
        //mappingBetters[msg.sender].betAmount = msg.value;
        //mappingBetters[msg.sender].securityId = id;
        //require (msg.value > 1 gwei, "bet more");
        mappingBetters[msg.sender].push(Betters({
            betAmount: betAmount,securityId : id,uniqueTransactionId : txid, price : 20,securityName: name
        }));
        betters.push(msg.sender);

        //uint256 allowance = ERC20(tokenAddress).allowance(msg.sender, address(this));
       // require(allowance >= betAmount, "Check the token allowance");
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), betAmount);
        emit Bet(msg.sender, betAmount,id);
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


    function getBet(address _address,uint index) public view returns(uint256, uint, uint, int, string memory) {
        return (mappingBetters[_address][index].betAmount, mappingBetters[_address][index].securityId, 
         mappingBetters[_address][index].uniqueTransactionId, mappingBetters[_address][index].price, 
         mappingBetters[_address][index].securityName);
    }

    function resolveBetsAll(address payable betterAddress) public onlyOwner {
        for (uint i = mappingBetters[betterAddress].length -1 ; i >=0; i--) {
            if ( getLatestPrice() > (120 * mappingBetters[betterAddress][i].price) / 100 ) {
             //betterAddress.transfer(mappingBetters[betterAddress][betNumberIndex].betAmount * 2);
              this.transferTo(mappingBetters[betterAddress][i].betAmount * 2);
              emit BetWon(betterAddress, mappingBetters[betterAddress][i].betAmount * 2,mappingBetters[betterAddress][i].securityId);
            }
        removeBets(betterAddress);
        }
    }

    function resolveBetsIndividual(address payable betterAddress,uint betNumberIndex) public onlyOwner {
        
        if ( getLatestPrice() > (120 * mappingBetters[betterAddress][betNumberIndex].price) / 100 ) {
            //betterAddress.transfer(mappingBetters[betterAddress][betNumberIndex].betAmount * 2);
            this.transferTo(mappingBetters[betterAddress][betNumberIndex].betAmount * 2);
            emit BetWon(betterAddress, mappingBetters[betterAddress][betNumberIndex].betAmount * 2,mappingBetters[betterAddress][betNumberIndex].securityId);
        }
        removeBets(betterAddress);
        
    }

    function removeBets(address _address) public onlyOwner {
        // Remove last element from array
        // This will decrease the array length by 1
        mappingBetters[_address].pop();
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

