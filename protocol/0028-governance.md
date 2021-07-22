# Governance

Governance allows the vega network to arrive at on-chain decisions. Implementing this specification will provide the ability for users to create proposals involving Markets or the network in general, by creating new markets, or updating a market or network parameter.

This is achieved by creating a simple protocol framework for the creation, approval/rejection, and enactment of governance proposals. Where a _proposal_ comprises a supported governance action and metadata that determines the conditions and timing for it's enactment.

To implement this framework, two new transactions must be supported by the Vega core:
 - Submit Proposal: deploy a new (valid) proposal to the network
 - Vote: record a vote for or against a live proposal

In this document, a "user" refers to a "party" (private key holder) on a Vega network.


# Guide-level explanation

Governance actions enable users to make proposals for changes on the network or vote for existing proposals. The allowable types of change to be proposed are known as "governance actions". In future, enactment of governance actions may also be possible by other means (for example, automatically by the protocol in response to certain conditiouns), which should be kept in mind during implementation.

The type of governance action are:

1. Create market
1. Change market parameters
1. Change network parameters
1. Add external asset to Vega (covered in a [separate spec - see 0027](./0027-asset-proposal.md))
1. Authorise a transfer to or from the [Network Treasury](TODO: LINK)

## Lifecycle of a proposal

Note: there are some differences/additional points for market creation proposals, see the section on market creation below.

1. Governance proposal is accepted by the network as a transaction.
1. The nodes validate the proposal. Note: this is where the network parameters that validate the minimum duration, minimum to to enactment, minimum participation rate, and required majority are evaluated. The proposal is not revalidated. This is also where, if not specified on the proposal, the required participation rate and majority for success are defined and copied to the proposal. The proposal is immutable once entered and future parameter changes don't impact it (this is to prevent surprising behaviour where other proposals with as yet unknown outcomes can impact the success of a proposal).
1. If valid, the the proposal is considered "active" for a proposal period. This period is defined on the proposal and must be at least as long as the minimum duration for the proposal type/subtype (specified by a network parameter)
1. During the proposal period, network participants who are eligible to vote on the proposal may submit votes for or against the proposal.
1. When the proposal period closes, the network calculates the outcome by:
    - comparing the total number of votes cast as a percentage of the number eligible to be cast to the minimum participation requirement (if the minimum is not reached, the proposal is rejected)
		- comparing the number of positive votes as a percentage of all votes cast (maximum one vote counted per party) to the required majority. 
1. If the required majority of "for" votes was met, the action described in the proposal will be taken (proposal is enacted) on the enactment date, which is defined by the proposal and must be at least the minimum enactment period for the proposal type/subtype (which is specified by a network parameter) _after_ voting on the proposal closes.

Any actions that result from the outcome of the vote are covered in other spec files.

## Governance Asset
The Governance Asset is the on-chain [asset](./0040-asset-framework.md) representing the [token configured in the staking bridge](./../non-protocol-specs/0006-erc20-governance-token-staking.md). Users with a staking account balance in the governance asset can:

- [Create proposals](#restriction-on-who-can-create-a-proposal)
- [Vote on proposals](#voting-for-a-proposal)
- [Delegate to validators](./0059-simple-staking-and-delegating.md)

## Governance weighting
A party on the Vega network will have a weighting for each type of proposal that determines how strongly their vote counts towards the final result. 

To submit a proposal the party has to have more (strictly greater) than a minimum set by a network parameter `governance.proposal.market.minProposerBalance` deposited on the Vega network (the network parameter sets the number of tokens). The minimum valid value for this parameter is `0`. 

Weighting will initially be determined by the sum of the locked and staked token balances on the [staking bridge](../non-protocol-specs/0004-staking-bridge.md).

In future, governance weighting for some proposal types will be based on alternative measures, such as:

1. The amount of market making bond that a participant has placed with the network for a specific market, or in total.
1. The value of some other internally calculated number specific to a participant (e.g. the size of their open positions on a particular market). See note below.

The governance system must be generic in term of weighting of the vote for a given proposal. As noted above, the first implementation will start with _the amount of a particular token that a participant holds_ but this will be extended in the near future, as additional protocol features and governance actions are added.

Initially the weighting will be based on the amount of the configured governance asset that the user has on the network as determined *only* by their staking account balance of this asset. 1 token represents 1 vote (0.0001 tokens represents 0.0001 votes, etc.). A user with a balance of 0 cannot vote or submit a proposal of that type, and ideally this would be enforced in a check _before_ scheduling the voting transaction in a block.

The governance token used for calculating voting weight must be an asset that is configured within the asset framework in Vega (this could be a "Vega native" asset on some networks or an asset deposited via a bridge, i.e. an ERC20 on Ethereum). Note: this means that the asset framework will _always_ need to be able to support pre-configured assets (the configuration of which must be verifiably the same on every node) in order to bootstrap the governance system. The governance asset configuration will be different on different Vega networks, so this cannot be hard coded.

Note: in future, some or all proposals for changes to a market will be weighted by a measure of participation in that market. The most likely way this would be calculated would be by the size of the voter's market making commitment or vs. the total committed in the market (and participation ratios would be calculated from the same), although we may also consider metrics like the voter's share of traded volume over, say, the voting period or some other algorithm. _Importantly this means a voter's weighting will vary between markets for these types of proposal._


## Voting for a proposal

Users of the vega platform will be able to vote for or against a proposal, if they have an eligible (non-zero) voting weight. A user may choose whether or not to vote. If a user votes, the action is binary: they may either vote **for the proposal** or **against the proposal**, and this will apply to their full weighting.

A user can vote as many times as needed, only the last vote will be accounted for in the final decision for the proposal. We do not consider prevention of spam/DOS attacks by multiple voting in this spec, though they will need to be covered (potentially by a fee and/or proof of work cost).

The amount of voting weight that a user is considered to be voting with is the full amount they hold, as measured by the network, **at the conclusion of the proposal period** - as part of calculating the vote outcome. For example, if a user votes "yes" for a proposal and then adds to or withdraws from (including via movements to and from margin accounts for trading the asset) their governance token balance after submitting their vote and prior to the end of the proposal period, their new balance of voting asset is the one used. (Note: this may change in future, if it is deemed to allow misleading or exploitative voting behaviour. Particularly, we may lock the balance from being withdrawn or used for trading for the duration of the vote, once a participant has voted.)


## Restriction on who can create a proposal

Anyone can create a proposal if the weighting of their vote on the proposal would be >0 (e.g. if they have more than 0 of the relevant governance token).

In a future iteration of the governance system we may restrict proposal submission by type of proposal based on a minimum weighting. e.g: only user with a certain number or percentage of the governance asset are allowed to open a "network parameter change" proposal.


## Configuration of a proposal

When a proposal is created, it can be configured in multiple ways. 


### Duration of the proposal

A new proposal will have a close date specified as a timestamp. After the proposal is created in the system and before the close date, the proposal is open for votes. e.g: A proposal is created and people have 3 weeks from the day it is sent to the network in order to submit votes for it.

The proposal's close date may optionally be set by the proposer and must be greater than or equal to a minimum duration time that is set by the network. Minimum duration times will be specified as network parameters depending on the type of proposal. 

The network's _minimum proposal duration_ - as specified by a network parameter specific to each proposal type - is used as the default when the new proposal does not include a proposal duration. If a proposal is submitted with a close date would fail to meet the network's minimum proposal duration time constraint, the proposal must be rejected.


### When a proposal is enacted

Note: market creation proposals are handled slightly differently, see below

A new proposal can also specify when any changes resulting from a successful vote would start to be applied. e.g: A new proposal is created in order to create a new market with an enactment date 1 week after vote closing. After 3 weeks the proposal is closed (the duration of the proposal), and if there are enough votes to accept the new proposal, then the changes will be applied in the network 1 week later.

This allows time for users to be ready for changes that may effect them financially or technically, e.g in the case the proposal is to decide to use a new version of the vega node, or something available only in a later version of the node, or a change that might increase capital requirements for positions significantly and thus could trigger close-outs. It also allows markets to be pre-approved early and launched at a chosen time in the future.

Proposals are enacted by timestamp, earliest first, as soon as the enactment time is reached by the network (i.e. "Vega time"). Proposals sharing the same exact enactment time are enacted in the order they were created. This means that in the case that two proposals change the same parameter with the same timestamp, the oldest proposal will be applied first and the newest will be applied last, overwriting the change made by the older proposal. There is no attempt to resolve differences between the two.

The network's _minimum pre-enactment period_ - as specified by a network parameter specific to each proposal type is used to validate whether the enactment date is acceptable.


## Editing and/or cancelling a proposal is not possible

A proposal cannot be edited, once created. The only possible action is to vote for or against a proposal, or submit a new proposal. 

If a proposal is created and later a different outcome is preferred by network participants, two courses of action are possible:

1. Vote against the proposal and create a new proposal with the correct change
1. Vote for or against the proposal and create a new proposal for the additional change

Which of these makes most sense will depend on the type of change, the timing of the events, and how the rest of the community votes for the initial proposal.


## Outcome

At the conclusion of the voting period the network will calculate two values:

1. The participation rate: `participation_rate = SUM ( weightings of ALL valid votes cast ) / max total weighting possible` (e.g. sum of token balances of all votes cast / total supply of governance asset, this implies that for this version it is only possible to use an asset with **fixed supply** as the governance asset)
1. The "for" rate: `for_rate = SUM ( weightings of votes cast for ) / SUM ( weightings of all votes cast )`

The proposal is considered successful and will be enacted if:

- The `participation_rate` is greater than or equal to the minimum participation rate for the proposal
- The `for_rate` is greater than or equal to the minimum required majority for the proposal
- The `participation rate` is calculated against the *total supply of the governance asset*.

Note: see below for details on minimum participation rate and minimum required majority, which are defined by type of governance action, and in some cases a category or sub-type.

Not in scope: minimum participation of active users, i.e. 90% of the _active_ users of the vega network have to take part in the vote. Minimum participation is currently always measured against the total possible participation.


# Reference-level explanation

We introduce 2 new commands which require consensus (needs to go through the chain)

- submit a proposal.
- vote for a given proposal.


## Types of proposals

## 1. Create market

This action differs from from other governance actions in that the market is created and some transactions (namely around liquidity provision) may be accepted for the market before the proposal has successfully passed. The lifecycle of a market and its triggers are covered in the [market lifecycle](./0043-market-lifecycle.md) spec.

Note the following key points from the market lifecycle spec:
* A market is created in Proposed status as soon as the proposal is accepted
* A market enters a Pending status as soon as the proposal is Successful (before enactment)
* A market usually enters Active status at the proposal's enactment date/time, but some conditions may delay this or cause the market to be Cancelled instead

A proposal to create a market contains 
1. a complete market specification as per the Market Framework (see spec) that describes the market to be created. 
1. a liquidity provision commitment via LP commitment data structure, specifying stake amount, fee bid, plus buy and sell shapes [see lp-mechanics](0044-lp-mechanics.md). The proposal must be rejected if the liquidity provision commitment is invalid or the proposer does not have the required collateral for the stake.
The stake commitment must exceed the `minimum_proposal_stake_amount` which is a per-asset parameter.
1. an enactment time that is at least the *minimum auction duration* after the vote closing time (see [auction spec](./0026-auctions.md))

All **new market proposals** initially have their validation configured by the network parameters `Governance.CreateMarket.All.*`. These may be split from `All` to subtypes in future, for instance when other market types like RFQ are created.


## 2. Change market parameters

[Market parameters](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0001-market-framework.md#market) that may be changed are described in the spec for the Market Framework, and additionally the specs for the Risk Model and Product being used by the market. See the [Market Framework spec](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0001-market-framework.md#market) for details on these parameters, including those that cannot be changed and the category of the parameters.

All **change market parameter proposals** have their validation configured by the network parameters `Governance.UpdateMarket.<CATEGORY>.*`, where `<CATEGORY>` is the category assigned to the parameter in the Market Framework spec.


## 3. Change network parameters

[Network parameters](./0054-network-parameters.md) that may be changed are described in the *Network Parameters* spec, this document for details on these parameters, including the category of the parameters. New network parameters require a code change, so there is no support for adding new network parameters.

All **change network parameter proposals** have their validation configured by the network parameters `Governance.UpdateNetwork.<CATEGORY>.*`, where `<CATEGORY>` is the category assigned to the parameter in the Network Parameter spec.

## 4. Add a new asset

New [assets](./0040-asset-framework.md) can be proposed through the governance system. The procedure is covered in detail in the [asset proposal spec](./0027-asset-proposal.md)). Unlike markets, assets cannot be updated after they have been added.

## 5. Transfers initiated by Governance

### Permitted source and destination account types

The below table shows the allowable combinations of source and destination account types for a transfer that's initiated by a governance proposal. 

| Source type | Destinaton type | Governance transfer permitted |
| --- | --- | --- |
| Party account (any type) | Any | No |
| Network treasury | Reward pool account | Yes [1] |
| Network treasury | Party general account(s) | Yes |
| Network treasury | Party other account types | No |
| Network treasury | Network insurance pool account | Yes |
| Network treasury | Market insurance pool account | Yes |
| Network treasury | Any other account | No |
| Network insurance pool account | Network treasury | Yes |
| Network insurance pool account | Market insurance pool account | Yes |
| Network insurance pool account | Any other account | No |
| Market insurance pool account | Party account(s) | Yes [2] |
| Market insurance pool account | Network treasury | Yes [2] |
| Market insurance pool account | Network insurance pool account | Yes [2] |
| Market insurance pool account | Any other account | No |
| Any other account | Any | No | 

[1] This is **the only type of this functionality required for Sweetwater/MVP**

[2] In future, by market governance vote (i.e. weighted by LP shares)


### Transfer proposal details

The proposal specifies:

- `source_type`: the source account type (i.e. network treasury, network insurance pool, market insurance pool)
- `source` specifies the account to transfer from, depending on the account type:
  - network treasury: leave blank (only one per asset)
  - network insurance pool: leave blank (only one per asset)
  - market insurance pool: market ID
- `type`, which can be either "all or nothing" or "best effort":
	- all or nothing: either transfers the specified amount or does not transfer anything
  - best effort: transfers the specified amount or the max allowable amount if this is less than the specified amount
- `amount`: the maximum amount to transfer
- `asset`: the asset to transfer
- `fraction_of_balance`: the maximum fraction of the source account's balance to transfer as a decimal (i.e. 0.1 = 10% of the balance)
- `destination_type` specifies the account type to transfer to (reward pool, party, network insurance pool, market insurance pool)
- `destination` specifies the account to transfer to, depending on the account type:
  - reward pool: the reward scheme ID
  - party: the party's public key
  - network insurance pool: leave blank (there's only one per asset)
  - market insurance pool: market ID
- Plus the standard proposal fields (i.e. voting and enactment dates, etc.)


### Transfer proposal enactment

If the proposal is successful and enacted, the amount will be transferred from the source account to the destination account on the enactment date.

The amount is calculated by
```
  transfer_amount = min( 
    proposal.fraction_of_balance * source.balance, 
    proposal.amount, 
    NETWORK_MAX_AMOUNT,
    NETWORK_MAX_FRACTION * source.balance )
```

Where:
-  NETWORK_MAX_AMOUNT is a network parameter specifying the maximum absolute amount that can be transferred by governance for the source account type
-  NETWORK_MAX_FRACTION is a network parameter specifying the maximum fraction of the balance that can be transferred by governance for the source account type (must be <= 1)

If `type` is "all or nothing" then the transfer will only proceed if:

```
transfer_amount == min( 
    proposal.fraction_of_balance * source.balance, 
    proposal.amount )
```


## Proposal validation parameters

As described throughout this specification, there are several sets of network parameters that control the minimum durations of the voting and pre-enactment periods, as well as the minimum participation rate and required majority for a proposal.

These sets of parameters are named in the form `Governance.<ActionType>.<Category>.*`, i.e.

* `Governance.<ActionType>.<Cateogry>.MinimumProposalPeriod`
* `Governance.<ActionType>.<Cateogry>.MinimumPreEnactmentPeriod`
* `Governance.<ActionType>.<Cateogry>.MinimumRequiredParticipation` 
* `Governance.<ActionType>.<Cateogry>.MinimumRequiredMajority`


See the details in 1-3 above for the action type and category (or references to where to find them). For example, for market creation the parameters are as below (and for updating market and network parameters, there are multiple sets of these by category):

* `Governance.CreateMarket.All.MinimumProposalPeriod`
* `Governance.CreateMarket.All.MinimumPreEnactmentPeriod`
* `Governance.CreateMarket.All.MinimumRequiredParticipation` 
* `Governance.CreateMarket.All.MinimumRequiredMajority`


Notes:

* The categorisation of parameters is liable to change and be added to as the protocol evolves.
* As these are themselves network parameters, a set of parameters will control these parameters for the actions that update these parameters (including being self-referential), i.e. the parameter `Governance.UpdateNetwork.GovernanceProposalValidation.MinimumRequiredParticipation` would control the amount of voting participation needed to change these parameters. See the Network Parameters spec.


## APIs

The core should expose via core APIs:
 - all the active proposals on the network
 - the current results for an active proposal or a proposal awaiting enactment

APIs should also exist for clients to:
 - list all proposals including historic ones, filter by status/type, sort either way by submission date, vote closing date, or enactment date
 - retrieve the summary results and status for any proposal
 - retrieve the party IDs (pub keys) of all votes counting for (i.e. only one latest vote per party) and against a proposal
 - retrieve the full voting history for a proposal including where a party voted multiple times
 - get a list of all proposals a party voted on

# Acceptance Criteria

- [x] As a user, I can create a new proposal to affect the vega network
- [x] As a user, I can list the open proposal on the network
- [ ] As a user, I can get a list of all proposals I voted for
- [x] As a user, I can receive notification when a new proposal is created and may require attention.
- [x] As the vega network, all the votes for an existing proposal are accepted when the proposal is still open
- [x] As the vega network, all votes received before the proposal is [active](#lifecycle-of-a-proposal), or once the proposal voting period is finished, are *rejected*
- [x] As the vega network, once the voting period is finished, I validate the result based on the parameters of the proposal used to decide the outcome of it.
- [x] As the vega network, if a proposal is accepted and the duration required before change takes effect is reached, the changes are applied
- [ ] As the vega network, proposals that close less than 2 days from enactment are rejected as invalid
- [ ] As the vega network, proposals that close more/less than 1 year from enactment are rejected as invalid

## Governance proposal types
### New Market proposals
- [x] New market proposals must contain a Liquidity Commitment

### Market change proposals
- [ ] Market change proposals can only propose a change to a single parameter

### Network parameter change proposals
- [x] Network parameter change proposals can only propose a change to a single parameter

## Using Vega governance tokens as voting weight:
- [ ] As a user, I can vote for an existing proposal if I have more than 0 governance tokens in my staking account
- [ ] As a user, my vote for an existing proposal is rejected if I have 0 governance tokens in my staking account
- [ ] As a user, my vote for an existing proposal is rejected if I have 0 governance tokens in my staking account even if I have more than 0 governance tokens in my general or margin accounts
- [ ] As a user, I can vote multiple times for the same proposal if I have more than 0 governance tokens in my staking account
  - [x] Only my most recent vote is counted
- [ ] When calculating the participation rate of an auction, the participation rate of the votes takes in to account the total supply of the governance asset.

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.

## 💧 Sweetwater

- Transfers created by the period allocation of funds from the Network Treasury to a reward pool account are executed correctly as define here (though they are initiated by governance setting the parameters not by a direct governance proposal)
