# Network Parameters

There are certain parameters within Vega that influence the behaviour of the system and must be able to be changed by on-chain governance. These parameters are called "network parameters" throughout the specs. This spec describes features of these parameters and how they may be changed by [governance](./0028-GOVE-governance.md).

## What is a network parameter?

A constant (or an array of constants) in the system whose values are able to be changed by on-chain governance. Not all constants are network parameters.

A network parameter is defined by:

- Name
- Type
- Value
- Constraints
- Governance update policy

### Name

- Editable by governance

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

Network parameters are able to be changed by [governance](./0028-GOVE-governance.md), however some network parameters need to be more difficult than others to change.

In some cases network parameters cannot be changed without a corresponding code change, in these cases any changes via governance would need to be submitted via a free form proposal as they are excluded from the protocol enacting the change on a successful governance vote. Those parameters are specified in [this file](https://github.com/vegaprotocol/vega/blob/develop/core/netparams/netparams.go) under the `updateDisallowed` list.

Therefore, Vega needs to know for each network parameter what governance thresholds should be applied for ascertaining a proposal to change the parameter's value. Specifically, these thresholds:

- proposal minimum close period
- proposal maximum close period
- proposal minimum enactment period
- proposal maximum enactment period
- proposal required participation to pass
- proposal required majority to pass
- proposal minimum proposer balance
- proposal minimum voter balance

There are groups of network parameters that will use the same values for the thresholds. The parameters can be set for the following groups:

- governance market proposal
- governance asset proposal
- governance update market proposal
- governance update asset proposal
- governance update network parameter proposal
- governance freeform proposal (with the exception of enactment periods)

Importantly, these Minimum Levels are themselves network parameters, and therefore subject to change. They should be self referential in terms of ascertaining the success of changing them.

For example, consider a network parameter that specifies the proportion of fees that goes to market makers (`MarketFeeFactorsMakerFee`), with change thresholds:

- `GovernanceProposalUpdateNetParamMinClose` = 30 days
- `GovernanceProposalUpdateNetParamMinEnact` = 10 days
- `GovernanceProposalUpdateNetParamRequiredParticipation` = 60%
- `GovernanceProposalUpdateNetParamRequiredMajority` = 80%
- `GovernanceProposalUpdateNetParamMinProposerBalance` = 100 (of the governance token)
- `GovernanceProposalUpdateNetParamMinVoterBalance` = 10 (of the governance token)

Then a proposal that attempted to change the `market.fee.factors.makerFee` would need to pass all of the thresholds listed above. It would have to run for 30 days, would be enacted 10 days after a sucessful vote.. etc.

## Data to Expose

The full list of network parameters must be available to the governance community. All proposals to change a network parameter should be easily discoverable.

## Current network parameters

The network parameter spec-name to name-in-vega-core mapping is found in the core [keys](https://github.com/vegaprotocol/vega/blob/develop/core/netparams/keys.go) file.

The current network parameters are specified in the code specifiying the min and max value ranges and the default values. The parameters and related values can be seen in the [defaults](https://github.com/vegaprotocol/vega/blob/develop/core/netparams/defaults.go) file in the core repository.

## Acceptance criteria

- All network parameter set in `genesis.json` can be queried and the values returned are the correct ones (unless overridden by [LNL checkpoint](./0073-LIMN-limited_network_life.md) value). (<a name="0054-NETP-001" href="#0054-NETP-001">0054-NETP-001</a>)(<a name="0054-SP-NETP-001" href="#0054-SP-NETP-001">0054-SP-NETP-001</a>)
- For `blockchains.ethereumConfig` set in `genesis.json` a governance proposal to change this parameter will be rejected with a rejection error `network parameter update disabled for blockchains.ethereumConfig`. (<a name="0054-NETP-002" href="#0054-NETP-002">0054-NETP-002</a>)(<a name="0054-SP-NETP-002" href="#0054-SP-NETP-002">0054-SP-NETP-002</a>)
- For `market.margin.scalingFactors` set in `genesis.json` or in a governance proposal we validate the format and the fact that "1.0 <= search <= initial <= release"; if these are invalid a useful error is returned. (<a name="0054-NETP-003" href="#0054-NETP-003">0054-NETP-003</a>)
- For `market.monitor.price.defaultParameters` set in `genesis.json` or in a governance proposal we validate the format; if these are invalid a useful error is returned. (<a name="0054-NETP-004" href="#0054-NETP-004">0054-NETP-004</a>)(<a name="0054SP--NETP-004" href="#0054-SP-NETP-004">0054-SP-NETP-004</a>)
- For each of the remaining parameter whether set in `genesis.json` or in a governance proposal we validate the data type, reject invalid and validate the range of allowable values; if these are invalid a useful error is returned. (<a name="0054-NETP-005" href="#0054-NETP-005">0054-NETP-005</a>)(<a name="0054-SP-NETP-005" href="#0054-SP-NETP-005">0054-SP-NETP-005</a>)
- All network parameter ranges, as specified in the [defaults](https://github.com/vegaprotocol/vega/blob/develop/core/netparams/defaults.go) file, are not able to be set less or greater than the range bondaries. (<a name="0054-NETP-006" href="#0054-NETP-006">0054-NETP-006</a>)(<a name="0054-SP-NETP-006" href="#0054-SP-NETP-006">0054-SP-NETP-006</a>)
