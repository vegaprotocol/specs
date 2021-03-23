# Block Explorer
An application that sits separate to Console - a transaction / ID explorer.

## Design Principles and MVP Features

1. Should allow a participant to find information about any transaction that has ever occurred / been processed in the network, including which block the tx is in (block height, Vega time, block hash etc)

1. Inspect any block by its hash or height.
  - which validator was lead
  - which validators participated in consensus
  - 

1. For any tx you should be able to find out what that tx did:
  - defined according to what tx type it is
  - how the state of the system changed as a result of that tx
  - (eventually) linking actions to a tx (e.g. trades to a tx)

1. Explore an ID:

Show the state of and a full tx log of the network filtered by:
  - participant ID (state = positions, margin states of positions, balances, governance actions)
  - market ID (state = market framework information, positions)
  - asset ID (state = assets details, balances, balance on margin, list of deposits/withdrawals)
  - oracle ID ()

1. Explore all the active data sources
  - for each data source

1. Explore validator / delegations / anyone who has staked
  - Validator delegations (ids of delegatees, delegated amts, longevity of validation, performance bonues)
  - Rewards paid out (performance bonuses)
  - Voting power
  - List of active validators and staked entities

1. Explore network
  - network parameters (description, show list of tx that have impacted that parameter - governance actions)
  - transactions per day over time

## Transaction Types

### Market instructions
1. Place / amend / cancel orders
1. Commit liquidity

### Governance
1. Propose
1. Vote

### Deposit / Withdrawals
1. Notification of the deposit
1. Prepare withdrawal

### Data Sourcing
1. Submit data

### Validator / Delegation
1. Stake / delegate


## Tech
1. Will need a (centralised) data store over and above the current stores / APIs
1. Open sourced and hostable
1. We will host an instance of it...e.g. vegascan.io


## Wishlist / future features

1. Incorporate bridged blockchain data
