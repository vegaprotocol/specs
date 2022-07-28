# Propose
Background: [Governance spec](../protocol/0028-GOVE-governance.md)
and [docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-protocol#governance).



## Associate tokens
When looking to propose something, I... 

- **must** see see a link to detailed explanation of Governance in the docs
- **must** see that the governance token is an ethereum ERC20 token and needs to attributed (or associated) to a Vega wallet for use on Vega
- **must** see that I need some associated tokens, and a link to do so
- **must** have an associated balance of the Governance token ([See Associate tokens](./1000-ASSO-associate.md))

... so I have a sufficient vote weight to propose.

## Select proposal type
when making a proposal, I...

- **must** select a proposal type

...so I get the appropriate form and information about rules for that type of proposal. e.g. min enactment and vote duration.

## populate a proposal form

When making a proposal, I...

- **must** input a rationale
- **must** input a rationale URL
- **must** see the rules (min vote duration and enactment delay) for this proposal type
- **must** be warned if the amount I have associated is less the the minimum required to propose
- **should** see the balance of associated Governance tokens

### Detail on specific proposals
Go to the following for detail on each proposal type:
- [Propose new Market](./1006-PMARK-propose_new_market.md)
- [Propose change(s) to market](./1007-PMAC-propose_market_change.md)
- [Propose new asset](1008-PASN-propose_new_asset.md)
- [Propose change(s) to asset](1009-PASC-propose_asset_change.md)
- [Propose change to network parameter(s)](1010-PNEC-propose_network.md)
- [Propose something "Freeform"](1011-PFRO-propose_freeform.md)

### Submit proposal

- **must** submit the proposal [Vega transactions](#TBD)
- **must** see the feedback on the [Vega transactions](#TBD)
- If there is an error on the proposal: 
  - **must** be shown an error message will all of the error details from the API
  - **must** see the proposal form populated with all the same values just submitted
  - **should** see error messages highlighted on the inputs that require user attention
- If the proposal we successful:
  - **must** be shown it was successful
  - **should** be prompted to vote on the proposal
  - **should** be prompted to share the proposal detail page to encourage others to vote
  - **must** see a link to the proposal detail page

...so that the proposal is listed on the chain and I and others can vote for or against it.