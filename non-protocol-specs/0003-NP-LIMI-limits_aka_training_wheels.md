# Decentralised limits and controls

This spec describes a set of limits and controls that must be supported by deployments of the Vega system to mitigate the risk of loss or misappropriation of funds early in the life of the system while it is relatively less well tested and more likely to contain major bugs or mechanism design issues. The aim is to achieve this by implementing features which reduce both the expected magnitude and the probability of financial loss, from the perspective of participants interacting with the Vega protocol.

These limits are expected to be used in early deployments of Vega and are designed to be raised and/or removed over time via the governance protocol as the security and the robustness of the implementation is demonstrated.

## Principles

These features:

- Must not introduce points of centralisation. They are therefore designed to be operated by decentralised governance protocols in keeping with the core Vega protocol.
- Should be as simple as possible and should operate correctly independent of whether any aspect of the core protocol is functioning as expected (i.e. they should allow recovery from issues in which someone is able to exploit bugs in products, margins, data sourcing, settlement, collateral, etc.).
- Are designed to be resilient to failure of the Vega chain and operable assuming only the continued existence of an honest quorum of validators (with their private keys) and the multisig control and bridge pool contract holding control over assets on the Ethereum chain.
- Are risk-based: they do not need to prevent certain things happening or provide absolute guarantees so much as to reduce the probabilities and magnitudes.
- Signal the system's readiness and risk level: should be implemented and communicated and raised over time in such a way that the risks inherent in the system are clear, and that going beyond the limits (e.g. using sybils) requires sufficient understanding and effort that it would be done with clear knowledge of the risks.
- Are intended for early alpha versions of the Vega system and are expected to be implemented almost entirely in the Ethereum bridge smart contracts, no thought has been given to implementations for other chains.

## Required limits and controls

### Sweetwater

For Sweetwater, we only require the ability to:

1. Prevent the submission of market creation proposals until a validator initiated and agreed change to the genesis configuration
1. Prevent the submission of asset addition proposals until a validator initiated and agreed change to the genesis configuration
1. Set a date/time before which no market creation proposal will be enacted as a network parameter (note if the above submission prevention is in place the proposal must still be rejected after this date)
1. Set a date/time before which no asset addition proposal will be enacted as a network parameter (note if the above submission prevention is in place the proposal must still be rejected after this date)

At genesis, Sweetwater will be started with only one asset: VEGA. As no new assets can be proposed (limit 2), only VEGA tokens can be deposited or withdrawn via the bridge. There will be no markets at genesis, and due to point 1 above, no markets can be created.

### Sweetwater++

We have identified three types of limit/control that will together achieve these aims:

- Deposit limits reduce the exposure of individual participants as well as the total funds at risk
- Withdrawal controls reduce the probability that funds acquired in error on Vega can be taken outside the control of the system before the error can be fixed
- A system wide deposit/withdrawal stop provides the ability to buy extra time to investigate or fix any issues

#### Deposit limits

These limits restrict the risk that can be easily taken by each participant. They can be overcome by creating multiple keypairs on Vega and the host chain, but per the principles above and given the impact of gas costs, this is not a problem.

- There will be a `maximum lifetime deposit` configured for each asset (as part of Vega asset proposal). This amount will be stored in the host chain's bridge contract system and set during the whitelisting process for adding a new asset to Vega.
- It should be possible to amend the `maximum lifetime deposit` via a Vega governance transaction (update asset). This should cause Vega to create a signed bundle when the governance transaction is enacted. Someone would be expected to submit this transaction to the Ethereum chain for it to take effect.
- Any attempt to deposit funds where `total funds deposited by sender address > maximum lifetime deposit` must be rejected (by the Ethereum bridge contract).
- Any attempt to deposit funds where `total funds deposited to receiver address > maximum lifetime deposit` must be rejected (by the Ethereum bridge contract).
- Users can exempt themselves from the deposit limits by running `exempt_depositor()` after which transactions greater than deposit limit for that asset will be allowed.

#### Withdrawal limits

These limits reduce the risk that someone who is able to exploit implementation bugs or protocol design issues is able to acquire and withdraw funds that are not intended for them.

- A single `withdrawal delay period` to apply for all assets will be stored in the bridge contract system. This will default to 120 hours (5 days) and may be changed via multisig control.
- There will be a `withdrawal delay threshold` configured for each asset. This sets a threshold amount above which the withdrawal is subject to an additional delay. This amount will be stored in the host chain's bridge contract system and set during the whitelisting process for adding a new asset to Vega.
- It should be possible to amend the `withdrawal delay threshold` via a Vega governance transaction (update asset). This should cause Vega to create a signed bundle when the governance transaction is enacted. Someone would be expected to submit this transaction to the Ethereum chain for it to take effect.
- Any withdrawal bundle created where `withdrawal amount > withdrawal delay threshold` will be rejected by the bridge if `time since bundle creation <= withdrawal delay period` (the bundle must therefore contain a timestamp of its creation, which must be validated by nodes before they sign the bundle).
- An API is required to list all pending withdrawals (i.e. those that have not been executed on the bridge) on the Vega chain across all public keys. This is required to allow the community to identify transactions that require withdrawals to stopped pending investigation.

#### Global bridge stop

This allows the stoppage of all deposits and withdrawals after the discovery of an issue or potential issue that requires investigation and/or deployment of a fix. Deposits and withdrawals would be reinstated once the situation is resolved.

- A quorum of validators may sign a transaction bundle which, when submitted to the bridge contract system, will stop the processing of all withdrawals and deposits. This would be done by removing the assignment of the bridge contract to the asset pool, without which the bridge contract cannot control assets in the pool.
- Similarly, a quorum of validators may sign a transaction bundle which, when submitted to the bridge contract system, will resume deposits and withdrawals by assigning a bridge contract to the pool again. This may be the original bridge contract or, if it was the source of the problem, an alternative bridge contract that may be deployed with fixes.
- Note that this entire feature is understood to be existing functionality of the bridge contract system and should require no new development other than that described in the "Tooling/UI support" section below.

### Deposit Limit Exemptions

This allows for the listing of specific Ethereum addresses to be able to deposit more than the lifetime limits for the asset.
This is primarily for liquidity providers and other sophisticated participants and for depositing rewards.

- Any ETH address can add/remove *itself* from the list of exempt addresses.
- Any ETH address on the deposit allowlist can deposit as normal, bypassing deposit limits both on ETH key and destination Vega key.
- Withdrawal limits *are still in place for everyone*.

### Tooling/UI support

- A simple tool is required to generate valid transactions for operating all features in this spec. This must be usable regardless of whether the Vega chain is running.
- A tool to manually sign such transactions and to create the required multisig control signature bundle from these signatures (which will be performed remotely from each other) is also required.
- Unless explicitly mentioned, Vega transactions (governance or otherwise) are **not required** and the Vega chain does not need to interact with these features directly.
- Console should be aware of limits, delays, thresholds etc. (i.e. by querying the bridge contract system)

## Out of scope

- Orderly withdrawal of funds (including those held by participant accounts and the insurance pool) at the end of life of a Vega network (when these have limited lives) is out of scope for this spec and is covered in the [limited network life spec](../protocol/0073-LIMN-limited_network_life.md).

## Limitations

- These features do not protect against a malicious validator set.
- No attempt is made to prevent sybils with these features, although the ratio between gas fees for deposits and withdrawals and the limits per public key will affect the attractiveness of **any** money making scheme whether by intended or unintended behaviour of the protocol, therefore low limits can provide some level of mitigation here.
- Users could submit multiple small withdrawals to get around the size limits for delays. To mitigate this, sizes can be set such that gas costs of such an approach would be significant, or to zero so that all withdrawals are delayed.

## Network Parameters

| Property         | Type   | Example value | Description |
|------------------|--------| ------------|--------------|
| `limits.assets.proposeEnabledFrom`       | String (date) |  `"2021-12-17T14:34:26Z"`        | The date/time after which asset creation is allowed.  |
| `limits.markets.proposeEnabledFrom`      | String (date) |  `"2021-12-17T14:34:26Z"`        | The date/time after which market creation is allowed.  |

## Acceptance Criteria

### Vega criteria

1. Market Creation can be restricted using a genesis configuration (<a href="../protocol/0028-GOVE-governance.md#0028-GOVE-024">0028-GOVE-024</a>)
    - With `propose_market_enabled` set to true in the genesis configuration;
    - With `propose_market_enabled_from` set to the future
      - Any market creation proposal is rejected
      - After a the date set in `propose_market_enabled_from`
        - Any valid market creation proposal is allowed, as per [0028-GOVE](./../protocol/0028-GOVE-governance.md)
    - With `propose_market_enabled_from` set to the past
      - Any valid market creation proposal is allowed, as per [0028-GOVE](./../protocol/0028-GOVE-governance.md)
1. Asset creation can be restricted using genesis configuration  (<a href="../protocol/0028-GOVE-governance.md#0028-GOVE-025">0028-GOVE-025</a>)
    - With `propose_asset_enabled` set to true in the genesis configuration
    - With `propose_asset_enabled_from` set to the future:
      - Any asset creation proposal is rejected
      - After the date set in `propose_asset_enabled_from`
        - Any valid asset creation proposal is allowed, as per [0028-GOVE](./../protocol/0028-GOVE-governance.md)
    - With `propose_asset_enabled_from` set to the past:
      - Any valid asset creation proposal is allowed, as per [0028-GOVE](./../protocol/0028-GOVE-governance.md)
1. `propose_market_enabled_from` can be changed through a network parameter update proposal (<a href="../protocol/0028-GOVE-governance.md#0028-GOVE-008">0028-GOVE-008</a>)
1. `propose_asset_enabled_from` can be changed through a network parameter update proposal (<a href="../protocol/0028-GOVE-governance.md#0028-GOVE-008">0028-GOVE-008</a>)

### Smart contract criteria

1. `max lifetime deposit` is enforced by the [ERC20 bridge](./../protocol/0031-ETHB-ethereum_bridge_spec.md) (<a name="0003-NP-LIMI-001" href="#0003-NP-LIMI-001">0003-NP-LIMI-001</a>)
    - This does not apply to the [governance staking contract](./../glossaries/staking-and-governance.md)
    - With an Ethereum address that has never deposited to Vega before:
      - A valid deposit transaction that is less than `max lifetime deposit` is not rejected
        - A valid second deposit transaction that, in addition to the first TX exceeds `max lifetime deposit` is rejected
        - This is true even if both TXs target different [Vega public keys](./../protocol/0017-PART-party.md)
      - Withdrawing all funds after the first transaction, then placing a valid second deposit transaction that causes total lifetime deposits to exceed `max lifetime deposit` is still rejected
      - A single deposit transaction that is more than `max lifetime deposit` rejected
1. `max lifetime deposit` can be overridden for specific Ethereum addresses through an Ethereum transaction (<a name="0003-NP-LIMI-002" href="#0003-NP-LIMI-002">0003-NP-LIMI-002</a>)
    - An ETH address that is listed on the smart contract as exempt can deposit more than `max lifetime deposit`
    - Any ETH address can use a method on the smart contract to add or remove itself (own ETH address) from the exemption list
1. `max lifetime deposit` can be updated per asset via an Ethereum transaction (<a name="0003-NP-LIMI-003" href="#0003-NP-LIMI-003">0003-NP-LIMI-003</a>)
1. Validators can, via multisig, stop and recommence processing bridge transactions (<a name="0003-NP-LIMI-004" href="#0003-NP-LIMI-004">0003-NP-LIMI-004</a>)
    - A representative set of validators can produce a multisig transaction that stops all future deposits and withdrawals
    - A representative set of validators can produce a multisig transaction that allows the bridge to resume processing future deposits and withdrawals
    - All withdrawals that are submitted while the bridge is 'stopped' are rejected
    - All deposits that are submitted while the bridge is 'stopped' are rejected
1. Withdrawal delay network parameter requires a wait between withdrawals creation & submission if it meets or exceeds a threshold (<a name="0003-NP-LIMI-005" href="#0003-NP-LIMI-005">0003-NP-LIMI-005</a>)
    - For valid withdrawals that have been approved by validators, when the user submits the TX to the bridge smart contract:
      - If the withdrawal amount is below or equal to `withdrawal delay threshold`, the withdrawal is accepted by the bridge smart contract
      - If the withdrawal amount is above `withdrawal delay threshold` for the asset,
        - If it is submitted before `withdrawal delay period`, it is rejected by the bridge smart contract
        - If it is submitted after `withdrawal delay period`, it is accepted by the bridge smart contract
      - `withdrawal delay threshold` can be changed, per asset, by multisig control on the bridge contract
1. A withdrawal that is subject to delay can be cancelled by a validator (<a name="0003-NP-LIMI-006" href="#0003-NP-LIMI-006">0003-NP-LIMI-006</a>)
