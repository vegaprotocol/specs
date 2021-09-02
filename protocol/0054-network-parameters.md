# Network Parameters

There are certain parameters within Vega that influence the behaviour of the system and must be able to be changed by on-chain governance. These parameters are called "network parameters" throughout the specs. This spec describes features of these parameters and how they may be changed by [governance](./0028-governance.md).

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

Network parameters are able to be changed by [governance](./0028-governance.md), however some network parameters need to be more difficult than others to change than others.

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

| Name                                                     | Type     | Specification | Description                                                       | Version added  |   
|----------------------------------------------------------|:--------:|---------------|-------------------------------------------------------------------|:--------:|
|`blockchains.ethereumConfig`                              | JSON     | [0031 - Ethereum Bridge](./0031-ethereum-bridge-spec.md#network-parameters)           | Configuration for how this Vega network connections to Ethereum   | - |
|`governance.proposal.asset.maxEnact`                      |          |               |               | - |
|`governance.proposal.asset.minVoterBalance`               |          |               |               | - |
|`governance.proposal.asset.requiredParticipation`         |          |               |               | - |
|`governance.proposal.asset.minProposerBalance`            |          |               |               | - |
|`governance.proposal.market.minVoterBalance`              |          |               |               | - |
|`governance.proposal.market.minProposerBalance`           |          |               |               | - |
|`governance.proposal.market.requiredParticipation`        |          |               |               | - |
|`governance.proposal.market.maxEnact`                     |          |               |               | - |
|`governance.proposal.updateMarket.maxEnact`               |          |               |               | - |
|`governance.proposal.updateMarket.requiredMajority`       | String (integer)  | [0028 - Governance](./0028-governance.md#governance-weighting) | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion on a [a market update proposal](./0028-governance.md#1-create-market)      | - |
|`governance.proposal.updateMarket.minVoterBalance`        | String (integer)   | [0028 - Governance](./0028-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-governance.md#restriction-on-who-can-create-a-proposal) required to [vote on a market update proposal](./0028-governance.md#1-create-market)               | - |
|`governance.proposal.updateMarket.minProposerBalance`     | String (Integer)  | [0028 - Governance](./0028-governance.md#governance-weighting) | Minimum [Governance token balance](/0028-governance.md#restriction-on-who-can-create-a-proposal) required to [create a market update proposal](./0028-governance.md#1-create-market)            | - |
|`governance.proposal.updateMarket.requiredParticipation`  |          |               |               | - |
|`governance.proposal.updateMarket.maxClose`               |          |               |               | - |
|`governance.proposal.updateMarket.minClose`               |          |               |               | - |
|`governance.proposal.updateNetParam.requiredParticipation`|          |               |               | - |
|`governance.proposal.updateNetParam.minClose`             |          |               |               | - |
|`governance.proposal.updateNetParam.maxEnact`             |          |               |               | - |
|`governance.proposal.updateNetParam.minEnact`             |          |               |               | - |
|`governance.proposal.updateNetParam.minVoterBalance`      |          |               |               | - |
|`governance.proposal.updateNetParam.minProposerBalance`   |          |               |               | - |
|`governance.proposal.asset.maxClose`                      |          |               |               | - |
|`governance.proposal.market.minClose`                     |          |               |               | - |
|`governance.proposal.market.requiredMajority`             |          |               |               | - |
|`governance.proposal.market.minEnact`                     |          |               |               | - |
|`governance.proposal.asset.requiredMajority`              |          |               |               | - |
|`governance.proposal.market.maxClose`                     |          |               |               | - |
|`governance.proposal.asset.minEnact`                      |          |               |               | - |
|`governance.proposal.updateMarket.minEnact`               |          |               |               | - |
|`governance.proposal.asset.minClose`                      |          |               |               | - |
|`governance.proposal.updateNetParam.requiredMajority`     |          |               |               | - |
|`governance.proposal.updateNetParam.maxClose`             |          |               |               | - |
|`market.stake.target.timeWindow`                          |          |               |               | - |
|`market.stake.target.scalingFactor`                       |          |               |               | - |
|`market.margin.scalingFactors`                            |          |               |               | - |
|`market.monitor.price.updateFrequency`                    | String (duration)  | [0032 - Price Monitoring](./0032-price-monitoring.md#network) | Frequency to update the price monitoring scaling factors| - |
|`market.monitor.price.defaultParameters`                  | JSON     | [0032 - Price Monitoring](./0032-price-monitoring.md#market)| Configuration for price monitoring | - |
|`market.value.windowLength`                               |          |               |               | - |
|`market.auction.maximumDuration`                          | String (duration)  | [0026 - Auctions](./0026-auctions.md#auction-config) | The longest duration an auction can be. Auctions that would be shorter (or [proposals that require a shorter auction](./0028-governance.md#duration-of-the-proposal)) should not be started | - |
|`market.auction.minimumDuration`                          | String (duration)   | [0026 - Auctions](./0026-auctions.md#auction-config) | The shortest duration an auction can be. Auctions that would be longer should not be started | - |
|`market.fee.factors.infrastructureFee`                    | String (float) | [0029 - Fees](./0029-fees.md) | Proportion of a trade's notional value to be taken as an [infrastructure fee](./0029-fees.md#factors)| - |
|`market.fee.factors.makerFee`                             | String (float) | [0029 - Fees](./0029-fees.md) | Proportion of a trade's notional value to be taken as a [price maker fee](./0029-fees.md#factors)| - |
|`market.liquidityProvision.shapes.maxSize`                | String (integer)| [0044 - LP Mechanics](./0044-lp-mechanics.md#network-parameters) | The upper limit of orders in an [LP commitment shape](./0044-lp-mechanics.md#orders-buy-shapesell-shape) | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.maximumLiquidityFeeFactorLevel`         | String (float) | [0044 - LP Mechanics](./0044-lp-mechanics.md#network-parameters) | The highest fee an [LP can offer](0044-lp-mechanics.md#fees) | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.providers.fee.distributionTimeStep`     | String (?) | [0044 - LP Mechanics](./0044-lp-mechanics.md#network-parameters) | How frequently liquidity rewards are [distributed to LPs](./0042-setting-fees-and-rewarding-lps.md#distributing-fees) | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.minimum.probabilityOfTrading.lpOrders`  | String (?) | [0038 - liquidity-provision-order-type](./0038-liquidity-provision-order-type.md#network-parameters) | Orders created from liquidity commitments that fall below this probaility [will be repriced](./0038-liquidity-provision-order-type.md#network-parameters) | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.targetstake.triggering.ratio`           | String (?) | [0044 - LP Mechanics](./0044-lp-mechanics.md#network-parameters) |               | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.probabilityOfTrading.tau.scaling`       |  String (integer) | - |               | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.bondPenaltyParameter`                   |  String (float) | [0044 - LP Mechanics](./0044-lp-mechanics.md#network-parameters) | Scaling factor for [LP penalties in case of shortfall](./0044-lp-mechanics.md#penalties) | [💃 Flamenco Tavern](../milestones/2-flamenco-tavern.md) |
|`market.liquidity.stakeToCcySiskas`                       | String (float)   | [0044 - Liquidity Provision Mechanics](./0044-lp-mechanics.md#network-parameters) | Translates a [Liquidity Commitment size](./0044-lp-mechanics.md#calculating-liquidity-from-commitment) to a [volume obligation](./0044-lp-mechanics.md#calculating-liquidity-from-commitment) | - |
|`network.checkpoint.marketsFreezeDate`                    | String (date) | [0005 - Limited Network Life](../non-protocol-specs/0005-limited-network-life.md#network-parameters) | The date before which all markets are expected to settle | [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`network.checkpoint.chainEndOfLifeDate`                   | String (date) | [0005 - Limited Network Life](../non-protocol-specs/0005-limited-network-life.md#network-parameters) | The point at which the chain will be shutdown | [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`network.checkpoint.timeElapsedBetweenCheckpoints`        | String (duration) | [0005 - Limited Network Life](../non-protocol-specs/0005-limited-network-life.md#network-parameters) | The minimum time that should pass before another checkpoint is taken | [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`validators.epoch.length`                                 | String (integer) | [0050 - Epochs](./0050-epochs.md#network-parameters) | The length (in seconds) of an Epoch | [:droplet: Sweetwater](../milestones/2.5-Sweetwater.md) |
|`validators.delegation.minAmount`                         | String (float) | [0059 - Simple staking & delegating](./0059-simple-staking-and-delegating.md#network-parameters) | The smallest amount of the governance asset that can be delegated |
|`validators.delegation.competitionLevel`                 | String (float) | [0059 - Simple staking & delegating](./0059-simple-staking-and-delegating.md#network-parameters) | The level of competition of the validators (factor how much stake would be needed for all validators to reach optimal revenue). Default value `1.1`. Minimum value `1` (inclusive). No maximum.   |
|`validators.delegation.delegatorShare`                    | String (float) | [0059 - Simple staking & delegating](./0059-simple-staking-and-delegating.md#network-parameters) | The fraction of staking rewards that goes to delegators who delegated to a validator. Default value `0.883`. Valid range is between `0` and `1` inclusive. |

* A `-` in the *Version added* column indicates that the network parameter existed before `0.38.0`, when this table was added. 
