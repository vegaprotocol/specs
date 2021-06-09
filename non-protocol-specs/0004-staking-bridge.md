# Staking Bridge

In order to manage the staking of Vega tokens from mainnet Ethereum to Vega mainnet, events need to be raised on ETH that can then be consumed by Vega.
Much like [the Ethereum bridge](../protocol/0031-ethereum-bridge-spec.md), a bridge smart contract will be used.
Unlike the ERC20 or ETH bridges however, the Staking Bridge does not rely on any sort of multisignature control and deposits/withdrawals are entirely at the discretion of the depositor.


## Solidity contracts
The staking bridge contracts live in [vegaprotocol/staking_bridge](https://github.com/vegaprotocol/Staking_Bridge)

### IStake.sol
IStake.sol contains the events necessary to track all Ethereum-side transactions using the CQRS design pattern.
Any contract that wants to be recognized by Vega as valid for staking, it must emit the specified events.

These events include:
* `event Stake_Deposited(address indexed user, uint256 amount, bytes32 indexed vega_public_key)` - This event is emitted when a stake deposit is made and should be credited to provided vega_public_key
* `event Stake_Removed(address indexed user, uint256 amount, bytes32 indexed vega_public_key)` - This event is emitted when a user removes stake and should trigger targeted vega_public_key to be decremented
* `event Stake_Transferred(address indexed from, uint256 amount, address indexed to, bytes32 indexed vega_public_key)` - This event is emitted when a user transfers the given amount of stake between the `from` and `to` wallets. This allows a user to change owing ETH wallet without removing potentially delegated stake

### Vega_Staking_Bridge.sol
Vega_Staking_Bridge.sol contains functions enabling users to deposit, remove, and transfer stake.

Functions:
* `Stake(uint256 amount, bytes32 vega_public_key)` - stakes the given amount of Vega to the target vega_public_key
* `Remove_Stake(uint256 amount, bytes32 vega_public_key)`- removes the given amount of Vega stake from the target vega_public_key
* `Transfer_Stake(uint256 amount, address new_address, bytes32 vega_public_key)` -Transfers staked Vega from the sender to the target address

### Other Implementations
[ERC20_Vesting.sol](https://github.com/vegaprotocol/Vega_Token_V2/blob/main/contracts/ERC20_Vesting.sol) emits both `Stake_Deposited` and `Stake_Removed` events.

* `stake_tokens(uint256 amount, bytes32 vega_public_key)` emits `Stake_Deposited`
* `remove_stake(uint256 amount, bytes32 vega_public_key)` emits `Stake_Removed`


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
