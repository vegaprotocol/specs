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
| Name                                                     | Type     | Specification | Description                                                 |
|----------------------------------------------------------|:--------:|---------------|-------------------------------------------------------------|
|`market.liquidity.minimum.probabilityOfTrading.lpOrders`  |          |               |               |
|`market.liquidity.targetstake.triggering.ratio`           |          |               |               |
|`governance.proposal.market.requiredParticipation`        |          |               |               |
|`governance.proposal.updateMarket.requiredMajority`       | String   |               | 'Yes' votes must outnumber 'No' votes on this proposal by this proportion              |
|`governance.proposal.updateMarket.minProposerBalance`     | String   |               | Minimum Governance token balance for proposals              |
|`market.stake.target.timeWindow`                          |          |               |               |
|`governance.proposal.market.minVoterBalance`              |          |               |               |
|`governance.proposal.market.minProposerBalance`           |          |               |               |
|`governance.proposal.updateMarket.minVoterBalance`        |          |               |               |
|`market.liquidity.providers.fee.distributionTimeStep`     |          |               |               |
|`governance.proposal.asset.minProposerBalance`            |          |               |               |
|`governance.proposal.updateMarket.maxEnact`               |          |               |               |
|`market.stake.target.scalingFactor`                       |          |               |               |
|`governance.proposal.updateNetParam.minVoterBalance`      |          |               |               |
|`market.monitor.price.updateFrequency`                    |          |               |               |
|`governance.proposal.updateNetParam.minClose`             |          |               |               |
|`governance.proposal.updateMarket.maxClose`               |          |               |               |
|`governance.proposal.updateNetParam.minEnact`             |          |               |               |
|`blockchains.ethereumConfig`                              |          |               |               |
|`governance.proposal.asset.requiredParticipation`         |          |               |               |
|`market.liquidity.probabilityOfTrading.tau.scaling`       |          |               |               |
|`governance.proposal.market.maxEnact`                     |          |               |               |
|`market.value.windowLength`                               |          |               |               |
|`market.fee.factors.infrastructureFee`                    |          |               |               |
|`governance.proposal.asset.maxEnact`                      |          |               |               |
|`governance.proposal.asset.minVoterBalance`               |          |               |               |
|`governance.vote.asset`                                   |          |               |               |
|`market.auction.maximumDuration`                          |          |               |               |
|`governance.proposal.updateNetParam.maxEnact`             |          |               |               |
|`market.monitor.price.defaultParameters`                  |          |               |               |
|`governance.proposal.updateMarket.requiredParticipation`  |          |               |               |
|`market.liquidityProvision.shapes.maxSize`                |          |               |               |
|`governance.proposal.updateNetParam.minProposerBalance`   |          |               |               |
|`governance.proposal.asset.maxClose`                      |          |               |               |
|`market.fee.factors.makerFee`                             |          |               |               |
|`governance.proposal.updateNetParam.requiredParticipation`|          |               |               |
|`market.liquidity.maximumLiquidityFeeFactorLevel`         |          |               |               |
|`governance.proposal.updateMarket.minClose`               |          |               |               |
|`market.auction.minimumDuration`                          |          |               |               |
|`governance.proposal.market.minClose`                     |          |               |               |
|`governance.proposal.market.requiredMajority`             |          |               |               |
|`governance.proposal.market.minEnact`                     |          |               |               |
|`governance.proposal.asset.requiredMajority`              |          |               |               |
|`governance.proposal.market.maxClose`                     |          |               |               |
|`governance.proposal.asset.minEnact`                      |          |               |               |
|`governance.proposal.updateMarket.minEnact`               |          |               |               |
|`governance.proposal.asset.minClose`                      |          |               |               |
|`governance.proposal.updateNetParam.requiredMajority`     |          |               |               |
|`market.margin.scalingFactors`                            |          |               |               |
|`market.liquidity.bondPenaltyParameter`                   |          |               |               |
|`governance.proposal.updateNetParam.maxClose`             |          |               |               |
|`market.liquidity.stakeToCcySiskas`                       |          |               |               |
