# Vote
Background: [Governance spec](../protocol/0028-GOVE-governance.md)
and [docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-protocol#governance).

There are a few things that can be governed on Vega...
- Network parameters (variables used by the network), 
- Markets (creation and changes to existing)
- Assets (creation on changes to existing)
- "Freeform", which has no affect on the network but can be used to to measure token holders views
These are governed through proposed changes, and then Votes for or against these proposal.

To make proposal: Parties will require an amount of the Governance token [associated](1000-ASSO-associate.md) with their key.

To vote: a party will require [associated](1000-ASSO-associate.md) Governance tokens (with exceptions around market change proposals where liquidity providers can also vote). A vote is weighted by the number of governance tokens they have associated (or in the case of liquidity providers: their equity like share).

Each type will have a majority figure that is required for the proposal to pass. As in a majority of tokens that 
 as well as a participation level. 

## list of proposals
When looking for a particular proposal or wanting to see what proposals are open, soon to enact or closed, I...

- **must** see open proposals or ones due for enactment distinct from others (e.g grouped by "open" or "closed") (note: freeform proposals do not enact)
- **should** see proposals sorted with the ones closest to enactment first
- **must** see a history of all other proposals
- **must** see the type of proposal
- **should** see a summary of what the type of proposed change is, without looking at details (network, new market etc)
  - for network parameters: **should** see what parameter is being changed and new value
  - for network parameters: **could** see what the current values are for that parameter
  - for network parameters: **could** see if there are other open proposals for the same parameter
  - for new markets: **should** see the type of market (e.g. Future)
  - for new markets: **could** see the type trading mode of the market (e.g. auction, continuous)
  - for new markets: **should** see the name of the new market
  - for new markets: **should** see the code of the new market
  - for new markets: **should** see the settlement asset of the new market (not just asset ID but asset Symbol)
  - for new markets: **could** see a summary of the oracle used for settlement
  - for market changes: **should** see the name of the market being changed
  - for market changes: **should** see a summary of what parameters are being changed
  - for market changes: **should** see a the proposed values for parameters
  - for market changes: **should** see a the current values for that parameter
  - for market changes: **could** see if there are other open proposals for the same market
  - for new assets: **must** see the name of the new asset
  - for new assets: **must** see the name of the new asset
  - for new assets: **must** see the source of the new asset (e.g. ERC20)
  - for new assets (if source is ERC20): **must** see contract address
  - for asset changes: **must** see name of asset being changed
  - for asset changes: **must** see the parameter(s) being changed
  - for asset changes; **must** see the new value for the parameters being changed
  - for asset changes: **could** see if there are other open proposals for the same parameter(s)
  - for asset changes: **should** see the current values for these parameters
  - for freeform: **must** see a summary of the proposal (suggest the first x characters of the proposal blob)
- **must** see the proposal status e.g. passed, open, waiting for node to vote)
- for open proposals: **must** see a summary of how the vote is going
  - if the proposal failed (had the status of "failed", because they were invalid on submission) they **should not** appear in the list (instead the proposer will see this after submission)
  - if the proposal looks like it will fail due to insufficient participation: **should** show "participation not reached"
  - else if: proposal looks like it might fail due to insufficient majority (and is not a market change proposal): should show "Majority not reached"
  - else if (is a market change proposal) and is likely to pass because of liquidity providers vote: **should** show "set to pass by Liquidity provider vote"
  - else if: proposal is likely to pass: **should** show "set to pass"
  - **must** see when voting closes on proposal
- for (non-freefrom) proposals that have passed but not enacted: **must** see when they will enact
- for (non-freefrom) proposals that have passed but not enacted: **should** see when voting closed
- for freeform proposals that have passed: **must** see when they passed
- for (non-freeform) proposals that passed: **must** see when they enacted
- for proposals that did not pass due to lack of participation: **must** see "Participation not reached"
- for proposals that did not pass due to lack of majority: **must** see "Majority not reached"
- for proposals that did not pass due to failure: **must** see "Failed"
- for proposals that I ([connected Vega](#TBD) key) have voted on: **must** see my vote

...so I can see select one to view and vote, or view outcome

## details of a proposal
When looking at a particular proposal, I...

- see [above](#list-of-proposals)
- 

... so i can see what I am voting for and the status of the vote.

## Can vote on an open proposals

### Associate tokens so that I have some voting weight
See [Associate tokens](./1000-ASSO-associate.md)

### All proposal types

### Market change specific

