# Propose

Background: [Governance spec](../protocol/0028-GOVE-governance.md)
and [docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-protocol#governance).

## Associate tokens

When looking to propose something, I...

- **must** see see a link to detailed explanation of Governance in the docs <a name="3002-PROP-001" href="#3002-PROP-001">3002-PROP-001</a>
- **must** see that the governance token is an ethereum ERC20 token and needs to attributed (or [associated](1003-ASSO-associate.md)) to a Vega wallet for use on Vega <a name="3002-PROP-002" href="#3002-PROP-002">3002-PROP-002</a>
- **must** see that I need some associated tokens, and a link to [associate](1003-ASSO-associate.md) <a name="3002-PROP-003" href="#3002-PROP-003">3002-PROP-003</a>

... so I have a sufficient vote weight to propose.

## Select proposal type

when making a proposal, I...

- **must** select a proposal type <a name="3002-PROP-005" href="#3002-PROP-005">3002-PROP-005</a>

...so I get the appropriate form and information about rules for that type of proposal. e.g. min enactment and vote duration.

## Populate a proposal form

When making a proposal, I...

- **must** input a rationale <a name="3002-PROP-006" href="#3002-PROP-006">3002-PROP-006</a>
- **must** input a rationale URL <a name="3002-PROP-007" href="#3002-PROP-007">3002-PROP-007</a>
- **must** see the rules (min vote duration and enactment delay) for this proposal type <a name="3002-PROP-008" href="#3002-PROP-008">3002-PROP-008</a>
- if anything except market change: **must** be warned if the amount I have associated is less the the minimum required to propose for this proposal type <a name="3002-PROP-009" href="#3002-PROP-009">3002-PROP-009</a>
- if market change: **must** be warned if the amount I have less than the minimum required equity like share to propose a change <a name="3002-PROP-020" href="#3002-PROP-020">3002-PROP-020</a>
- **should** see the balance of associated Governance tokens <a name="3002-PROP-010" href="#3002-PROP-010">3002-PROP-010</a>

### Detail on specific proposals

Go to the following for detail on each proposal type:

- [Propose new Market](./1006-PMARK-propose_new_market.md)
- [Propose change(s) to market](./1007-PMAC-propose_market_change.md)
- [Propose new asset](1008-PASN-propose_new_asset.md)
- [Propose change(s) to asset](1009-PASC-propose_asset_change.md)
- [Propose change to network parameter(s)](1010-PNEC-propose_network.md)
- [Propose something "Freeform"](1011-PFRO-propose_freeform.md)

### Submit proposal

- **must** submit the proposal [Vega transaction](0003-WTXN-submit_vega_transaction.md) <a name="3002-PROP-011" href="#3002-PROP-011">3002-PROP-011</a>
- **must** see the feedback on the [Vega transaction](0003-WTXN-submit_vega_transaction.md) <a name="3002-PROP-012" href="#3002-PROP-012">3002-PROP-012</a>
- If there is an error on the proposal:
  - **must** be shown an error message will all of the error details from the API <a name="3002-PROP-013" href="#3002-PROP-013">3002-PROP-013</a>
  - **must** see the proposal form populated with all the same values just submitted <a name="3002-PROP-014" href="#3002-PROP-014">3002-PROP-014</a>
  - **should** see error messages highlighted on the inputs that require user attention <a name="3002-PROP-015" href="#3002-PROP-015">3002-PROP-015</a>
- If the proposal was successful:
  - **must** be shown it was successful <a name="3002-PROP-016" href="#3002-PROP-016">3002-PROP-016</a>
  - **should** be prompted to vote on the proposal <a name="3002-PROP-017" href="#3002-PROP-017">3002-PROP-017</a>
  - **should** be prompted to share the proposal detail page to encourage others to vote <a name="3002-PROP-018" href="#3002-PROP-018">3002-PROP-018</a>
  - **must** see a link to the proposal detail page <a name="3002-PROP-019" href="#3002-PROP-019">3002-PROP-019</a>

...so that the proposal is listed on the chain and I and others can vote for or against it.
 