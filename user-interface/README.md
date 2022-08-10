# User interface acceptance criteria
This folder contain descriptions of things that users do when interacting with a Vega chain. The things they need and some information about why they are doing them. These can be referenced in testing and used as input for building new interfaces (e.g. User requirements).

These have been listed with the most "upstream" being first.

Each file contains blocks that relate to a user task. What the user is trying to do, a bullet for each thing the need, then why they are doing it...

> When doing a thing, I...
> 
>  - **must** be able to see some particular number [0000-CODE-000]
> 
> ...so I can decide if I want to continue.

Each bullet is worded so that it contains a **must**, **should**, **could**, or **would like to**. This gives app developers some indication of the priority of user needs. The current ranking of these is a hypothesis that will improve as we do more user research and get more feedback. At the end of each bullet is a code that can be referenced in tests etc.

## 0 - Wallets and signing transactions
- [Get and use a Vega wallet](0001-WALL-wallet.md)
- [Connect Vega wallet + select keys](0002-WCON-connect_vega_wallet.md)
- [Submit Vega transaction](0003-WTXN-submit_vega_transaction.md) 
- [Connect Ethereum wallet](0004-EWAL-connect_ethereum_wallet.md) `Incomplete`
- [Submit Ethereum transaction](0005-ETXN-submit_ethereum_transaction.md) `Incomplete`

  
## 1 - Staking and Governance
- [Associate governance token a Vega key](1000-ASSO-associate.md)
- [View and Redeem vested tokens](1001-VEST-vesting.md)
- [Staking validators](1002-STKE-staking.md)
- [Review staking income](1003-INCO-income.md)
- [Vote on changes](1004-VOTE-vote.md)
- [Propose changes](1005-PROP-propose.md)
  - [Propose new Market](./1006-PMARK-propose_new_market.md)
  - [Propose change(s) to market](./1007-PMAC-propose_market_change.md)
  - [Propose new asset](1008-PASN-propose_new_asset.md)
  - [Propose change(s) to asset](1009-PASC-propose_asset_change.md)
  - [Propose change to network parameter(s)](1010-PNEC-propose_network.md)
  - [Propose something "Freeform"](1011-PFRO-propose_freeform.md)

## 2 - Treasury 
- Understand treasury rewards 

## 3 - Bridges and Transfers
- [Deposit](3000-DEPO-desposit.md) `Incomplete`
- [Withdraw](3001-WITH-withdraw.md) `Incomplete`
- Transfer

## 4 - Liquidity provision
- Understand return of liquidity provision
- Provide liquidity

## 5 - Markets and analysis
- [Find markets](5000-MARK-find_markets.md) `Incomplete`
- View Market details
- Analyze Order book
- Analyze price history
- Analyze trade history

## 6 - Collateral, Orders, Positions and fills 
- [View Collateral / accounts](6000-COLL-collateral.md) `Incomplete`
- [Submit an order](6001-SORD-submit_orders.md) 
- [Manage my orders](6002-MORD-manage_orders.md) `Incomplete`
- [View my positions](6003-POSI-positions.md) `Incomplete`
- [View my trades/fills](6003-FILL-fills.md) `Incomplete`
- [//]: # (Get alerts (price, fills etc))

## Appendixes 

- [Display display rules](7001-DATA-data_display.md)

# Events
There are things that happen to users too
- Market lifecycle
- liquidation
- loss socialization 
- Spam protection
- Settlement
... AC for these are in context of the user journey above 👆