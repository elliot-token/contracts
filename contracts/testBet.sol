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
        string securityName;
    }



    mapping(address => Betters[]) public mappingBetters;
    address [] public betters;
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
    
}