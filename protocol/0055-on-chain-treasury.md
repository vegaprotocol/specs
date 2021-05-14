# Network Treasury

The Network Treasury is a set of accounts (up to 1 per asset supported by the network via ther asset framework) that are funded by parties, deposits, or by direct transfers (e.g. a portion of fees, or from insurance pools at market closure). 
The funds in the network treasury are spent either by direct governance action (transfer) or by mechanisms controlled by governance, such as a periodic transfer into a reward pot. 
There is no requirement or expectation of symmetry between funds flowing into the Network Treasury and funds flowing out.
For example, the treasury account may be seeded by funds held by the team or investors, or through the issuance of tokens at various irregular points in time, and these funds may then be allocated to incentives/rewards, grants, etc. on a different schedule.


## Theory of operation

### Funding

Funding is how the on-chain treasury account receives collateral to be allocated later.


#### Funding by transfer

A transfer may specify the network treasury as the destination of the transfer. 
The funds, if available would be transferred instantly and irrevocably to the network treasury account for the asset in question (the treasury account for the asset will be created if it doesn’t exist).

- Transfer from protocol mechanics: there may be a protocol feature such as the charging or fees or handling of expired insurance pool balances that specifies the Netwok Treasury as destination in a transfer.

- Transfer by governance: a governance proposal can be submitted to transfer funds either from a market's insurance pool or from the network wide per-asset insurance pool into the on chain treasury account for the asset. TODO: link transfer spec

- Transfer transaction: a transaction submitted to the network may request to transfer funds from an account controlled by the owner’s private key (i.e. an asset general account) to the Network Treasury. TODO: link transfer spec


#### Funding by deposit

A deposit via a Vega bridge may directly specify the Network Treasury as the destination for the deposited funds. The deposited funds would then appear in the Network Treasury account

NOTE: this may not be needed once transfer transactions are built 


### Allocation 

Allocation is the process of deploying collateral from the on-chain treasury for various purposes. 
Allocation transfers funds from the on-chain treasury account for an asset to another account. 
Reward calculation mechanics etc. never directly allocate funds from the on-chain treasury account but instead would be expected to create their own account(s) to which funds are first allocated via one of the methods below. This protects the on-chain treasury from errant or wayward mechanisms that may otherwise drain the funds if configured incorrectly or exploited by a malicious actor.


#### Allocation maximums

There is also a network parameter that controls transfers from the treasury:

- `max_transfer_fraction` specifies the maximum fraction of the on chain treasury balance that can be allocated (transferred out) in any one allocation. Validation: must be strictly positive. Must be less than or equal to 1. Default 1.
This limits the transfers that are specified via `amount` as well as those specified as `fraction_of_balance`, see below.


#### Direct allocation by governance

A governance proposal may be submitted to transfer funds on enactment from the on-chain treasury to any of the following account types:

- The network wide insurance pool for the asset
- A market's insurance pool for the asset
- A reward mechanism account for the asset
- A party's general account for the asset (via direct allocation only)

The proposal specifies:

- `type`, which can be either "all or nothing", "best effort" or "fraction", where:
	- all or nothing: either transfers the specified amount or does not transfer anything
    - best effort: transfers the specified amount or the max allowable amount if this is less than the specified amount
    - fraction: transfers a fraction of the on-chain treasury's balance at the time of enactment, in the given asset
- `amount` or `fraction_of_balance` (dependant on the type chosen), which specifies how much to transfer
- `destination` specifies the account to transfer to
- Plus the normal proposal fields (i.e. voting and enactment dates, etc.)

If the proposal is successful and enacted, the amount specified will be transferred to the destination account on the enactment date, subject to the limit specified by the `max_transfer_fraction` network parameter.


#### Periodic automated allocation to reward mechanism account

For each on chain reward mechanism account (i.e. each combination of reward type and asset that rewards are made in) there will be three network parameters:

- `max_percent_per_period`
- `max_amount_per_period`
- `period_length_seconds`

For each period of duration `period_length_seconds` a transfer is made from the on-chain treasury to the reward mechanism account in question, with the amount trasnferred calculated as:

```
transfer_amount = min(max_amount_per_period, max_percent_per_period * on_chain_treasury_balance)
```
