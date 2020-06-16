# Governance

Governance allows the vega network to arrive at on-chain decisions. Implementing this specification will provide a simple framework for users to create proposals involving Markets or the network in general, by creating new markets,
or updating a market parameter, or network parameters.

Ideally this would provide a very simple framework allowing users to:
 - Create a proposal
 - Vote on a proposal

In this document, a "user" refers to a "party" on a Vega network.

# Future work
This version of the specification covers governance of data within the network. 

Not covered is proposal rate limiting, spam protection or fees related to proposals. 

# Guide-level explanation

Governance actions enable users to make proposals for changes on the network or vote for existing proposals. Proposals should be able to cover multiple aspects of the vega protocol:

1. Creation of a market
1. Edit market parameters
1. Edit network parameters

## Lifecycle of a proposal
1. Governance proposal is submitted to the network.
1. The network validates the proposal.
1. If valid, the network holds the proposal active for a proposal period.
1. During the proposal period, network participants who are eligible to vote on the proposal may submit votes for or against the proposal.
1. The network calculates the outcome.

Any actions that result from the outcome of the vote are covered in other spec files.

## Voting weights

For on-chain voting mechanisms, the weighting of a vote can be based off:

1. The amount of a particular token that a participant holds
1. The amount of financial stake or bond that a participant has placed on the network 
1. The amount of some other internally calculated number specific to a participant (e.g. the size of their open positions on a particular market). See note below.

The governance system must be generic in term of weighting of the vote for a given proposal, the first implementation will start with _the amount of a particular token that a participant holds_ but this must be subject to configuration in the future.

Initially the weighting will be based on the amount of the configured governance token that the user has on the network as determined by their balance of this token as a percentage of the total issued supply of that token. 1 token represents 1 vote (0.0001 tokens represents 0.001 votes, etc.). A user with 0 tokens cannot vote, ideally this would be enforced before scheduling the voting transaction in a block.

The governance token used for calculating voting weight must be an asset that is configured within the asset framework in Vega (this could be a "Vega native" asset on some networks or an asset deposited via a bridge, i.e. an ERC20 on Ethereum.) This means that the asset framework will *always* need to be able to support pre-configured assets (the configuration of which must be the same on every node) in order to bootstrap the governance system. The governance asset configuration will be different on different Vega networks, so this cannot be hard coded.

Note: in future, some or all proposals for changes to a market will be weighted by a measure of participation in that market. The most likely way this would be calculated would be by the size of the voter's market making commitment vs. the total committed in the market (and participation ratios would be calculated from the same), although we may also consider metrics like the voter's share of traded volume over, say, the voting period or some other algorithm. Importantly this means a voter's weighting will vary between markets for these types of decision.

## Voting for a proposal

Users of the vega platform will be able to vote for or against a proposal, if they hold an eligible amount of the voting weight.
This action is binary:
 - a user can either say yes to a proposal
 - or no

A user can vote as many times as needed, only the last vote will be accounted for in the final decision for the proposal.

The amount of voting weight that a user is considered to be voting with is the amount they hold, as measured by the network, at the conclusion of the proposal period - as part of calculating the vote outcome. For example, if a user votes "yes" for a proposal and then adds to their governance token balance after submitting their vote (and prior to the end of the proposal period), their new balance of voting asset is the one used.


## Restriction on who can create a proposal
In a first implementation anyone will be able to create a proposal if the weighting of their vote on the proposal would be >0 (e.g. if they have more than 0 of the relevant governance token).

In future iteration of the governance system we expect to be able to restrict which users can create a specific type of proposal. The restriction would be applied based on the weighting required by the proposal. e.g: only user with 5k vega tokens are allowed to open a "network parameter change" proposal.

## Configuration of a proposal
When a proposal is created, it can be configured in multiple ways. 

### Duration of the proposal
A new proposal will have a close date specified as a timestamp. After the proposal is created in the system and before the close date, the proposal is open for votes.
e.g: A proposal is created and people have 3 weeks from the day it is sent to the network in order to submit votes for it.

The proposal's close date may optionally be set by the proposer and must be greater than or equal to a minimum duration time that is set by the network. The network will specify minimum duration times depending on the type of proposal. 

The network's _minimum proposal duration time_ - as specified by a network parameter relevant to the proposal type - is used as the default when the new proposal either fails to include a minimum proposal duration time or the proposal is submitted with a close date would fail to meet the network's minimum proposal duration time constraint.

### When a proposal is enacted
A new proposal can also specify when any changes resulting from a successful vote would start to be applied.
e.g: A new proposal is created in order to create a new market with a 1 week enactment date. After 3 weeks the proposal is closed (the duration of the proposal), and if there is enough votes to accept the new proposal, then the changes will be applied in the network 1 week later.
This would allow enough time for the operator to be ready for the changes, e.g in the case the proposal is to decide to use a new version of the vega node, or something available only in a later version of the node.

Proposals are enacted in the order they were created. This means that in the case that two proposals change the same parameter in roughly the same period, the oldest proposal will be applied first and the newest will be applied last. There is no attempt to resolve differences between the two.

The network's _minimum time between vote closing and enactment_ - as specified by a network parameter relevant to the proposal type is used to validate whether the enactment date is acceptable.

## Editing and/or cancelling a proposal is not possible
A proposal cannot be edited, once created. The only possible action is to vote for or against a proposal. We would expect amending a proposal to be made by creating a new proposal.
e.g: I create a proposal for a new market using ETH as an asset. Later on I decide it would be better to use BTC, the solution
will be to create a new proposal, to change this specific parameter on the market definition.

There will be no explicit link between the first proposal and the replacement one.

## Outcome
At the conclusion of the voting period the network will calculate the sum of vote weightings of *valid* 'Yes' votes, divided by the sum of vote weightings for all valid votes cast for the proposal.

If this amount is greater than or equal to the minimum majority amount required for this proposal, then the vote is considered to be successful. Note, the network will specify minimum majority amounts depending on the type of proposal.

If this "yes" result is greater than the 

Not in scope: minimum percentage of participation. e.g: require 80% of users who vote to vote yes and 90% of the _active_ users of the vega network have to take part in the vote.

# Reference-level explanation

We introduce 2 new commands which require consensus (needs to go through the chain)

- create a proposal.
- vote for a given proposal.

## Types of proposals

We allow users to create proposals covering 4 domains:

1. Creation of a market
1. Edit market parameters
1. Edit network parameters

We have proposed the set of network parameters that will be utilised by each type of  proposal. However, in the future, different sub-types of these categories may reference different sets of (or specific) network parameters. For example, amending a long-running liquid market may have different network parameter requirements to a smaller, short term market.

## 1. Creation or amending of a market

All **new market proposals** will reference a set of shared network parameters:

* `NetworkParameters.Governance.Markets.New.MinimumProposalPeriod` [default]
* `NetworkParameters.Governance.Markets.New.MinimumRequiredParticipation` [always used]
* `NetworkParameters.Governance.Markets.New.MinimumRequiredMajority` [always used]

All **market amend proposals** will reference a set of shared network parameters:
* `NetworkParameters.Governance.Markets.Amend.MinimumProposalPeriod` [default]
* `NetworkParameters.Governance.Markets.Amend.MinimumRequiredParticipation` [always used]
* `NetworkParameters.Governance.Markets.Amend.MinimumRequiredMajority` [always used]


## 2. Edit market parameters

In future when there are multiple products, parameters that can be changed via governance will be defined individually for the product.

For now, proposals to update market parameters are limited to the following:

| Field                                                 | Y/N | Specifics                                                                               |
|-------------------------------------------------------|-----|-----------------------------------------------------------------------------------------|
| Market.TradingMode                                    | Y   | Both the trading mode itself, and the individual fields                                 |
| Market.TradableInstrument.RiskModel                   | Y   | Both the entire risk model, and individual params of the risk model (needs spec!)       |
| Market.TradableInstrument.MarginCalculator            | Y   | Updating all scaling factors is possible                                                |
| Market.TradableInstrument.Instrument.Code             | Y   | Updating the descriptive name                                           |                                              |
| Market.Status            | Y   | Including for closing or suspending a market                                                |                                              |

Add category/subtype: "Trading" (mode and status), others under instrument

For version 1 of governance, all trading parameters should reference the following network parameters:
* `NetworkParameters.Governance.Market.Trading.MinimumProposalPeriod` [default]
* `NetworkParameters.Governance.Market.Trading.MinimumRequiredParticipation` [always used]
* `NetworkParameters.Governance.Market.Trading.MinimumRequiredMajority` [always used]

For version 1 of governance, all instrument parameters should reference the following network parameters:
* `NetworkParameters.Governance.Market.Instrument.MinimumProposalPeriod` [default]
* `NetworkParameters.Governance.Market.Instrument.MinimumRequiredParticipation` [always used]
* `NetworkParameters.Governance.Market.Instrument.MinimumRequiredMajority` [always used]

In future, we may define separate network parameters depending on either:
1. The type of parameter that is the subject of the change proposal.
1. A set of rules that specify which parameter would be used according to a set of conditions - such as, whether or not the market is active or not (e.g. if a market has been trading for some time, suddenly changing the risk factors and scaling factors is risky, less so if the market is not active yet).

## 4. Edit network parameters


For version 1 of governance, all network parameter change proposals should reference the following network parameters:

* `NetworkParameters.Governance.Network.<Type>.MinimumProposalPeriod` [default]
* `NetworkParameters.Governance.Network.<Type>.MinimumRequiredParticipation` [always used]
* `NetworkParameters.Governance.Network.<Type>.MinimumRequiredMajority` [always used]

In the future, the network parameter framework will specify the Type.

All network parameters may at some point be assigned individual network parameters that govern a particular change to themselves.

Note

`NetworkParameters.Governance.Network.<Type = governance>.MinimumProposalPeriod` control changing the minimum proposal periods.. Barney to complete.


## APIs

We expect the user to be able to do the following actions by using the core APIs:
 - list all the open proposals on the network
 - vote for a given proposal
 - get the results for a given proposal
 - get a list of proposals a user voted for
 - a notification system in order to be notified of new proposal requiring attention

# Pseudo-code / Examples

Possible implementation of the Proposal format (protobuf):
```
enum ProposalKind {
	Market = 1;
	NetworkParam = 2;
	// ...
}

message Proposal {
	ProposalKind kind = 1;
	oneof Data {
		vega.Market market = 2;
		string networkParam = 3;
	}
	int64 winThreshold = 4;
	int64 openUntil = 5;
	int64 takeEffectOn = 6;
}
```

Possible implementation for a vote
```
enum VoteChoice {
	Yes = 1;
	No = 2;
}

message Vote {
	string partyID = 1;
	string proposalID = 2;
	VoteChoice choice = 3;
}
```

# Acceptance Criteria

- [ ] As a user, I can create a new proposal to affect the vega network
- [ ] As a user, I can list the open proposal on the network
- [ ] As a user, I can get a list of all proposals I voted for
- [ ] As a user, I can receive notification when a new proposal is created and may require attention.
- [ ] As the vega network, all the votes for an existing proposal are accepted when the proposal is still open
- [ ] As the vega network, all votes received are rejected once the proposal voting period is finished
- [ ] As the vega network, once the voting period is finished, I validate the result based on the parameters of the proposal used to decide the outcome of it.
- [ ] As the vega network, if a proposal is accepted and the duration required before change takes effect is reached, the changes are applied
- [ ] As the vega network, proposals that close less than 2 days from enactment are rejected as invalid
- [ ] As the vega network, proposals that close moreless than 1 year from enactment are rejected as invalid

## Using Vega governance tokens as voting weight:
- [ ] As a user, I can vote for an existing proposal if I have more than 0 governance tokens
- [ ] As a user, my vote for an existing proposal is rejected if I have 0 governance tokens

## Future criteria, once a new weighting method is introduced?
- [ ] As a user, I can understand which voting weighting methodology a proposal requires

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
