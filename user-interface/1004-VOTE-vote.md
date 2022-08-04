# Vote

Background: [Governance spec](../protocol/0028-GOVE-governance.md)
and [docs](https://s.vega.xyz/s/mainnet/concepts/vega-protocol#governance).

There are a few things that can be governed on Vega...

- Network parameters (variables used by the network),
- Markets (creation and changes to existing)
- Assets (creation on changes to existing)
- "Freeform", which has no affect on the network but can be used to to measure token holders views
  These are governed through proposed changes, and then Votes for or against these proposal.

To make proposal: Parties will require an amount of the Governance token [associated](./1027-ASSO-associate.md) with their key.

To vote: a party will require [associated](./1027-ASSO-associate.md) Governance tokens (with exceptions around market change proposals where liquidity providers can also vote). A vote is weighted by the number of governance tokens they have associated (or in the case of liquidity providers: their equity like share).

Each type will have a majority figure that is required for the proposal to pass. As in a majority of tokens that as well as a participation level.

A short hand is used in these ACs:

- Open = Accepting votes
- To enact = passed but not yet enacted
- Closed = was accepting votes but deadline has passed (e.g. passed, rejected etc)
- Failed = did not get to the point of accepting votes.

## list of proposals

When looking for a particular proposal or wanting to see what proposals are open, soon to enact or closed, I...

- **must** see link to details on how governance works in docs <a name="1004-VOTE-001" href="#1004-VOTE-001">1004-VOTE-001</a>
- **must** see link(s) to make proposals <a name="1004-VOTE-002" href="#1004-VOTE-002">1004-VOTE-002</a>
- **must** if there are no proposals, see that there have been no proposals since the last chain checkpoint restore <a name="1004-VOTE-003" href="#1004-VOTE-003">1004-VOTE-003</a>
- **must** see open proposals (and ones due for enactment) distinct from others (e.g grouped by "open", "to enact" "closed") (note: freeform proposals do not enact so should be shown as "closed" when "passed") <a name="1004-VOTE-004" href="#1004-VOTE-004">1004-VOTE-004</a>
- **should** see proposals sorted with the ones closest to enactment first (within each group) <a name="1004-VOTE-005" href="#1004-VOTE-005">1004-VOTE-005</a>
- **must** see a history of all "closed" proposals <a name="1004-VOTE-006" href="#1004-VOTE-006">1004-VOTE-006</a>
- **should** have the option to search for a proposal. by:
  - **should** be able to search by proposal ID
  - **should** be able to search by public key of the proposer
  - **should** be abel to search by market ID/name/code (ID may be the same as proposal ID)
  - **should** be able to search by asset name/symbol
  - **should** be able to search by network parameter
  - **should** be able to search by content of proposal description

for each proposal:

- **must** see the type of proposal <a name="1004-VOTE-007" href="#1004-VOTE-007">1004-VOTE-007</a>
- **should** see a summary of what the type of proposed change is, without looking at details (network, new market etc) <a name="1004-VOTE-008" href="#1004-VOTE-008">1004-VOTE-008</a>
  - for network parameters: **should** see what parameter is being changed and new value <a name="1004-VOTE-009" href="#1004-VOTE-009">1004-VOTE-009</a>
  - for network parameters: **could** see what the current values are for that parameter <a name="1004-VOTE-010" href="#1004-VOTE-010">1004-VOTE-010</a>
  - for network parameters: **could** see if there are other open proposals for the same parameter <a name="1004-VOTE-012" href="#1004-VOTE-012">1004-VOTE-012</a>
  - for new markets: **should** see the type of market (e.g. Future) <a name="1004-VOTE-013" href="#1004-VOTE-013">1004-VOTE-013</a>
  - for new markets: **could** see the type trading mode of the market (e.g. auction, continuous) <a name="1004-VOTE-014" href="#1004-VOTE-014">1004-VOTE-014</a>
  - for new markets: **should** see the name of the new market <a name="1004-VOTE-015" href="#1004-VOTE-015">1004-VOTE-015</a>
  - for new markets: **should** see the code of the new market <a name="1004-VOTE-016" href="#1004-VOTE-016">1004-VOTE-016</a>
  - for new markets: **should** see the settlement asset of the new market (not just asset ID but asset Symbol) <a name="1004-VOTE-018" href="#1004-VOTE-018">1004-VOTE-018</a>
  - for new markets: **could** see a summary of the oracle used for settlement <a name="1004-VOTE-020" href="#1004-VOTE-020">1004-VOTE-020</a>
  - for market changes: **should** see the name of the market being changed <a name="1004-VOTE-021" href="#1004-VOTE-021">1004-VOTE-021</a>
  - for market changes: **should** see a summary of what parameters are being changed <a name="1004-VOTE-022" href="#1004-VOTE-022">1004-VOTE-022</a>
  - for market changes: **should** see a the proposed values for parameters <a name="1004-VOTE-023" href="#1004-VOTE-023">1004-VOTE-023</a>
  - for market changes: **should** see a the current values for that parameter <a name="1004-VOTE-024" href="#1004-VOTE-024">1004-VOTE-024</a>
  - for market changes: **could** see if there are other open proposals for the same market <a name="1004-VOTE-025" href="#1004-VOTE-025">1004-VOTE-025</a>
  - for new assets: **must** see the name of the new asset <a name="1004-VOTE-026" href="#1004-VOTE-026">1004-VOTE-026</a>
  - for new assets: **must** see the code of the new asset <a name="1004-VOTE-027" href="#1004-VOTE-027">1004-VOTE-027</a>
  - for new assets: **must** see the source of the new asset (e.g. ERC20) <a name="1004-VOTE-028" href="#1004-VOTE-028">1004-VOTE-028</a>
  - for new assets (if source is ERC20): **must** see contract address <a name="1004-VOTE-095" href="#1004-VOTE-095">1004-VOTE-095</a>
  - for new assets (if source is ERC20): **must** see if the Asset has been whitelisted on the bridge <a name="1004-VOTE-096" href="#1004-VOTE-096">1004-VOTE-096</a>
  - for asset changes: **must** see name of asset being changed <a name="1004-VOTE-029" href="#1004-VOTE-029">1004-VOTE-029</a>
  - for asset changes: **must** see the parameter(s) being changed <a name="1004-VOTE-030" href="#1004-VOTE-030">1004-VOTE-030</a>
  - for asset changes; **must** see the new value for the parameters being changed <a name="1004-VOTE-031" href="#1004-VOTE-031">1004-VOTE-031</a>
  - for asset changes: **could** see if there are other open proposals for the same parameter(s) <a name="1004-VOTE-032" href="#1004-VOTE-032">1004-VOTE-032</a>
  - for asset changes: **should** see the current values for these parameters <a name="1004-VOTE-033" href="#1004-VOTE-033">1004-VOTE-033</a>
  - for freeform: **must** see a summary of the proposal (suggest the first x characters of the proposal blob) <a name="1004-VOTE-034" href="#1004-VOTE-034">1004-VOTE-034</a>
- **must** see the proposal status e.g. passed, open, waiting for node to vote) <a name="1004-VOTE-035" href="#1004-VOTE-035">1004-VOTE-035</a>
  - for new asset proposals: **must** see if an asset has not yet been whitelisted on the bridge <a name="1004-VOTE-036" href="#1004-VOTE-036">1004-VOTE-036</a>
- for open proposals: **must** see a summary of how the vote count stands and if it looks like proposal will pass or not (note some of these are repeated in more details in the [details section](#details-of-a-proposal)) <a name="1004-VOTE-037" href="#1004-VOTE-037">1004-VOTE-037</a>
  - if the proposal failed (had the status of "failed", because it was an invalid on submission) they **should not** appear in the list (instead the proposer will see this after submission) <a name="1004-VOTE-038" href="#1004-VOTE-038">1004-VOTE-038</a>
  - if the proposal looks like it will fail due to insufficient participation: **should** see "participation not reached" <a name="1004-VOTE-039" href="#1004-VOTE-039">1004-VOTE-039</a>
  - else if: proposal looks like it might fail due to insufficient majority (and is not a market change proposal): should see "Majority not reached" <a name="1004-VOTE-040" href="#1004-VOTE-040">1004-VOTE-040</a>
  - else if (is a market change proposal) and is likely to pass because of liquidity providers vote: **should** see "set to pass by Liquidity provider vote" <a name="1004-VOTE-041" href="#1004-VOTE-041">1004-VOTE-041</a>
  - else if: proposal is likely to pass: **should** see "set to pass" <a name="1004-VOTE-042" href="#1004-VOTE-042">1004-VOTE-042</a>
  - **must** see when (date/time) voting closes on proposal <a name="1004-VOTE-043" href="#1004-VOTE-043">1004-VOTE-043</a>
- for (non-freefrom) proposals that have passed but not enacted: **must** see when they will enact <a name="1004-VOTE-044" href="#1004-VOTE-044">1004-VOTE-044</a>
- for (non-freefrom) proposals that have passed but not enacted: **should** see when (date/time)voting closed <a name="1004-VOTE-045" href="#1004-VOTE-045">1004-VOTE-045</a>
- for (non-freeform) proposals that enacted: **must** see when they enacted <a name="1004-VOTE-046" href="#1004-VOTE-046">1004-VOTE-046</a>
- for freeform proposals that have passed: **must** see when they passed <a name="1004-VOTE-047" href="#1004-VOTE-047">1004-VOTE-047</a>
- for proposals that did not pass due to lack of participation: **must** see "Participation not reached" <a name="1004-VOTE-048" href="#1004-VOTE-048">1004-VOTE-048</a>
- for proposals that did not pass due to lack of majority: **must** see "Majority not reached" <a name="1004-VOTE-049" href="#1004-VOTE-049">1004-VOTE-049</a>
- for proposals that did not pass due to failure: **must** see "Failed" <a name="1004-VOTE-050" href="#1004-VOTE-050">1004-VOTE-050</a>
- for proposals that I ([connected Vega](./0002-WCON-connect_vega_wallet.md) key) have voted on: **should** see my vote (for or against) <a name="1004-VOTE-051" href="#1004-VOTE-051">1004-VOTE-051</a>

...so I can see select one to view and vote, or view outcome.

## details of a proposal

When looking at a particular proposal, I...

- see [the same details in the list of proposals](#list-of-proposals) and:
- **must** have option to see raw JSON of proposal <a name="1004-VOTE-052" href="#1004-VOTE-052">1004-VOTE-052</a>
- **should** display the proposed change <a name="1004-VOTE-053" href="#1004-VOTE-053">1004-VOTE-053</a>

- **must** show the rationale text <a name="1004-VOTE-054" href="#1004-VOTE-054">1004-VOTE-054</a>
- **must** show the rationale URL <a name="1004-VOTE-055" href="#1004-VOTE-055">1004-VOTE-055</a>
- **should** see that the Dapp has verified that the text on the rationale matches the hash <a name="1004-VOTE-056" href="#1004-VOTE-056">1004-VOTE-056</a>

For open proposals:

- **must** show a summary of vote status (base on the current total amount associated tokens, note this could change before the vote ends) <a name="1004-VOTE-057" href="#1004-VOTE-057">1004-VOTE-057</a>
- **must** see if the Token vote has met the required participation threshold <a name="1004-VOTE-058" href="#1004-VOTE-058">1004-VOTE-058</a>
- **must** see the sum of tokens that have voted so far <a name="1004-VOTE-059" href="#1004-VOTE-059">1004-VOTE-059</a>
- **should** see sum of tokens that have voted as a percentage of total voted <a name="1004-VOTE-060" href="#1004-VOTE-060">1004-VOTE-060</a>
- **should** see what the participation threshold is for this proposal (note this is set per proposal once the proposal hits the chain based on the current network params, incase a proposal is set to enact that changes threshold) <a name="1004-VOTE-061" href="#1004-VOTE-061">1004-VOTE-061</a>
- **must** see if the Token vote has met the required majority threshold <a name="1004-VOTE-062" href="#1004-VOTE-062">1004-VOTE-062</a>
- **must** see the sum of tokens that have voted in favour of the proposal <a name="1004-VOTE-064" href="#1004-VOTE-064">1004-VOTE-064</a>
- **should** see sum of tokens that have votes in favour of proposal as percentage of total associated <a name="1004-VOTE-065" href="#1004-VOTE-065">1004-VOTE-065</a>
- **should** see what the majority threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold) <a name="1004-VOTE-066" href="#1004-VOTE-066">1004-VOTE-066</a>

For open market change proposals, all of the above and:

- **must** show a summary of vote status (base on the current equality like share, note this could change before the vote ends) <a name="1004-VOTE-067" href="#1004-VOTE-067">1004-VOTE-067</a>
- **must** see if the equality like share vote has met the required participation threshold <a name="1004-VOTE-068" href="#1004-VOTE-068">1004-VOTE-068</a>
- **must** see the equality like share % that has voted so far <a name="1004-VOTE-069" href="#1004-VOTE-069">1004-VOTE-069</a>
- **should** see what the equality like share threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold) <a name="1004-VOTE-070" href="#1004-VOTE-070">1004-VOTE-070</a>
- **must** see if the equality like share vote has met the required majority threshold <a name="1004-VOTE-071" href="#1004-VOTE-071">1004-VOTE-071</a>
- **must** see the equality like share as percentage that has voted in favour of the proposal <a name="1004-VOTE-072" href="#1004-VOTE-072">1004-VOTE-072</a>
- **must** see what the majority threshold is for this proposal (note this is see per proposal, incase a proposal is set to enact that changes threshold) <a name="1004-VOTE-073" href="#1004-VOTE-073">1004-VOTE-073</a>

For **closed** market change proposals, all of the above and:

- all of above but values at time of vote close <a name="1004-VOTE-074" href="#1004-VOTE-074">1004-VOTE-074</a>

... so I can see what I am voting for and the status of the vote.

## Can vote on an open proposals

When looking to vote on the proposal, I...

- **must** see an option to [connect to a Vega wallet/key](./0002-WCON-connect_vega_wallet.md) <a name="1004-VOTE-075" href="#1004-VOTE-075">1004-VOTE-075</a>
- **must** be [connected to a Vega wallet/key](./0002-WCON-connect_vega_wallet.md) <a name="1004-VOTE-076" href="#1004-VOTE-076">1004-VOTE-076</a>
  - **must** see sum of tokens I have [associated](1027-ASSO-associate.md) <a name="1004-VOTE-100" href="#1004-VOTE-100">1004-VOTE-100</a>
  - **should** see what percentage of the total [associated](1027-ASSO-associate.md) tokens I hold <a name="1004-VOTE-077" href="#1004-VOTE-077">1004-VOTE-077</a>
    - **should**, if i have 0 tokens, see link to [associate](1027-ASSO-associate.md) <a name="1004-VOTE-078" href="#1004-VOTE-078">1004-VOTE-078</a>
  - **must** see my current vote for, against, or not voted <a name="1004-VOTE-079" href="#1004-VOTE-079">1004-VOTE-079</a>
  - **must** see option to vote for or against <a name="1004-VOTE-080" href="#1004-VOTE-080">1004-VOTE-080</a>
  - **must** see option to change my vote (vote again in same or different direction) <a name="1004-VOTE-090" href="#1004-VOTE-090">1004-VOTE-090</a>

For open market change proposals, all of the above and:

- **must** be [connected to a Vega wallet/key](./0002-WCON-connect_vega_wallet.md) <a name="1004-VOTE-091" href="#1004-VOTE-091">1004-VOTE-091</a>
  - **must** see your equity like share on the market you are voting on <a name="1004-VOTE-092" href="#1004-VOTE-092">1004-VOTE-092</a>

for both:

- **must** see feedback of my vote [Vega transaction](0003-WTXN-submit_vega_transaction.md) <a name="1004-VOTE-093" href="#1004-VOTE-093">1004-VOTE-093</a>

...so that I can cast my vote and see the impact it might have.
