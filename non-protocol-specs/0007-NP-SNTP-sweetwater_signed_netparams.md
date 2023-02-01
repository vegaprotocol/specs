# Network Parameters Signed for Sweetwater

There are parameters within Vega that influence the behaviour of the system:

- some are set in genesis block but fixed once network is running,
- while others are changeable by on-chain [governance](../protocol/0028-GOVE-governance.md) but initialised to genesis values during network launch. For more info see [network paramters](../protocol/0054-NETP-network_parameters.md)

On [Sweetwater (Restricted Mainnet) Release](https://github.com/orgs/vegaprotocol/projects/114) Vega Team wishes to control how certain parameters are initialised while letting validators change others as they see fit.
As the process of decentralisation progresses Vega Team the number of such parameters will be reduced.

## Signing

The Vega binary will include a public key that Vega team controls.
The configuration of the network parameters defined here will be signed and verified as part of the Vega network initialisation for Sweetwater.

## Parameters to be signed

The values to be specified as a PR against ??? repo.

`TODO`: once the repo is chosen put a link here.
`TODO`: find where `validator min balance` is defined and reference correctly.

| Name                                                        | Comment                                                            | Suggested value (optional) |
|-------------------------------------------------------------|:------------------------------------------------------------------:| :-------------------------:|
| `min number of validators` (not in sweetwater)              | Not in [network paramters](../protocol/0054-NETP-network_parameters.md) |                            |
| `validator min balance`                                     | Not in [network paramters](../protocol/0054-NETP-network_parameters.md) | 3000 VEGA                  |
| `governance.proposal.updateNetParam.requiredMajority`       | So that what is set in genesis cannot be changed too easily        | 0.5                        |
| `governance.proposal.updateNetParam.requiredParticipation`  | So that what is set in genesis cannot be changed too easily        | 0.5                        |
| `validators.epoch.length`                                   | Rewards currently make an assumption on epoch length, best fix it. | 1 day                      |
| `genesis asset section`                                     | Only one asset: VEGA                                               |                            |
| `blockchains.ethereumConfig`                                | Sets collateral and staking bridge addresses.                      |                            |
| `network.checkpoint.chainEndOfLifeDate`                     | Can enforce code upgrade by setting this not too far ahead.        | 21 days                    |
| `genesis training wheels section`                           | This is important.                                                 |                            |

## Notes

The `governance.proposal.updateNetParam.requiredMajority` and `governance.proposal.updateNetParam.requiredParticipation`
are a fraction of the total number of VEGA tokens which is 64 999 723.
But currently (as of Sweetwater release) we will only have about 45 000 000 issued, so this has to be taken into account when setting these.
So a majority of 0.5 x 65 mil is 32.5 which is in fact 72%!
