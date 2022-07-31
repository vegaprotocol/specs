# User interface acceptance criteria
This folder contain descriptions of thing that users do when interacting with a Vega chain. These can be referenced in testing and used as input for building new interfaces.

These have been listed with the most "upstream" being first.

0
- [Get and use a **Vega wallet**](0001-WALL-wallet.md)
- [Connect Vega wallet + select keys](0002-WCON-connect_vega_wallet.md) `Incomplete`
- [Submit Vega transaction](0003-WTXN-submit_vega_transaction.md) `Incomplete`
- [Connect Ethereum wallet](0004-EWAL-connect_ethereum_wallet.md) `Incomplete`
- [Submit Ethereum transaction](0005-ETXN-submit_ethereum_transaction.md) `Incomplete`

  
1
- [Associate governance token a Vega key](1000-ASSO-associate.md)
- [View and Redeem vested tokens](1001-VEST-vesting.md)
- [Staking validators](1002-STAK-staking.md)
- [Review staking income](1003-INCO-income.md)
- [Vote on changes](1004-VOTE-vote.md)
- [Propose changes](1005-PROP-propose.md)
  - [Propose new Market](./1006-PMARK-propose_new_market.md)
  - [Propose change(s) to market](./1007-PMAC-propose_market_change.md)
  - [Propose new asset](1008-PASN-propose_new_asset.md)
  - [Propose change(s) to asset](1009-PASC-propose_asset_change.md)
  - [Propose change to network parameter(s)](1010-PNEC-propose_network.md)
  - [Propose something "Freeform"](1011-PFRO-propose_freeform.md)

2
- Understand treasury rewards 

3
- [Deposit](3000-DEPO-desposit.md) `Incomplete`
- [Withdraw](3001-WITH-withdraw.md) `Incomplete`
- Transfer

4
- Understand return of liquidity provision
- Provide liquidity

5
- [Find markets](5000-MARK-find_markets.md) `Incomplete`
- View Market details
- Analyze Order book
- Analyze price history
- Analyze trade history

6
- [View Collateral / accounts](6000-COLL-collateral.md) `Incomplete`
- [Submit an order](6001-SORD-submit_orders.md) (Market or Limit) `Incomplete`
- [Manage my orders](6002-MORD-manage_orders.md) `Incomplete`
- [View my positions](6003-POSI-positions.md) `Incomplete`
- [View my trades/fills](6003-FILL-fills.md) `Incomplete`
- [//]: # (Get alerts (price, fills etc))

7
- Analyze chain state and activity
- Action transaction on Ethereum
- Action transaction on Vega

# Events
There are things that happen to users too
- Market lifecycle
- liquidation
- loss socialization 
- Spam protection
- Settlement
... AC for these are in context of the user journey above 👆