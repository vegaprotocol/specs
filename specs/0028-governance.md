Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary

Governance allows token-owning users of the vega network to make on-chain decisions. Implementing this specification will provide a simple framework for users to create proposals involving Markets or the network in general, by creating new markets,
or updating a market parameter, or network parameters.

Ideally this would provide a very simple framework allowing users to:
 - Create a proposal
 - Vote on a proposal

In this document, a "user" refers to a "party" on a Vega network.

# Future work
This version of the specification covers governance of data within the network. It does not cover changes to network level parameters such as validator sets, block duration or configuration file updates, which will be supported in the future.

Also not covered is proposal rate limiting, spam protection or fees related to proposals. 

Dependencies between proposals and their impact on voting needs to be clarified in the network proposal spec.

Proposals to upate market parameters are limited to the following:

| Field                                                 | Y/N | Specifics                                                                               |
|-------------------------------------------------------|-----|-----------------------------------------------------------------------------------------|
| Market.Name                                           | Y   | provisionally                                                                           |
| Market.TradingMode                                    | Y   | Both the trading mode itself, and the individual fields                                 |
| Market.TradableInstrument.Instrument.Product.Maturity | Y   | This determins the EOL of a market, this field might need to be moved to a higher level |
| Market.TradableInstrument.RiskModel                   | Y   | Both the entire risk model, and individual params of the risk model (needs spec!)       |
| Market.TradableInstrument.MarginCalculator            | Y   | Updating all scaling factors is possible                                                |

For a number of these parameters, different rules need to be specified depending on whether or not the market is active or not (e.g. if a market has been trading for some time, suddenly changing the risk factors and scaling factors is risky, less so if the market is not active yet).

# Guide-level explanation

Governance enable users to make proposals for changes on the network or vote for existing proposals. Proposals should be able to cover multiple aspect of the vega protocol:
 - create a new market
 - change parameters of an existing market (e.g: change some settings of a risk model for a given market)

In future, we will also add:
 - update parameters of the network itself (e.g: duration of a block)

## Configuration of a proposal
When a proposal is created, it can be configured in multiple ways. Depending on the type of proposal, restrictions on the fields in the proposal can be set.
i.e. A proposal of type new market might have a minimum participation level set at 50% so the user can only choose the values 50->100% for the participation field.

### Decision weighting
The governance system must be generic in term of weighting of the vote for a given proposal, the first implementation will start with a few options (or one) for weighting but this must be subject to configuration in the future.
Initially the weighting will be based on the amount of stake the user has on the network as determined by their balance of the  configured governance token as a percentage of the total issued supply of that token. 1 token represents 1 vote (0.0001 tokens represents 0.001 votes, etc.). A user with 0 tokens cannot vote, ideally this would be enforced before scheduling the voting transaction in a block.

The governance token used for calculating voting weight must be an asset that is configured within the asset framework in Vega (this could be a "Vega native" asset on some networks or an asset deposited via a bridge, i.e. an ERC20 on Ethereum.) This means that the asset framework will *always* need to be able to support pre-configured assets (the configuration of which must be the same on every node) in order to bootstrap the governance system. The governance asset configuration will be different on different Vega networks, so this cannot be hard coded.

Note on future requirement:

 - In future, some or all proposals for changes to a market will be weighted by a measure of participation in that market. The most likely way this would be calculated would be by the size of the voter's market making commitment vs. the total committed in the market (and participation ratios would be calculated from the same), although we may also consider metrics like the voter's share of traded volume over, say, the voting period or some other algorithm. Importantly this means a voter's weighting will vary between markets for these types of decision.

### How the success of a proposal is defined
For the proposal to be accepted, a number of positive votes will be required.
This is something which can be defined at the creation of the proposal.

First the win can be defined by a percentage of positive votes:
e.g: the proposal require 80% of the users who vote to vote yes to be accepted.

Not in scope: minimum percentage of participation. e.g: require 80% of users who vote to vote yes and 90% of the _active_ users of the vega network have to take part in the vote.

### Duration of the proposal
When a proposal is created, it will be configured with a variable end date, until then the proposal is open for votes.
e.g: A proposal is created and people have 3 weeks from the day it is sent to the network in order to submit votes for it.

### When changes are applied
The proposals can also be parameterised about when the change which are voted for will start to be applied.
e.g: A new proposal is created in order to create a new market, after 3 weeks the proposal if closed, if there is enough votes  to accept the new proposal, then the changes will be applied in the network 1 week later.
This would allow enough time for the operator to be ready for the changes, e.g in the case the proposal is to decide to use a new version of the vega node, or something available only in a later version of the node.

Proposals are applied in the order they were created. This means that in the case that two proposals change the same parameter in roughly the same period, the oldest proposal will be applied first and the newest will be applied last. There is no attempt to resolve differences between the two.

## Restriction on who can create a proposal
In a first implementation anyone will be able to create a proposal if the weighting of their vote on the proposal would be >0 (i.e. has more than 0 tokens).

In future iteration of the governance system we expect to be able to restrict which users can create a proposal.
The restriction would be applied based on the weighting required by the proposal.
e.g: only user with a stack of 5k vega token are allowed to open a new proposal.

## Editing a proposal is not possible
A proposal cannot be edited, once created the only thing which would be possible would be to vote for or against a proposal. We would expect amending a proposal to be made by creating a new proposal.
e.g: I create a proposal for a new market using ETH as an asset. Later on I decide it would be better to use BTC, the solution
will be to create a new proposal, to change this specific parameter on the market definition.

There will be no explicit link between the first proposal and the replacement one.

## Vote for a proposal
Users of the vega platform will be able to vote for or against a proposal, assuming they have more than 0 tokens.
This action is binary:
 - a user can either say yes to a proposal
 - or no

A user can vote as many times as needed, only the last vote will be accounted for in the final decision for the proposal.

## Outcome
The result of a proposal is calculated as a sum of vote weightings of *valid* 'Yes' votes, divided by the sum of vote weightings for all valid votes cast for the proposal.

# Reference-level explanation

We introduce 2 new commands which require consensus (needs to go through the chain)

- create a proposal.
- vote for a given proposal.

## Types of proposals

We allow users to create proposals covering 3 domains:

1. Creation or amending of a market (market framework)
2. Close or suspend an existing market
3. Edit network parameters

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
- [ ] As a user, I can vote for an existing proposal if I have more than 0 tokens
- [ ] As a user, My vote for an existing proposal is rejected if I have 0 tokens
- [ ] As a user, I can list the open proposal on the network
- [ ] As a user, I can get a list of all proposal I voted for
- [ ] As a user, I can receive notification when a new proposal is created and may require attention.
- [ ] As the vega network, all the votes for an existing proposal are accepted when the proposal is still open
- [ ] As the vega network, all vote received are rejected once the proposal voting period is finished
- [ ] As the vega network, once the voting period is finished, I validate the result based on the parameters of the proposal used to decide the outcome of it.
- [ ] As the vega network, if a proposal is accepted and the duration required before change takes effect is reached, the changes are applied

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
