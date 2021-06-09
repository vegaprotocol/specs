# Staking Bridge

The staking bridge is roughly analagous to [the Ethereum bridge](../protocol/0031-ethereum-bridge-spec.md), but differs in that it deals with tokens that are locked to a single address in a user's Ethereum wallet, but can be staked on Vega

## Solidity contracts
The staking bridge contracts live in [vegaprotocol/staking_bridge](https://github.com/vegaprotocol/Staking_Bridge)

## Staking Event Queue
```
       _--~~--_
     /~/_|  |_\~\
    |____________|                    Help Me Obi Wan.
    |[][][][][][]|:=  .               You're my only hope!
  __| __         |__ \  ' .          /
 |  ||. |   ==   |  |  \    ' .     /
(|  ||__|   ==   |  |)   \      '<
 |  |[] []  ==   |  |      \    '\|
 |  |____________|  |        \    |
 /__\            /__\          \ / \
  ~~              ~~

```

## Accounts
Staked assets will appear in a user's [staking account](../protocol/0013-accounts.md). As the staked tokens will be used for [governance](../protocol/0028-governance.md) in the first mainnet (aka Sweetwater), governance will need to be updated to check for staked balances as well as general account balances.
