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

The full list of network parameters must be available to the governance community. All proposals to change a network parameter should be easily discoverable.@

# Current network parameters
| Name                                                     | Type     | Specification | Description                                                       |
|----------------------------------------------------------|:--------:|---------------|-------------------------------------------------------------------|
|`blockchains.ethereumConfig`                              | JSON     | [0031 - Ethereum Bridge](./0031-ethereum-bridge-spec.md#network-parameters)              | Configuration for how this Vega network connections to Ethereum   |
|`governance.proposal.asset.maxEnact`                      |          |               |               |
|`governance.proposal.asset.minVoterBalance`               |          |               |               |
|`governance.proposal.asset.requiredParticipation`         |          |               |               |
|`governance.proposal.asset.minProposerBalance`            |          |               |               |
|`governance.proposal.market.minVoterBalance`              |          |               |               |
|`governance.proposal.market.minProposerBalance`           |          |               |               |
|`governance.proposal.market.requiredParticipation`        |          |               |               |
|`governance.proposal.market.maxEnact`                     |          |               |               |
|`governance.proposal.updateMarket.maxEnact`               |          |               |               |
|`governance.proposal.updateMarket.minVoterBalance`        |          |               |               |
|`governance.proposal.updateMarket.requiredMajority`       | String   |               | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion              |
|`governance.proposal.updateMarket.minProposerBalance`     | String   |               | Minimum Governance token balance for proposals              |
|`governance.proposal.updateMarket.requiredParticipation`  |          |               |               |
|`governance.proposal.updateMarket.maxClose`               |          |               |               |
|`governance.proposal.updateMarket.minClose`               |          |               |               |
|`governance.proposal.updateNetParam.requiredParticipation`|          |               |               |
|`governance.proposal.updateNetParam.minClose`             |          |               |               |
|`governance.proposal.updateNetParam.maxEnact`             |          |               |               |
|`governance.proposal.updateNetParam.minEnact`             |          |               |               |
|`governance.proposal.updateNetParam.minVoterBalance`      |          |               |               |
|`governance.proposal.updateNetParam.minProposerBalance`   |          |               |               |
|`governance.proposal.asset.maxClose`                      |          |               |               |
|`governance.proposal.market.minClose`                     |          |               |               |
|`governance.proposal.market.requiredMajority`             |          |               |               |
|`governance.proposal.market.minEnact`                     |          |               |               |
|`governance.proposal.asset.requiredMajority`              |          |               |               |
|`governance.proposal.market.maxClose`                     |          |               |               |
|`governance.proposal.asset.minEnact`                      |          |               |               |
|`governance.proposal.updateMarket.minEnact`               |          |               |               |
|`governance.proposal.asset.minClose`                      |          |               |               |
|`governance.proposal.updateNetParam.requiredMajority`     |          |               |               |
|`governance.proposal.updateNetParam.maxClose`             |          |               |               |
|`governance.vote.asset`                                   |          |               |               |
|`market.stake.target.timeWindow`                          |          |               |               |
|`market.stake.target.scalingFactor`                       |          |               |               |
|`market.liquidity.providers.fee.distributionTimeStep`     |          |               |               |
|`market.liquidity.minimum.probabilityOfTrading.lpOrders`  |          |               |               |
|`market.liquidity.targetstake.triggering.ratio`           |          |               |               |
|`market.liquidity.probabilityOfTrading.tau.scaling`       |          |               |               |
|`market.monitor.price.updateFrequency`                    |          |               |               |
|`market.monitor.price.defaultParameters`                  |          |               |               |
|`market.value.windowLength`                               |          |               |               |
|`market.fee.factors.infrastructureFee`                    |          |               |               |
|`market.auction.maximumDuration`                          |          |               |               |
|`market.auction.minimumDuration`                          |          |               |               |
|`market.fee.factors.makerFee`                             |          |               |               |
|`market.liquidityProvision.shapes.maxSize`                |          |               |               |
|`market.liquidity.maximumLiquidityFeeFactorLevel`         |          |               |               |
|`market.margin.scalingFactors`                            |          |               |               |
|`market.liquidity.bondPenaltyParameter`                   |          |               |               |
|`market.liquidity.stakeToCcySiskas`                       |          |               |               |
