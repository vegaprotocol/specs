# Vote
Background: [Governance spec](../protocol/0028-GOVE-governance.md)
and [s](https://s.vega.xyz/s/mainnet/concepts/vega-protocol#governance).

There are a few things that can be governed on Vega...
- Network parameters (variables used by the network), 
- Markets (creation and changes to existing)
- Assets (creation on changes to existing)
- "Freeform", which has no affect on the network but can be used to to measure token holders views
These are governed through proposed changes, and then Votes for or against these proposal.

To make proposal: Parties will require an amount of the Governance token [associated](1027-ASSO-associate.md) with their key.

To vote: a party will require [associated](1027-ASSO-associate.md) Governance tokens (with exceptions around market change proposals where liquidity providers can also vote). A vote is weighted by the number of governance tokens they have associated (or in the case of liquidity providers: their equity like share).

Each type will have a majority figure that is required for the proposal to pass. As in a majority of tokens that  as well as a participation level. 

A short hand is used in these ACs:
- Open = Accepting votes
- To enact = passed but not yet enacted
- Closed = was accepting votes but deadline has passed (e.g. passed, rejected etc)
- Failed = did not get to the point of accepting votes.

## list of proposals
When looking for a particular proposal or wanting to see what proposals are open, soon to enact or closed, I...

- **must** see link to details on how governance works in docs [1004-VOTE-001](#1004-VOTE-001 "1004-VOTE-001")
- **must** see link(s) to make proposals [1004-VOTE-002](#1004-VOTE-002 "1004-VOTE-002")
- **must** if there are no proposals, see that there have been no proposals since the last chain checkpoint restore [1004-VOTE-003](#1004-VOTE-003 "1004-VOTE-003")
- **must** see open proposals (and ones due for enactment) distinct from others (e.g grouped by "open", "to enact" "closed") (note: freeform proposals do not enact so should be shown as "closed" when "passed") [1004-VOTE-004](#1004-VOTE-004 "1004-VOTE-004")
- **should** see proposals sorted with the ones closest to enactment first (within each group) [1004-VOTE-005](#1004-VOTE-005 "1004-VOTE-005")
- **must** see a history of all "closed" proposals [1004-VOTE-006](#1004-VOTE-006 "1004-VOTE-006")

for each proposal:

- **must** see the type of proposal [1004-VOTE-007](#1004-VOTE-007 "1004-VOTE-007")
- **should** see a summary of what the type of proposed change is, without looking at details (network, new market etc) [1004-VOTE-008](#1004-VOTE-008 "1004-VOTE-008")
  - for network parameters: **should** see what parameter is being changed and new value [1004-VOTE-009](#1004-VOTE-009 "1004-VOTE-009")
  - for network parameters: **could** see what the current values are for that parameter [1004-VOTE-010](#1004-VOTE-010 "1004-VOTE-010")
  - for network parameters: **could** see if there are other open proposals for the same parameter [1004-VOTE-012](#1004-VOTE-012 "1004-VOTE-012")
  - for new markets: **should** see the type of market (e.g. Future) [1004-VOTE-013](#1004-VOTE-013 "1004-VOTE-013")
  - for new markets: **could** see the type trading mode of the market (e.g. auction, continuous) [1004-VOTE-014](#1004-VOTE-014 "1004-VOTE-014")
  - for new markets: **should** see the name of the new market [1004-VOTE-015](#1004-VOTE-015 "1004-VOTE-015")
  - for new markets: **should** see the code of the new market [1004-VOTE-016](#1004-VOTE-016 "1004-VOTE-017")
  - for new markets: **should** see the settlement asset of the new market (not just asset ID but asset Symbol) [1004-VOTE-018](#1004-VOTE-018 "1004-VOTE-018")
  - for new markets: **could** see a summary of the oracle used for settlement [1004-VOTE-020](#1004-VOTE-020 "1004-VOTE-020")
  - for market changes: **should** see the name of the market being changed [1004-VOTE-021](#1004-VOTE-021 "1004-VOTE-021")
  - for market changes: **should** see a summary of what parameters are being changed [1004-VOTE-022](#1004-VOTE-022 "1004-VOTE-022")
  - for market changes: **should** see a the proposed values for parameters [1004-VOTE-023](#1004-VOTE-023 "1004-VOTE-023")
  - for market changes: **should** see a the current values for that parameter [1004-VOTE-024](#1004-VOTE-024 "1004-VOTE-024")
  - for market changes: **could** see if there are other open proposals for the same market [1004-VOTE-025](#1004-VOTE-025 "1004-VOTE-025")
  - for new assets: **must** see the name of the new asset [1004-VOTE-026](#1004-VOTE-026 "1004-VOTE-026")
  - for new assets: **must** see the code of the new asset [1004-VOTE-027](#1004-VOTE-027 "1004-VOTE-027")
  - for new assets: **must** see the source of the new asset (e.g. ERC20) [1004-VOTE-028](#1004-VOTE-028 "1004-VOTE-028")
  - for new assets (if source is ERC20): **must** see contract address [1004-VOTE-095](#1004-VOTE-095 "1004-VOTE-095")
  - for new assets (if source is ERC20): **must** see if the Asset has been whitelisted on the bridge [1004-VOTE-096](#1004-VOTE-096 "1004-VOTE-096")
  - for asset changes: **must** see name of asset being changed [1004-VOTE-029](#1004-VOTE-029 "1004-VOTE-029")
  - for asset changes: **must** see the parameter(s) being changed [1004-VOTE-030](#1004-VOTE-030 "1004-VOTE-030")
  - for asset changes; **must** see the new value for the parameters being changed [1004-VOTE-031](#1004-VOTE-031 "1004-VOTE-031")
  - for asset changes: **could** see if there are other open proposals for the same parameter(s) [1004-VOTE-032](#1004-VOTE-032 "1004-VOTE-032")
  - for asset changes: **should** see the current values for these parameters [1004-VOTE-033](#1004-VOTE-033 "1004-VOTE-033")
  - for freeform: **must** see a summary of the proposal (suggest the first x characters of the proposal blob) [1004-VOTE-034](#1004-VOTE-034 "1004-VOTE-034")
- **must** see the proposal status e.g. passed, open, waiting for node to vote) [1004-VOTE-035](#1004-VOTE-035 "1004-VOTE-035")
  - for new asset proposals: **must** see if an asset has not yet been whitelisted on the bridge [1004-VOTE-036](#1004-VOTE-036 "1004-VOTE-036")
- for open proposals: **must** see a summary of how the vote count stands and if it looks like proposal will pass or not (note some of these are repeated in more details in the [details section](#details-of-a-proposal)) [1004-VOTE-037](#1004-VOTE-037 "1004-VOTE-037")
  - if the proposal failed (had the status of "failed", because it was an invalid on submission) they **should not** appear in the list (instead the proposer will see this after submission) [1004-VOTE-038](#1004-VOTE-038 "1004-VOTE-038")
  - if the proposal looks like it will fail due to insufficient participation: **should** see "participation not reached" [1004-VOTE-039](#1004-VOTE-039 "1004-VOTE-039")
  - else if: proposal looks like it might fail due to insufficient majority (and is not a market change proposal): should see "Majority not reached" [1004-VOTE-040](#1004-VOTE-040 "1004-VOTE-040")
  - else if (is a market change proposal) and is likely to pass because of liquidity providers vote: **should** see "set to pass by Liquidity provider vote" [1004-VOTE-041](#1004-VOTE-041 "1004-VOTE-041")
  - else if: proposal is likely to pass: **should** see "set to pass" [1004-VOTE-042](#1004-VOTE-042 "1004-VOTE-042")
  - **must** see when (date/time) voting closes on proposal [1004-VOTE-043](#1004-VOTE-043 "1004-VOTE-043")
- for (non-freefrom) proposals that have passed but not enacted: **must** see when they will enact [1004-VOTE-044](#1004-VOTE-044 "1004-VOTE-044") (note: freeform do not enact)
- for (non-freefrom) proposals that have passed but not enacted: **should** see when (date/time)voting closed [1004-VOTE-045](#1004-VOTE-045 "1004-VOTE-045")
- for (non-freeform) proposals that enacted: **must** see when they enacted [1004-VOTE-046](#1004-VOTE-046 "1004-VOTE-046")
- for freeform proposals that have passed: **must** see when they passed [1004-VOTE-047](#1004-VOTE-047 "1004-VOTE-047")
- for proposals that did not pass due to lack of participation: **must** see "Participation not reached" [1004-VOTE-048](#1004-VOTE-048 "1004-VOTE-048")
- for proposals that did not pass due to lack of majority: **must** see "Majority not reached" [1004-VOTE-049](#1004-VOTE-049 "1004-VOTE-049")
- for proposals that did not pass due to failure: **must** see "Failed"  [1004-VOTE-050](#1004-VOTE-050 "1004-VOTE-050")
- for proposals that I ([connected Vega](0002-WCON-connect_vega_wallet.md) key) have voted on: **should** see my vote (for or against) [1004-VOTE-051](#1004-VOTE-051 "1004-VOTE-051")

...so I can see select one to view and vote, or view outcome.

## details of a proposal
When looking at a particular proposal, I...

- see [the same details in the list of proposals](#list-of-proposals) and:
- **must** have option to see raw JSON of proposal  [1004-VOTE-052](#1004-VOTE-052 "1004-VOTE-052")
- **should** display the proposed change [1004-VOTE-053](#1004-VOTE-053 "1004-VOTE-053")

- **must** show the rationale text [1004-VOTE-054](#1004-VOTE-054 "1004-VOTE-054")
- **must** show the rationale URL [1004-VOTE-055](#1004-VOTE-055 "1004-VOTE-055")
- **should** see that the Dapp has verified that the text on the rationale matches the hash [1004-VOTE-056](#1004-VOTE-056 "1004-VOTE-056")

For open proposals:

- **must** show a summary of vote status (base on the current total amount associated tokens, note this could change before the vote ends) [1004-VOTE-057](#1004-VOTE-057 "1004-VOTE-057")
- **must** see if the Token vote has met the required participation threshold [1004-VOTE-058](#1004-VOTE-058 "1004-VOTE-058")
- **must** see the sum of tokens that have voted so far [1004-VOTE-059](#1004-VOTE-059 "1004-VOTE-059")
- **should** see sum of tokens that have voted as a percentage of total voted [1004-VOTE-060](#1004-VOTE-060 "1004-VOTE-060")
- **should** see what the participation threshold is for this proposal (note this is set per proposal once the proposal hits the chain based on the current network params, incase a proposal is set to enact that changes threshold) [1004-VOTE-061](#1004-VOTE-061 "1004-VOTE-061")
- **must** see if the Token vote has met the required majority threshold [1004-VOTE-062](#1004-VOTE-062 "1004-VOTE-062")
- **must** see the sum of tokens that have voted in favour of the proposal [1004-VOTE-064](#1004-VOTE-064 "1004-VOTE-064")
- **should** see sum of tokens that have votes in favour of proposal as percentage of total associated [1004-VOTE-065](#1004-VOTE-065 "1004-VOTE-065")
- **should** see what the majority threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold) [1004-VOTE-066](#1004-VOTE-066 "1004-VOTE-066")

For open market change proposals, all of the above and:

- **must** show a summary of vote status (base on the current equality like share, note this could change before the vote ends) [1004-VOTE-067](#1004-VOTE-067 "1004-VOTE-067")
- **must** see if the equality like share vote has met the required participation threshold [1004-VOTE-068](#1004-VOTE-068 "1004-VOTE-068")
- **must** see the equality like share % that has voted so far [1004-VOTE-069](#1004-VOTE-069 "1004-VOTE-069")
- **should** see what the equality like share threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold) [1004-VOTE-070](#1004-VOTE-070 "1004-VOTE-070")
- **must** see if the equality like share vote has met the required majority threshold [1004-VOTE-071](#1004-VOTE-071 "1004-VOTE-071")
- **must** see the equality like share as percentage that has voted in favour of the proposal [1004-VOTE-072](#1004-VOTE-072 "1004-VOTE-072")
- **must** see what the majority threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold) [1004-VOTE-073](#1004-VOTE-073 "1004-VOTE-073")

For **closed** market change proposals, all of the above and:

- all of above but values at time of vote close [1004-VOTE-074](#1004-VOTE-074 "1004-VOTE-074")

... so I can see what I am voting for and the status of the vote.

## Can vote on an open proposals
When looking to vote on the proposal, I...

- **must** see an option to [connect to a Vega wallet/key](0002-WCON-connect_vega_wallet.md) [1004-VOTE-075](#1004-VOTE-075 "1004-VOTE-075")
- **must** be [connected to a Vega wallet/key](0002-WCON-connect_vega_wallet.md) [1004-VOTE-076](#1004-VOTE-076 "1004-VOTE-076")
  - **must** see sum of tokens I have [associated](1027-ASSO-associate.md) [1004-VOTE-100](#1004-VOTE-100 "1004-VOTE-100")
  - **should** see what percentage of the total [associated](1027-ASSO-associate.md) tokens I hold [1004-VOTE-077](#1004-VOTE-077 "1004-VOTE-077")
    - **should**, if i have 0 tokens, see link to [associate](1027-ASSO-associate.md) [1004-VOTE-078](#1004-VOTE-078 "1004-VOTE-078")
  - **must** see my current vote for, against, or not voted [1004-VOTE-079](#1004-VOTE-079 "1004-VOTE-079")
  - **must** see option to vote for or against [1004-VOTE-080](#1004-VOTE-080 "1004-VOTE-080")
  - **must** see option to change my vote (vote again in same or different direction) [1004-VOTE-090](#1004-VOTE-090 "1004-VOTE-090")

For open market change proposals, all of the above and:

- **must** be [connected to a Vega wallet/key](0002-WCON-connect_vega_wallet.md) [1004-VOTE-091](#1004-VOTE-091 "1004-VOTE-091")
  - **must** see your equity like share on the market you are voting on [1004-VOTE-092](#1004-VOTE-092 "1004-VOTE-092")

for both:

- **must** see feedback of my vote [Vega transaction](0003-WTXN-submit_vega_transaction.md) [1004-VOTE-093](#1004-VOTE-093 "1004-VOTE-093")

...so that I can cast my vote and see the impact it might have. [1004-VOTE-094](#1004-VOTE-094 "1004-VOTE-094")

