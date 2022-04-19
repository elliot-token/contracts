// SPDX-License-Identifier: MIT
pragma solidity <= 0.9.11;
contract Betting {
    
    address payable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed!");
        _;
    }

    constructor() payable public {
        owner = msg.sender;
    }

    struct Betters {
        uint256 betAmount;
        uint securityId;
    }

    mapping(address => Betters) public mappingBetters;

    //event Received(address, uint);
    //receive() external payable {
    //    emit Received(msg.sender, msg.value);
    //}
    //fallback() payable external {
    function() payable external {

    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }


    
    function  placeBets (uint id) payable public {
        
        mappingBetters[msg.sender].betAmount = msg.value;
        mappingBetters[msg.sender].securityId = id;
        
    }
    
    function getBet(address _address) public view returns(uint256, uint) {
        return (mappingBetters[_address].betAmount, mappingBetters[_address].securityId);
    }
    
}

