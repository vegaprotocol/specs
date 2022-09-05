# User interface acceptance criteria
This folder contain descriptions of things that users do when interacting with Vega. The information they need and why they are doing them. These can be referenced in testing and used as input for building new interfaces.

The acceptance criteria are organized into files, with each file representing a high level user task. These have been listed with the most "upstream" being first, and grouped into similar tasks.

Each file contains blocks that relate to a low level user task. The block states what the user is trying to do or the context they are in, has a bullet for each thing the need, then states why they are doing it...

> When doing a thing, I...
> 
>  - **must** be able to see some particular number [0000-CODE-000]
> 
> ...so I can decide if I want to continue.

Each bullet is worded so that it contains a **must**, **should**, **could**, or **would like to**. This gives app developers some indication of the priority of user needs. At the end of each bullet is a code that can be referenced in tests etc.

These acceptance criteria are not final or intended to be "the truth" but a useful tool, they will be improved over time as more people feedback on using Vega.

## 0. Wallets and signing transactions
- [Get and use a Vega wallet](0001-WALL-wallet.md)
- [Connect Vega wallet to a Dapp & select keys](0002-WCON-connect_vega_wallet.md)
- [Submit Vega transaction](0003-WTXN-submit_vega_transaction.md) 
- [Connect Ethereum wallet to a Dapp](0004-EWAL-connect_ethereum_wallet.md))
- [Submit Ethereum transaction](0005-ETXN-submit_ethereum_transaction.md)

## 1. Staking and Governance
- Associate governance token with a Vega key
- View and redeem vested tokens
- Staking validators
- Review staking income
- Vote on changes
- Propose changes
  - Propose new Market
  - Propose change(s) to market
  - Propose new asset
  - Propose change(s) to asset
  - Propose change to network parameter(s)
  - Propose something "Freeform"

## 2. Treasury 
- Understand treasury rewards

## 3. Bridges and Transfers
- Deposit
- [Withdraw](3001-WITH-withdraw.md)
- Transfer

## 4. Liquidity provision
- Understand return of liquidity provision
- Provide liquidity

## 5. Markets and analysis
- Find markets 
- View market specification
- Analyze Order book
- Analyze price history
- Analyze trade history

## 6. Collateral, Orders, Positions and Fills 
- View my collateral / accounts
- [Submit an order](6001-SORD-submit_orders.md) 
- Manage my orders
- View my positions
- View my trades/fills

## Appendixes 

- [Display display rules](7001-DATA-data_display.md)

