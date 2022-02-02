# Network Parameters

There are certain parameters within Vega that influence the behaviour of the system and must be able to be changed by on-chain governance. These parameters are called "network parameters" throughout the specs. This spec describes features of these parameters and how they may be changed by [governance](./0028-GOVE-governance.md).

## What is a network parameter?

A constant (or an array of constants) in the system whose values are able to be changed by on-chain governance. Not all constants are network parameters.

A network parameter is defined by:
* Name
* Type
* Value
* Constraints
* Governance update policy 

### Name

* Editable by governance

### Type

Types available to network parameters:
- JSON as string
- string
- number
- Boolean
- array of data (that meets format requirements)

### Value

### Constraints

### Governance update policy

---

## Adding and removing network parameters

Network parameters are only added and removed with code releases.

## Amending a network parameter's value

Network parameters are able to be changed by [governance](./0028-GOVE-governance.md), however some network parameters need to be more difficult than others to change than others.

Therefore, Vega needs to know for each network parameter what governance thresholds should be applied for ascertaining a proposal to change the parameter's value. Specifically, these thresholds:

* `MinimumProposalPeriod`
* `MinimumPreEnactmentPeriod`
* `MinimumRequiredParticipation` 
* `MinimumRequiredMajority`

There are groups of network parameters that will use the same values for the thresholds.

Importantly, these Minimum Levels are themselves network parameters, and therefore subject to change. They should be self referential in terms of ascertaining the success of changing them.

For example, consider a network parameter that specifies the proportion of fees that goes to validators (feeAmtValidators), with change thresholds:

* `MinimumProposalPeriod = 30 days`
* `MinimumPreEnactmentPeriod = 10 days` 
* `MinimumRequiredParticipation = 60%` 
* `MinimumRequiredMajority = 80%`

Then a proposal that attempted to change the `feeAmtValidators.MinimumProposalPeriod` would need to pass all of the thresholds listed above. It would have to run for 30 days.. etc.

## Data to Expose

The full list of network parameters must be available to the governance community. All proposals to change a network parameter should be easily discoverable.

# Current network parameters

| Name                                                     | Type     | Specification | Description                                                       | Validation | Version added  |   
|----------------------------------------------------------|:--------:|---------------|-------------------------------------------------------------------|:---|--------:|
|`blockchains.ethereumConfig`                              | JSON     | [0031 - Ethereum Bridge](./0031-ETHB-ethereum_bridge_spec.md#network-parameters)           | Configuration for how this Vega network connects to Ethereum |  | - |
|`governance.proposal.asset.maxClose`                      | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be before `current time + maxClose`. Possible value `24h`. | | - |         |               |               | - |
|`governance.proposal.asset.requiredMajority`              | String (integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion on a [market update proposal](./0028-GOVE-governance.md#1-create-market) |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.5`.  | - |
|`governance.proposal.asset.minEnact`                      | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be after `current time + minEnact`. Possible value `2h`. | Must be greater than or equal to the corresponding `minClose` as a proposal can't be enacted before voting on it closed. | - |
|`governance.proposal.asset.minClose`                      | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be after `current time + minClose`. Possible value `1h`.   |  | - |
|`governance.proposal.asset.maxEnact`                      | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be before `current time + maxEnact`. Possible value `2h`. |       | - |         |               |               | - |
|`governance.proposal.asset.minVoterBalance`               | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](./0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [vote on a market update proposal](./0028-governance.md#1-create-market) including the correct padding instead of possible decimal places. | e.g. for 1 VEGA enter `1000000000000000000`      | - |
|`governance.proposal.asset.requiredParticipation`         | String (float) |  [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [create a market update proposal](./0028-governance.md#1-create-market)        |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.25`.             |               | - |         |               |         |      | - |
|`governance.proposal.asset.minProposerBalance`            | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to submit the proposal including the correct padding instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - |
|`governance.proposal.updateMarket.requiredMajority`       | String (integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion on a [market update proposal](./0028-GOVE-governance.md#1-create-market) |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.5`.  | - |
|`governance.proposal.updateMarket.minVoterBalance`        | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [vote on a market update proposal](./0028-governance.md#1-create-market) including the correct padding instead of possible decimal places. | e.g. for 1 VEGA enter `1000000000000000000`      | - |
|`governance.proposal.updateMarket.minProposerBalance`     | String (Integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [create a market update proposal](./0028-governance.md#1-create-market) including the correct padding instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - |
|`governance.proposal.updateMarket.requiredParticipation`  | String (float) |  [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [create a market update proposal](./0028-governance.md#1-create-market)        |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.25`.             |               | - |
|`governance.proposal.updateMarket.minClose`               | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be after `current time + minClose`. Possible value `1h`.   |  | - |
|`governance.proposal.updateMarket.maxClose`               | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be before `current time + maxClose`. Possible value `24h`. | | - |
|`governance.proposal.updateMarket.minEnact`               | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be after `current time + minEnact`. Possible value `2h`. | Must be greater than or equal to the corresponding `minClose` as a proposal can't be enacted before voting on it closed. | - |
|`governance.proposal.updateMarket.maxEnact`               | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be before `current time + maxEnact`. Possible value `2h`. |       | - |         |               |               | - |
|`governance.proposal.updateNetParam.requiredParticipation`| String (float) |  [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [create a market update proposal](./0028-governance.md#1-create-market)        |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.25`.             |               | - |
|`governance.proposal.updateNetParam.minClose`             | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be after `current time + minClose`. Possible value `1h`.   |  | - |
|`governance.proposal.updateNetParam.maxEnact`             | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be before `current time + maxEnact`. Possible value `2h`. |       | - |         |               |               | - |
|`governance.proposal.updateNetParam.minEnact`             | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be after `current time + minEnact`. Possible value `2h`. | Must be greater than or equal to the corresponding `minClose` as a proposal can't be enacted before voting on it closed. | - |
|`governance.proposal.updateNetParam.minVoterBalance`      | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [vote on a market update proposal](./0028-governance.md#1-create-market) including the correct padding instead of possible decimal places. | e.g. for 1 VEGA enter `1000000000000000000`      | - |
|`governance.proposal.updateNetParam.minProposerBalance`   | String (Integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md) required to for the relevant proposal including the correct padding instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - |
|`governance.proposal.updateNetParam.requiredMajority`     | String (integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion on a [market update proposal](./0028-GOVE-governance.md#1-create-market) |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.5`.  | - |
|`governance.proposal.updateNetParam.maxClose`             | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be before `current time + maxClose`. Possible value `24h`. | | - |         |               |               | - |
|`governance.proposal.market.minClose`                     | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be after `current time + minClose`. Possible value `1h`.   |  | - |
|`governance.proposal.market.requiredMajority`             | String (integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion on a [market update proposal](./0028-GOVE-governance.md#1-create-market) |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.5`.  | - |
|`governance.proposal.market.minEnact`                     | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be after `current time + minEnact`. Possible value `2h`. | Must be greater than or equal to the corresponding `minClose` as a proposal can't be enacted before voting on it closed. | - |
|`governance.proposal.market.maxClose`                     | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains vote closing time which has to be before `current time + maxClose`. Possible value `24h`. | | - |
|`governance.proposal.market.minVoterBalance`              | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [vote on a market update proposal](./0028-governance.md#1-create-market) including the correct padding instead of possible decimal places. | e.g. for 1 VEGA enter `1000000000000000000`      | - |
|`governance.proposal.market.minProposerBalance`           | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to submit the proposal including the correct padding instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - |
|`governance.proposal.market.requiredParticipation`        | String (float) |  [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [create a market update proposal](./0028-governance.md#1-create-market)        |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.25`.             |               | - |
|`governance.proposal.market.maxEnact`                     | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each proposal contains proposal enactment time which has to be before `current time + maxEnact`. Possible value `2h`. |       | - |         |               |               | - |
|`governance.proposal.freeform.maxClose`                   | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each freeform proposal contains vote closing time which has to be before `current time + maxClose`. Possible value `24h`. | | - |
|`governance.proposal.freeform.minClose`                   | String (duration) | [0028 - Governance](./0028-GOVE-governance.md) | Each freeform proposal contains vote closing time which has to be after `current time + minClose`. Possible value `1h`.   |  | - |
|`governance.proposal.freeform.minProposerBalance`         | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to submit a freeform proposal including the correct padding instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - |
|`governance.proposal.freeform.minVoterBalance`            | String (integer)   | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [vote on a freeform proposal](./0028-governance.md#6-freeform-governance-proposal) including the correct padding instead of possible decimal places. | e.g. for 1 VEGA enter `1000000000000000000`      | - |
|`governance.proposal.freeform.requiredMajority`           | String (integer)  | [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion on a [freeform proposal](./0028-GOVE-governance.md#6-freeform-governance-proposal) |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.5`.  | - |
|`governance.proposal.freeform.requiredParticipation`      | String (float) |  [0028 - Governance](./0028-GOVE-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-GOVE-governance.md#restriction-on-who-can-create-a-proposal) required to [create a freeform proposal](./0028-governance.md#6-freeform-governance-proposal)        |  A fraction of total token holders that must participate in a vote. Minimum `0.0`, maximum `1.0`, sensible value e.g. `0.25`.             |               | - |
||`market.stake.target.timeWindow`                         | String (duration) |  [0041 - Target Stake](./0041-TSTK-target_stake.md)        |  Length of time window over which open interest is measured |             | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.stake.target.scalingFactor`                       | String (integer) |  [0041 - Target Stake](./0041-TSTK-target_stake.md)             | Scaling between liquidity demand estimate based on open interest and target stake |              | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.margin.scalingFactors`                            | JSON         | [0019 - Margin Calculator](./0019-MCAL-margin_calculator.md) | Margin level scaling factors   |             | - |
|`market.monitor.price.updateFrequency`                    | String (duration)  | [0032 - Price Monitoring](./0032-PRIM-price_monitoring.md#network) | Frequency of price monitoring scaling factors update| | - |
|`market.monitor.price.defaultParameters`                  | JSON     | [0032 - Price Monitoring](./0032-PRIM-price_mmonitoring.md#market)| Configuration for price monitoring | | - |
|`market.value.windowLength`                               | String (duration)  | [0042 - Setting Fees and Rewarding LPs](./0042-LIQF-setting_fees_and_rewarding_lps.md)              | Length of time window over which market value is estimated      |    | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.auction.maximumDuration`                          | String (duration)  | [0026 - Auctions](./0026-AUCT-auctions.md#auction-config) | The longest duration an auction can be. Auctions that would be shorter (or [proposals that require a shorter auction](./0028-governance.md#duration-of-the-proposal)) should not be started | | - |
|`market.auction.minimumDuration`                          | String (duration)   | [0026 - Auctions](./0026-AUCT-auctions.md#auction-config) | The shortest duration an auction can be. Auctions that would be longer should not be started | | - |
|`market.fee.factors.infrastructureFee`                    | String (float) | [0029 - Fees](./0029-FEES-fees.md) | Proportion of a trade's notional value to be taken as an [infrastructure fee](./0029-FEES-fees.md#factors)| | - |
|`market.fee.factors.makerFee`                             | String (float) | [0029 - Fees](./0029-FEES-fees.md) | Proportion of a trade's notional value to be taken as a [price maker fee](./0029-FEES-fees.md#factors)| | - |
|`market.liquidityProvision.minLpStakeQuantumMultiple`     | String (float) | [0042 - setting fees and rewarding LPs](./0042-LIQF-setting_fees_and_rewarding_lps.md) | Multiplier of the asset quantum that sets the minimum LP commitment amount | |  |
|`market.liquidityProvision.shapes.maxSize`                | String (integer)| [0044 - LP Mechanics](./0044-LIQM-lp_mechanics.md#network-parameters) | The upper limit of orders in an [LP commitment shape](./0044-LIQM-lp_mechanics.md#orders-buy-shapesell-shape) | | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.maximumLiquidityFeeFactorLevel`         | String (float) | [0044 - LP Mechanics](./0044-LIQM-lp_mechanics.md#network-parameters) | The highest fee an [LP can offer](0044-LIQM-lp_mechanics.md#fees) | | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.providers.fee.distributionTimeStep`     | String (duration) | [0044 - LP Mechanics](./0044-LIQM-lp_mechanics.md#network-parameters) | How frequently liquidity rewards are [distributed to LPs](./0042-LIQF-setting_fees_and_rewarding_lps.md#distributing-fees) | | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.minimum.probabilityOfTrading.lpOrders`  | String (float) | [0038 - liquidity-provision-order-type](./0038-OLIQ-liquidity_provision_order_type.md#network-parameters) | Orders created from liquidity commitments that fall below this probability [will be repriced](./0038-OLIQ-liquidity_provision_order_type.md#network-parameters) || [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.targetstake.triggering.ratio`           | String (float) | [0044 - LP Mechanics](./0044-LIQM-lp_mechanics.md#network-parameters) |              | | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.probabilityOfTrading.tau.scaling`       |  String (integer) | [0034 - Probability-weighted Liquidity Measure](./0034-PROB-prob_weighted_liquidity_measure.ipynb) |              | | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.bondPenaltyParameter`                   |  String (float) | [0044 - LP Mechanics](./0044-LIQM-lp_mechanics.md#network-parameters) | Scaling factor for [LP penalties in case of shortfall](./0044-LIQM-lp_mechanics.md#penalties) | | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.stakeToCcySiskas`                       | String (float)   | [0044 - Liquidity Provision Mechanics](./0044-LIQM-lp_mechanics.md#network-parameters) | Translates a [Liquidity Commitment size](./0044-LIQM-lp_mechanics.md#calculating-liquidity-from-commitment) to a [volume obligation](./0044-LIQM-lp_mechanics.md#calculating-liquidity-from-commitment) | | - |
|`network.checkpoint.marketFreezeDate`                     | String (date) | [0005 - Limited Network Life](../non-protocol-specs/0005-limited-network-life.md#network-parameters) | The date before which all markets are expected to settle | | [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`network.checkpoint.networkEndOfLifeDate`                 | String (date) | [0005 - Limited Network Life](../non-protocol-specs/0005-limited-network-life.md#network-parameters) | The point at which the chain will be shutdown || [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`network.checkpoint.timeElapsedBetweenCheckpoints`        | String (duration) | [0005 - Limited Network Life](../non-protocol-specs/0005-limited-network-life.md#network-parameters) | The minimum time that should pass before another checkpoint is taken | | [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`validators.epoch.length`                                 | String (integer) | [0050 - Epochs](./0050-EPOCH-epochs.md#network-parameters) | The length (in seconds) of an Epoch | |[:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`validators.delegation.minAmount`                         | String (float) | [0059 - Simple staking & delegating](./0059-STKG-simple_staking_and_delegating.md#network-parameters) | The smallest amount of the governance asset that can be delegated |
|`validators.vote.required`                                | String (float) |                                                                                                  | The fraction of validators that need to "see" Ethereum events before the event being accepted as true. Default value `0.67`. Valid range is between `0` and `1`. |
|`reward.staking.delegation.competitionLevel`              | String (float) | [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | The level of competition of the validators (influences how much stake is be needed for all validators to reach optimal revenue). Default value `3.1`. Minimum value `1` (inclusive). No maximum.   |
|`reward.staking.delegation.delegatorShare`                | String (float) | [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | This fraction of a validator’s rewards is distributed between its delegators. Default value `0.883`. Valid range is between `0` and `1` inclusive. |
|`reward.staking.delegation.minValidators`                 | String (integer) | [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | The minimum number of validators~ used for reward calculation~. Default value `5`. Valid values are integers greater than or equal to `1`. |
|`reward.staking.delegation.maxPayoutPerEpoch`             | String (integer) | [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | The maximum amount that can be distributed from the reward pool per epoch. Number must be including the correct padding with zeros instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - | 
|`reward.staking.delegation.maxPayoutPerParticipant`       | String (integer) | [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | The maximum amount that can be distributed to a single participant from the reward pool per epoch. Number must be including the correct padding with zeros instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - | 
|`reward.staking.delegation.minimumValidatorStake`         | String (integer) | [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | The minimum amount of staking asset that a validator needs to self-delegate to be eligible for validator rewards. Number must be including the correct padding with zeros instead of possible decimal places. | e.g. for 100 VEGA enter `100000000000000000000`      | - | 
|`reward.staking.delegation.payoutDelay`                   | String (duration)| [0059 - Simple staking & delegating](./0059-STKG-simple-staking-and-delegating.md#network-parameters) | The delay in hours, after the end of an epoch, for rewards to be paid out.   | e.g. `72h` or `12h30m`      | - |
|`spam.protection.max.votes`                               | String (integer) | [0062 - Spam Protection](./0062-SPAM-spam_protection.md)  | Maximal number of  votes per proposal per epoch a vega account has. default value is 3   | `3`   | - | 
|`spam.protection.voting.min.tokens"`                      | String (integer) | [0062 - Spam Protection](./0062-SPAM-spam_protection.md)   | Minimum number of tokens an account needs to be allowed to vote on governance proposals.   | 100 tokens (i.e., 100 x 10^18units)    | - | 
|`spam.protection.max.proposals`                           | String (integer) | [0062 - Spam Protection](./0062-SPAM-spam_protection.md)  | Maximum number of proposals an account is allowed to do in one epoch. | `3`   | - | 
|`spam.protection.proposal.min.tokens`                     | String (integer) | [0062 - Spam Protection](./0062-SPAM-spam_protection.md) | Minimum amount of tokens required to be allowed to do a proposal.  Note that there is a parameter to a similar end in core; the main difference is that in spam protection, whatever stays below this threshold doesn't even make it onto the chain.   | `100000` (i.e., 100000 x 10^18)   | - | 
|`spam.protection.max.delegations`                         | String (integer) | [0062 - Spam Protection](./0062-SPAM-spam_protection.md) | Maximum number of delegation changes a Vega account is allowed in one epoch.   | `360`   | - | 
|`spam.protection.delegation.min.tokens`                   | String (integer) | [0062 - Spam Protection](./0062-SPAM-spam_protection.md) | Minimum amount of tokens needed to be allowed to delegate.   | `10^-18` (i.e., `1` ), the minimum amount of tokens possible to own.    | - |
|`network.validators.tendermint.number`                    | String (integer) | [0068 - Validators chosen by stake](./0069-VCBS-validators_chosen_by_stake.md#network-parameters) | The optimal number of validators that should be in the Tendermint validator set   |    | - |
|`network.validators.incumbentBonus`                       | String (integer) | [0068 - Validators chosen by stake](./0069-VCBS-validators_chosen_by_stake.md#network-parameters) | When comparing the stake of existing validators to ersatz validators, this is the bonus that existing validators earn   |    | - | 
|`network.validators.miniumEthereumEventsForNewValidator`  | String (integer) | [0068 - Validators chosen by stake](./0069-VCBS-validators_chosen_by_stake.md#network-parameters) | Ersatz validators must have reported or confirmed this many Ethereum events to be considered for promotion   |  `3`  | - |   
|`network.validators.multisig.numberOfSigners`             | String (integer) | [0068 - Validators chosen by stake](./0069-VCBS-validators_chosen_by_stake.md#network-parameters) | Currently set to the number of validators on the network. In future will be used to scale multisig Validator participation.   |    | - |
|`network.validators.ersatz.rewardFactor`                   | String (float) | [0068 - Validators chosen by stake](./0069-VCBS-validators_chosen_by_stake.md#network-parameters) | Scales down [the rewards](./0069-VCBS-validators_chosen_by_stake.md#ersatz-validators) of ersatz validators relative to actual validators    |    | - |
|`network.validators.ersatz.multipleOfTendermintValidators` | String (integer) | [0068 - Validators chosen by stake](./0069-VCBS-validators_chosen_by_stake.md#network-parameters) | Used to [calculate the number](./0069-VCBS-validators_chosen_by_stake.md#ersatz-validators) of ersatz validators that will earn rewards    |    | - | 

* A `-` in the *Version added* column indicates that the network parameter existed before `0.38.0`, when this table was added. 
