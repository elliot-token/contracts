// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Betting {
    
    AggregatorV3Interface internal priceFeed;      
    address payable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed!");
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    struct Betters {
        uint256 betAmount;
        uint securityId;
        string securityName;
    }



    mapping(address => Betters[]) public mappingBetters;
    address [] public betters;
    //event Received(address, uint);
    //receive() external payable {
    //    emit Received(msg.sender, msg.value);
    //}
    //fallback() payable external {
    /* function() payable external {
    }*/

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }


    
    function  placeBets (uint id, string memory name) payable public {
        
        //mappingBetters[msg.sender].betAmount = msg.value;
        //mappingBetters[msg.sender].securityId = id;
        
        mappingBetters[msg.sender].push(Betters({
            betAmount: msg.value,securityId : id, securityName: name
        }));
        betters.push(msg.sender);
    }
    
    function getBet(address _address,uint index) public view returns(uint256, uint, string memory) {
        return (mappingBetters[_address][index].betAmount, mappingBetters[_address][index].securityId,  mappingBetters[_address][index].securityName);
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
    
}