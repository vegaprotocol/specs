# ERC-20 Governance Token Staking

## Summary

Vega makes uses of a ERC-20 token on the Ethereum blockchain as a [governance asset](./../protocol/0028-GOVE-governance.md) for [delegation](../protocol/0059-STKG-simple_staking_and_delegating.md) to validators and creation and voting of [governance proposals](./../protocol/0028-GOVE-governance.md). A party's governance tokens must first be recognised against a Vega public key before they can be used on the Vega network for governance and delegation.

Although it would be possible to use the standard ERC-20 bridge to deposit governance tokens and put them in full control of the Vega network, the system will not do this for the governance asset. Instead there will be a separate system that allows governance tokens (only) to be "staked" to a Vega public key (and "unstaked" when done) without any action on the Vega network, and without putting the tokens under the control of the Vega network. This approach has been chosen for two primary reasons:

1. Any attacker who gains control of or is able to exploit the Vega network will be unable to steal staked Vega tokens. This means that even if an attacker was able to take over the network, the tokenholders would remain unchanged and could fix the issue and relaunch the network by delegating to new validators.
2. This method allows unvested (locked) tokens to be staked. Both staking and unstaking are controlled entirely on the Ethereum side, and staked balances are recognised on the Vega network by listening for `Stake_*` events which can be emitted by any contract that's recognised by the network, which makes it possible to implement stake/unstake functionality into the token vesting contract in additional to the normal "staking bridge" contract.

In order to manage the staking of Vega tokens from mainnet Ethereum to Vega mainnet, events need to be raised on ETH that can then be consumed by Vega.
Much like [the Ethereum bridge](./../protocol/0031-ETHB-ethereum_bridge_spec.md), a bridge smart contract will be used.
Unlike the ERC-20 or ETH bridges however, the Staking Bridge does not rely on any sort of multisignature control and deposits/withdrawals are entirely at the discretion of the depositor.

## Components of staking

### Vega network

Staked assets will appear in a user's [staking account](./../protocol/0013-ACCT-accounts.md) once the Vega network sees the relevant `Stake_Deposited` event(s) with enough confirmations (defined by a network parameter). As the staked tokens will be used for [governance](./../protocol/0028-GOVE-governance.md), the governance will weight votes based on the staking account balance instead of the general account balance. Delegation functionality will also use the staking account balance as the source of truth for the maximum number of delegated tokens.

- Vega will have a new `stake account` account type to track the balance of staked tokens for each public key
- Vega  will listen for `Stake_Deposited` events from the staking bridge and ERC-20 vesting contracts (see below) and increase the balance in the appropriate party's stake account by the amount deposited each time new stake is deposited
- Vega  will listen for `Stake_Removed` events from the staking bridge and ERC-20 vesting contracts (see below) and decrease the balance in the appropriate party's stake account by the amount removed each time stake is removed (unstaked)
- There will be APIs to list parties with non-zero stake account balances and query stake account balances
- There will be APIs to query `Stake_Deposited` and `Stake_Removed` events that have been processed by the network
- Both governance and delegation will need to handle the fact that the stake account balance can be reduced without warning if a user unstakes tokens.

Note: the behaviour of delegation is covered in [staking and delegation](./../protocol/0059-STKG-simple_staking_and_delegating.md), and the use of stake to determine a party's weight in governance votes is covered in [governance](./../protocol/0028-GOVE-governance.md).

### Bootstraping of a network / of the staking accounts balances

When a vega network is bootstraping it's necessary for each validators nodes to recompute the current balance of all the parties which ever locked tokens on the staking or vesting bridge.
This is required, so when the network is finally starting or if a snapshot is loaded, then no delegation request would become incorrect either because of token being locked, or unlocked during the shutdown of the network.

We introduce a new network parameter `staking_balances_bootstrap_block_count`, which in number of blocks to be executed, from the genesis block. During this time the network will accept no new transaction from any parties, and only transaction from the validators used to validate staking accounts balances will be accepted.

Transaction to restore a snapshot would also be allowed during this time.

## Ethereum network (Solidity contracts)

The majority of the logic for staking of ERC-20 governance tokens exists on the Ethereum network in the form of new and updated Solidity contracts. These define the interface that contracts implementing staking must conform to and the events that they must emit, and implement staking for both normal ERC-20 tokens and tokens locked in the vesting contract.

The staking bridge contracts live in [vegaprotocol/staking_bridge](https://github.com/vegaprotocol/Staking_Bridge)

### Staking interface (`IStake.sol`)

The staking interface defines the events necessary to track all Ethereum-side transactions using the CQRS design pattern.
Any contract that wants to be recognised by Vega as valid for staking must emit the specified events.

These events are:

- `event Stake_Deposited(address indexed user, uint256 amount, bytes32 indexed vega_public_key)` - This event is emitted when a stake deposit is made and must be credited to provided vega_public_key's stake account
- `event Stake_Removed(address indexed user, uint256 amount, bytes32 indexed vega_public_key)` - This event is emitted when a user removes stake and must trigger the targeted vega_public_key's stake account to be decremented
- `event Stake_Transferred(address indexed from, uint256 amount, address indexed to, bytes32 indexed vega_public_key)` - This event is emitted when a user transfers the given amount of stake between the `from` and `to` wallets. This allows a user to change owing ETH wallet without removing potentially delegated stake. It is optional whether contracts that permit staking allow this operation.

### Staking bridge (`Vega_Staking_Bridge.sol`)

The staking bridge contains functions enabling users to deposit, remove, and transfer stake by moving the governance tokens from a user's wallet to the staking bridge. This contract is used for all staking of tokens except where the tokens to be staked reside in the ERC-20 vesting contract.

Functions:

- `Stake(uint256 amount, bytes32 vega_public_key)` - stakes the given amount of governance tokens to the target vega_public_key
  - Requires that the sender address calling the function holds at least `amount` governance tokens that are able to be transferred to the staking bridge (note: tokens held by the vesting contract on behalf of an address do not count here)
  - Emits the `Stake_Deposited` event
- `Remove_Stake(uint256 amount, bytes32 vega_public_key)`- removes the given amount of governance tokens stake from the target vega_public_key
  - Requires that at least `amount` tokens are staked by the sender with the staking bridge (not the vesting or any other contract implementing `IStake`) to the specified Vega public key
  - Must not unstake tokens staked to another Vega key or from another contract (i.e. vesting)
  - Emits the `Stake_Removed` event
- `Transfer_Stake(uint256 amount, address new_address, bytes32 vega_public_key)` - Transfers staked governance from the sender to the target address
  - This changes the address that can unstake the tokens, and that will receive the tokens from the staking bridge when unstaked
  - This does not change the Vega public key to which the tokens are staked and will therefore not interrupt delegation
  - Requires that at least `amount` tokens are staked by the sender with the staking bridge (not the vesting or any other contract implementing `IStake`) to the specified Vega public key
  - Emits the `Stake_Transferred` event

### ERC-20 vesting contract (`ERC20_Vesting.sol`)

The ERC-20 vesting contract implements the [Token V2](../non-protocol-specs/0002-NP-TOKT-token_v2.md) specification and must also support the staking of tokens it holds as specified here. It will [ERC20_Vesting.sol](https://github.com/vegaprotocol/Vega_Token_V2/blob/main/contracts/ERC20_Vesting.sol) emit the `Stake_Deposited` and `Stake_Removed` events.

Functions:

- `stake_tokens(uint256 amount, bytes32 vega_public_key)` allows staking of tokens held by the contract on behalf of an address
  - Requires that the vesting contract holds at least `amount` governance tokens, that are currently not staked, on behalf of the sender address (i.e. they will be redeemable by sender once vested)
  - Must allow both unvested (locked) tokens and vested tokens that are not yet redeemed to be staked
  - Emits `Stake_Deposited`
- `remove_stake(uint256 amount, bytes32 vega_public_key)`
  - Requires that the vesting contract holds at least `amount` governance tokens, that are currently staked to the specified Vega public key, on behalf of the sender address (i.e. they will be redeemable by sender once vested)
  - Emits `Stake_Removed`

Other functionality:

- Attempts to redeem vested tokens will fail if there are not sufficient tokens held on behalf of the sender address that are not staked. Sender must first unstake tokens before they can be redeemed.
- This functionality does not interact in any way with the staking bridge contract. They are effectively completely separate staking mechanisms, so to unstake all an address's tokens when some are staked on each contract will require calls to both contracts.

## Acceptance Criteria

### Staking Bridge Smart Contract

- Staking Bridge accepts and locks deposited VEGA tokens and emits `Stake_Deposited` event (<a name="0071-STAK-001" href="#0071-STAK-001">0071-STAK-001</a>)(<a name="0071-SP-STAK-001" href="#0071-SP-STAK-001">0071-SP-STAK-001</a>)
- Staking Bridge allows only stakers to remove their staked tokens and emits `Stake_Removed` event (<a name="0071-STAK-002" href="#0071-STAK-002">0071-STAK-002</a>)(<a name="0071-SP-STAK-002" href="#0071-SP-STAK-002">0071-SP-STAK-002</a>)
- Staking Bridge allows users with staked balance to transfer ownership of stake to new ethereum address that only the new address can remove (<a name="0071-STAK-003" href="#0071-STAK-003">0071-STAK-003</a>)(<a name="0071-SP-STAK-003" href="#0071-SP-STAK-003">0071-SP-STAK-003</a>)
- Staking Bridge prohibits users from removing stake they don't own (<a name="0071-STAK-012" href="#0071-STAK-012">0071-STAK-012</a>)(<a name="0071-SP-STAK-012" href="#0071-SP-STAK-012">0071-SP-STAK-012</a>)
- Staking Bridge prohibits users from removing stake they have transferred to other ETH address (<a name="0071-STAK-013" href="#0071-STAK-013">0071-STAK-013</a>)(<a name="0071-SP-STAK-013" href="#0071-SP-STAK-013">0071-SP-STAK-013</a>)

### Vesting Smart Contract

- Vesting Contract locks vesting VEGA tokens and emits `Stake_Deposited` event (<a name="0071-STAK-005" href="#0071-STAK-005">0071-STAK-005</a>)(<a name="0071-SP-STAK-005" href="#0071-SP-STAK-005">0071-SP-STAK-005</a>)
- Vesting Contract unlocks vesting VEGA tokens and emits `Stake_Removed` event (<a name="0071-STAK-006" href="#0071-STAK-006">0071-STAK-006</a>)(<a name="0071-SP-STAK-006" href="#0071-SP-STAK-006">0071-SP-STAK-006</a>)
- Vesting Contract prohibits withdrawal of VEGA while that VEGA is staked (<a name="0071-STAK-007" href="#0071-STAK-007">0071-STAK-007</a>)(<a name="0071-SP-STAK-007" href="#0071-SP-STAK-007">0071-SP-STAK-007</a>)

### Event Queue

- Event Queue sees `Stake_Deposited` event from Staking Bridge smart contract and credits target Vega user with stake (<a name="0071-STAK-008" href="#0071-STAK-008">0071-STAK-008</a>)(<a name="0071-SP-STAK-008" href="#0071-SP-STAK-008">0071-SP-STAK-008</a>)
- Event Queue sees `Stake_Removed` event from Staking Bridge smart contract and removes stake from appropriate Vega user (<a name="0071-STAK-009" href="#0071-STAK-009">0071-STAK-009</a>)(<a name="0071-SP-STAK-009" href="#0071-SP-STAK-009">0071-SP-STAK-009</a>)
- Event Queue sees `Stake_Deposited` event from Vesting smart contract and credits target Vega user with stake (<a name="0071-STAK-010" href="#0071-STAK-010">0071-STAK-010</a>)(<a name="0071-SP-STAK-010" href="#0071-SP-STAK-010">0071-SP-STAK-010</a>)
- Event Queue sees `Stake_Removed` event from Vesting smart contract and removes stake from appropriate Vega user (<a name="0071-STAK-011" href="#0071-STAK-011">0071-STAK-011</a>)(<a name="0071-STAK-011" href="#0071-SP-STAK-011">0071-SP-STAK-011</a>)
