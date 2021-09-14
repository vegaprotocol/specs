# Decentralised limits and controls

This spec describes a set of limits and controls that must be supported by deployments of the Vega system to mitigate the risk of loss or misappropriation of funds early in the life of the system while it is relatively less well tested and more likely to contain major bugs or mechanism design issues. The aim is to achieve this by implementing features which reduce both the expected magnitude and the probability of financial loss, from the perspective of participants interacting with the Vega protocol.

These limits are expected to be used in early deployments of Vega and are desiogned to be raised and/or removed over time via the governance protocol as the security and the robustness of the implementation is demonstrated.


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

1. Prevent the submission of market creation proposals until a validator initiated and agreed change (i.e. a genesis/config/code change required rather than a network parameter)
2. Prevent the submission of asset addition proposals until a validator initiated and agreed change (i.e. a genesis/config/code change required rather than a network parameter)
3. Set a date/time before which no market creation proposal will be enacted as a network parameter (note if the above submission prevention is in place the proposal must still be rejected after this date)
4. Set a date/time before which no asset addition proposal will be enacted as a network parameter (note if the above submission prevention is in place the proposal must still be rejected after this date)

At genesis, Sweetwater will be started with only one asset: VEGA. As no new assets can be proposed (limit 2), only VEGA tokens can be deposited or withdrawn via the bridge. There will be no markets at genesis, and due to point 1 above, no markets can be created.

### Oregon Tail

We have identified three types of limit/control that will together achieve these aims:

- Deposit limits reduce the exposure of individual participants as well as the total funds at risk
- Withdrawal controls reduce the probability that funds acquired in error on Vega can be taken outside the control of the system before the error can be fixed
- A system wide deposit/withdrawal stop provides the ability to buy extra time to investigate or fix any issues 


### Deposit limits

These limits restrict the risk that can be easily taken by each participant. They can be overcome by creating multiple keypairs on Vega and the host chain, but per the principles above and given the impact of gas costs, this is not a problem.  

- There will be a `maximum lifetime deposit` configured for each asset (as part of Vega asset proposal). This amount will be stored in the host chain's bridge contract system and set during the whitelisting process for adding a new asset to Vega.
- It should be possible to amend the `maximum lifetime deposit` via a Vega governance transaction (update asset). This should cause Vega to create a signed bundle when the governance transaction is enacted. Someone would be expected to submit this transaction to the Ethereum chain for it to take effect.  
- Any attempt to deposit funds where `total funds deposited by sender address > maximum lifetime deposit` must be rejected (by the Ethereum bridge contract).
- Any attempt to deposit funds where `total funds deposited to receiver address > maximum lifetime deposit` must be rejected (by the Ethereum bridge contract).

### Withdrawal limits

These limits reduce the risk that someone who is able to exploit implementation bugs or protocol design issues is able to acquire and withdraw funds that are not intended for them. 

- A single `withdrawal delay period` to apply for all assets will be stored in the bridge contract system. This will default to 120 hours (5 days) and may be changed via multisig control.
- There will be a `withdrawal delay threshold` configured for each asset. This amount will be stored in the host chain's bridge contract system and set during the whitelisting process for adding a new asset to Vega.
- It should be possible to amend the `withdrawal delay threshold` via a Vega governance transaction (update asset). This should cause Vega to create a signed bundle when the governance transaction is enacted. Someone would be expected to submit this transaction to the Ethereum chain for it to take effect.  
- Any withdrawal bundle created where `withdrawal amount > withdrawal delay threshold` will be rejected by the bridge if `time since bundle creation <= withdrawal delay period` (the bundle must therefore contain a timestamp of its creation, which must be validated by nodes before they sign the bundle)
- An API is required to list all pending withdrawals (i.e. those that have not been executed on the bridge) on the Vega chain across all public keys. This is required to allow the community to identify transactiosn that require withdrawals to stopped pending investigation

### Global bridge stop

This allows the stoppage of all deposits and withdrawals after the discovery of an issue or potential issue that requires investigation and/or deployment of a fix. Deposits and withdrawals would be reinstated once the situation is resolved.

- A quorum of validators may sign a transaction bundle which, when submitted to the bridge contract system, will stop the processing of all withdrawals and deposits. This would be done by removing the assignment of the bridge contract to the asset pool, without which the bridge contract cannot control assets in the pool.
- Similarly, a quorum of validators may sign a transaction bundle which, when submitted to the bridge contract system, will resume deposits and withdrawals by assigning a bridge contract to the pool again. This may be the original bridge contract or, if it was the source of the problem, an alternative bridge contract that may be deployed with fixes.
- Note that this entire feature is understood to be existing functionality of the bridge contract system and should require no new development other than that described in the "Tooling/UI support" section below.


### Tooling/UI support

- A simple tool is required to generate valid transactions for operating all features in this spec. This must be usable regardless of whether the Vega chain is running.
- A tool to manually sign such transactions and to create the required multisig control signature bundle from these signatures (which will be performed remotely from each other) is also required.
- Unless explicitly mentioned, Vega transactions (governance or otherwise) are **not required** and the Vega chain does not need to interact with these features directly.
- Console should be aware of limits, delays, thresholds etc. (i.e. by querying the bridge contract system)


## Out of scope

- Orderly withdrawal of funds (including those held by participant accounts and the insurance pool) at the end of life of a Vega network (when these have limited lives) is out of scope for this spec and is covered in the [limited network life spec](0005-limited-network-life.md).


## Limitations

- These features do not protect against a malicious validator set.
- No attempt is made to prevent sybils with these features, although the ratio between gas fees for deposites and withdrawals and the limits per public key will affect the attractiveness of **any** money making scheme whether by intended or unintended behaviour of the protocol, therefore low limits can provide some level of mitigation here.
- Users could submit multiple small withdrawals to get around the size limits for delays. To mitigate this, sizes can be set such that gas costs of such an approach would be significant, or to zero so that all withdrawals are delayed. 
