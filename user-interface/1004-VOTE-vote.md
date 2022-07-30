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

Each type will have a majority figure that is required for the proposal to pass. As in a majority of tokens that  as well as a participation level. 

A short hand is used in these ACs:
- Open = Accepting votes
- To enact = passed but not yet enacted
- Closed = was accepting votes but deadline has passed (e.g. passed, rejected etc)
- Failed = did not get to the point of accepting votes.

## list of proposals
When looking for a particular proposal or wanting to see what proposals are open, soon to enact or closed, I...

- **must** see open proposals (and ones due for enactment) distinct from others (e.g grouped by "open", "to enact" "closed") (note: freeform proposals do not enact so should be shown as "closed" when "passed") [1004-VOTE-001](#1004-VOTE-001 "1004-VOTE-001")
- **should** see proposals sorted with the ones closest to enactment first [1004-VOTE-002](#1004-VOTE-002 "1004-VOTE-002")
- **must** see a history of all "closed" proposals [1004-VOTE-003](#1004-VOTE-003 "1004-VOTE-003")
- **must** see the type of proposal [1004-VOTE-004](#1004-VOTE-004 "1004-VOTE-004")
- **should** see a summary of what the type of proposed change is, without looking at details (network, new market etc) [1004-VOTE-005](#1004-VOTE-004 "1004-VOTE-004")
  - for network parameters: **should** see what parameter is being changed and new value [1004-VOTE-005](#1004-VOTE-005 "1004-VOTE-005")
  - for network parameters: **could** see what the current values are for that parameter [1004-VOTE-006](#1004-VOTE-006 "1004-VOTE-006")
  - for network parameters: **could** see if there are other open proposals for the same parameter [1004-VOTE-007](#1004-VOTE-007 "1004-VOTE-007")
  - for new markets: **should** see the type of market (e.g. Future) [1004-VOTE-008](#1004-VOTE-008 "1004-VOTE-008")
  - for new markets: **could** see the type trading mode of the market (e.g. auction, continuous) [1004-VOTE-009](#1004-VOTE-009 "1004-VOTE-009")
  - for new markets: **should** see the name of the new market [1004-VOTE-010](#1004-VOTE-010 "1004-VOTE-010")
  - for new markets: **should** see the code of the new market [1004-VOTE-011](#1004-VOTE-011 "1004-VOTE-011")
  - for new markets: **should** see the settlement asset of the new market (not just asset ID but asset Symbol) [1004-VOTE-012](#1004-VOTE-012 "1004-VOTE-012")
  - for new markets: **could** see a summary of the oracle used for settlement [1004-VOTE-013](#1004-VOTE-013 "1004-VOTE-013")
  - for market changes: **should** see the name of the market being changed [1004-VOTE-014](#1004-VOTE-014 "1004-VOTE-014")
  - for market changes: **should** see a summary of what parameters are being changed [1004-VOTE-015](#1004-VOTE-015 "1004-VOTE-015")
  - for market changes: **should** see a the proposed values for parameters [1004-VOTE-016](#1004-VOTE-016 "1004-VOTE-016")
  - for market changes: **should** see a the current values for that parameter [1004-VOTE-017](#1004-VOTE-017 "1004-VOTE-017")
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
- **must** have option to see raw JSON of proposal
- **should** display the proposed change

- **must** show the rationale text
- **must** show the rationale URL
- **should** see that the Dapp has verified that the text on the rationale matches the hash

For open proposals:

- **must** show a summary of vote status (base on the current total amount associated tokens, note this could change before the vote ends)
- **must** see if the Token vote has met the required participation threshold
- **must** see the sum of tokens that have voted so far
- **should** see sum of tokens that have voted as a percentage of total voted
- **should** see what the participation threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold)
- **must** see if the Token vote has met the required majority threshold
- **must** see the sum of tokens that have voted in favour of the proposal
- **should** see sum of tokens that have votes in favour of proposal as percentage of total associated
- **should** see what the majority threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold)

For open market change proposals, all of the above and:

- **must** show a summary of vote status (base on the current equality like share, note this could change before the vote ends)
- **must** see if the equality like share vote has met the required participation threshold
- **must** see the equality like share % that has voted so far
- **should** see what the equality like share threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold)
- **must** see if the equality like share vote has met the required majority threshold
- **must** see the equality like share as percentage that has voted in favour of the proposal
- **must** see what the majority threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold)

For **closed** market change proposals, all of the above and:

- all of above but values at time of vote close

... so I can see what I am voting for and the status of the vote.

## Can vote on an open proposals
When looking to vote on the proposal, I...

- **must** see an option to [connect to a Vega wallet/key](#TBD)
- **must** be [connected to a Vega wallet/key](#TBD)
  - **must** see sum of tokens I have [associated](1000-ASSO-associate.md)
  - **should** see what percentage of the total [associated](1000-ASSO-associate.md) tokens I hold
    - **should**, if i have 0 tokens, see link to [associate](1000-ASSO-associate.md)
  - **must** see my current vote for, against, or not voted
  - **must** see option to vote for or against
  - **must** see option to change my vote (vote again in same or different direction)

For open market change proposals, all of the above and:

- **must** be [connected to a Vega wallet/key](#TBD)
  - **must** see your equity like share on the market you are voting on

...so that I can cast my vote and see the impact it might have.

### All proposal types

### Market change specific

