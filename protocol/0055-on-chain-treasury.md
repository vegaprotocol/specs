# Network Treasury

The Network Treasury is a set of accounts (up to 1 per asset supported by the network via ther asset framework) that are funded by parties, deposits, or by direct transfers (e.g. a portion of fees, or from insurance pools at market closure). 
The purpose of the Network Treasury is to allow funding to be allocated to rewards, grants, etc. by token holder governance.

The funds in the network treasury are spent by being transferred to another account, either by direct governance action (i.e. voting on a specific proposed transfer) or by mechanisms controlled by governance, such as a periodic transfer, which may have network parameters that control the frequency of transfers, calculation of the amount, etc.. 
These transfers may be to a party general account, reward pool account, or insruance pool account for a market.
There is no requirement or expectation of symmetry between funds flowing into the Network Treasury and funds flowing out.
For example, the treasury account may be seeded by funds held by the team or investors, or through the issuance of tokens at various irregular points in time, and these funds may then be allocated to incentives/rewards, grants, etc. on a different schedule.

## Funding

Funding is how the on-chain treasury account receives collateral to be allocated later.

### Funding by transfer

A transfer may specify the network treasury as the destination of the transfer. 
The funds, if available would be transferred instantly and irrevocably to the network treasury account for the asset in question (the treasury account for the asset will be created if it doesn’t exist).

- Transfer from protocol mechanics: there may be a protocol feature such as the charging of fees or handling of expired insurance pool balances that specifies the Netwok Treasury as destination in a transfer. (Not required for MVP/Sweetwater)

- Transfer by governance: a [governance proposal](./0028-governance.md) can be submitted to transfer funds either from a market's insurance pool or from the network wide per-asset insurance pool into the on chain treasury account for the asset. (Not required for Sweetwater)

- Transfer transaction: a transaction submitted to the network may request to transfer funds from an account controlled by the owner’s private key (i.e. an asset general account) to the Network Treasury. (TODO: Not required for MVP/Sweetwater)


### Funding by deposit

A deposit via a Vega bridge may directly specify the Network Treasury as the destination for the deposited funds. The deposited funds would then appear in the Network Treasury account


### Funding from fee revenue (future — placeholder)

In future a fee factor (controlled by governance) may be added to allow the treasury to be funded from a component of the trading fees on the network.


### Funding from inflation or tax (future — placeholder)

In future a tax rate and/or inflation rate (controlled by governance) may be used to allow funding the network treasury with governance tokens. This would either involve transferring a fraction of each staked user's tokens to the network treausry per epoch (it is implied that this fraction would be a significantly lower value than the other assets they receive in fees), or periodic issuance of new tokens into the treasury (this would not be possible before the inflation cut-off date in the token contract).


## Allocation 

Allocation is the process of deploying collateral from the on-chain treasury for various purposes. 
Allocation transfers funds from the on-chain treasury account for an asset to another account. 
Reward calculation mechanics etc. never directly allocate funds from the on-chain treasury account but instead would be expected to create their own account(s) to which funds are first allocated via one of the methods below. This protects the on-chain treasury from errant or wayward mechanisms that may otherwise drain the funds if configured incorrectly or exploited by a malicious actor.


### Allocation maximums

There are two network parameters that control transfers from the treasury:

- `max_transfer_fraction` specifies the maximum fraction of the on chain treasury balances that can be allocated (transferred out) in any one allocation. Validation: must be strictly positive. Must be less than or equal to 1. Default 1. This single parameter applies to each per-asset treasury account.
- `max_transfer_amount` specifies the maximum absolute amount that can be allocated (transferred out) from the network treasury in any one allocation. Validation: must be strictly positive. Must be less than or equal to 1. Default 1. This single parameter applies to each per-asset treasury account.


### Direct allocation by governance

A governance proposal may be submitted to transfer funds on enactment from the on-chain treasury to certain account types. Please see [the governance spec]() for a description of this.


### Periodic automated allocation to reward pool account

For each on chain reward pool account (i.e. each combination of reward scheme and asset that rewards are made in) there may be a network parameter:

- `<reward_scheme_id>.<asset_id>.periodic_allocation`: a data structure with three elements:
	- `max_fraction_per_period`
	- `max_amount_per_period`
	- `period_length_seconds`

This parameter must be defaulted as empty for each reward scheme that's created, which ensures that periodic automated allocation will not happen for any reward scheme unless separately enabled through a separate governance process. That is, periodic allocation should not be able to be configured in the same proposal that creates the reward scheme itself.

For each period of duration `period_length_seconds` a transfer is made from the on-chain treasury to the reward pool account in question as described in the governance initiated transfers spec (including network wide amount limits, etc.) (TODO: link), where the following are used for the transfer details:
- `source_type` =  network treasury
- `source` = blank (only one per asset)
- `type` =  "best effort"
- `asset` = the `asset_id` matching the one in network parameter name
- `amount` = `max_amount_per_period`
- `fraction_of_balance` = `max_fraction_per_period`
- `destination_type` = "reward pool"
- `destination` = the `reward_scheme_id` matching the one in network parameter name

The transfer occurs immediately per once every `period_length_seconds` and does not require voting, etc. as the governance proposal used to set the parameters for the periodic transfer has already approved it.


## Acceptance criteria


### 💧 Sweetwater

- Depositing funds via the [ERC20 bridge](./0031-ethereum-bridge-spec.md) directly to the Validators Rewards account (i.e. xxx address). There will be no more  on-chain-treasury on sweetwater.

### 🤠 Oregon Trail WIP

- TBD for a lot of this
- Depositing funds via the [ERC20 bridge](./0031-ethereum-bridge-spec.md) to the Network Treasury account (i.e. zero address) when there is no Network Treasury account for the asset being deposited:
	- Creates a Network Treasury account for that asset 
	- Results in the balance of the Network Treasury account for the asset being equal to the amount of the asset that was deposited
	- The Network Treasury accounts API includes the new account 
	- The Network Treasury accounts API returns the correct balance for the new account
- Depositing funds via the ERC20 bridge to the Network Treasury account (i.e. zero address) when there is already a Network Treasury account for the asset being deposited:
	- Increments the balance of the Network Treasury account for the asset by the amount of the asset that was deposited
	- The Network Treasury accounts API returns the correct balance for the new account
- No party can withdraw assets from the Network Treasury account via the ERC20 bridge
- No party can use assets in the Network Treasury account as margin or transfer them to another account on Vega
- The network treasury account balances [are restored after a network restart](../non-protocol-specs/0005-limited-network-life.md)
- It is possible to set a network parameter for periodic allocation to the [staking and delegation reward scheme](./0057-reward-functions.md) **for any valid asset ID** in the asset framework:
	- The parameter can be set/changed via governance
	- The parameter defaults to an empty/null/false state (or doesn't exist by default)
	- The parameter is a structure that includes values for `max fraction per period`, `max amount per period`, and `period length in seconds`
	- If `max_fraction_per_period` is zero, no funds are allocated 
	- If `max_amount_per_period` is zero, no funds are allocated 
	- If `period_length_seconds` is zero or blank/empty, no attempt to allocate funds occurs
- The allocation network parameter can be set for an asset in order to distribute funds to the staking and delegation reward pool for the asset:
  - If `period_length_seconds` is non-zero, the amount to be transferred to the reward pool is calculated and the distribution occurs. This happens `period_length_seconds` seconds after the last attempt to calculate and distribute funds, if no attempt has ever been made then the first distribution is calculated immediately.
	- The amount sent to the reward pool account is equal to the smaller of `max_amount_per_period` and `max_fraction_per_period * network_treasury_balance[assset]`
	- The balance of the treasury account for the asset is reduced by the amount sent
	- The balance of the target reward pool account for the asset is increased by the amount sent

NOTE: for Sweetwater the allocation logic and reward pools can be simplified to work only for the governance asset (i.e. VEGA tokens) if needed.





