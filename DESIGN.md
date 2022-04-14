# Smart contract Design

## Events 

- `event NewBet` : emitted when a user makes a bet on the security

## Data Structure

- `struct Security`:
  - `uint id`: unique id of the bet
  - `bytes32 name`: name of the security (ETH, GOLD) 

- `struct Bet`:
  - `uint id`: unique id of the bet
  - `address address`: wallet address of the user
  - `fixed betAmount`: bet amount (seems like fixed points are not fully supported yet ? https://docs.soliditylang.org/en/v0.8.13/types.html#fixed-point-numbers)
  - `uint256 createdAt`: creation time stored in Unix time.
  - `uint securityId`: id of the security to bet on
  - `fixed betPrice`: price of the security at the end of bet time (comparison at end of period must be exact ?)
  
- Bet[]: array containing all bets
- Security[]: array containing all teams
- address payable conOwner: address of the owner of the contract
- uint totalBetMoney: total bets placed
- mapping numBetsAddress: links address to a bet to ensure that each user only places one bet until a winner is chosen
  
  ## Functions
  
- createSecurity(_name): can be called by owner to create a new team that bets can be placed on
- placeBet(_name, _teamId): can be called by a user with msg.value to place a bet on a certain team (elliot token transfers to contract)
- resolveBets(_teamId): can be called by owner to resolve bets and distribute ELI (elliot tokens) to winners accordingly
