# Oregon Trail

* **Status**: Being confirmed
* **Overview**: 🤠 Feature readiness for trading on mainnet.
* **Result**: A new network named Wild Westnet will be launched based on this milestone, which will point at Ethereum mainnet and be run with Validators none of which are controlled by the Vega team.
* **Project board**: https://github.com/orgs/vegaprotocol/projects/58
* **Target timings**: 6-8 weeks (late Feb to coinside with Eth Denver)


## Key Requirements
| Priority | Feature | Because | Details | Owner </br>(Spec Lead) | Sub-Function |
|:---------:|---------|---------|:------:|:------:|:------:|
| **1** | 👉 Floating point determinism | There is a need to create a state variable engine which reaches consensus on floating point values across validators | [Spec](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0065-floating-point-consensus.md) | @witgaw | Core |
| **2** | Validator performance  | Because validator rewards will be scaled based on their performance | [spec1 rewards](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0064-validator-performance-based-rewards.md) </br> [spec2 TM weights](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0065-validator-tendermint-weights.md) | @core | Core |
| **3** | Decentralised validator selection  | Because we are decentrailised and validator selection will be done by delegation | [open PR](https://github.com/vegaprotocol/specs-internal/pull/766) | @core | Core |
| **4** | 👑 On-chain Treasury | There needs to be a pool of assets to reward people | [Spec](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0055-on-chain-treasury.md) | @davidsiska-vega | Core |
| **5** | Market governance proposals | (e.g. weighting by LP shares, granular difficulty control) | LINK? | @davidsiska-vega | Core |
| **6** | Benchmark performance testing | We need to assess risks and resolve any found critical issues before trading is enabled | LINK? | @core | Core |
| **7** | Data node v2 | Because users of the protcol often need various data (price history / delegation history / transfers etc.) | [open PR](https://github.com/vegaprotocol/specs-internal/pull/763) | @Vegaklaus | Research</br>Front End</br>Core |
| **8** | Decimal place conversions  | We need to convert to and from 18dp and account for fees etc. | Issue TBC | @jeremyletang | Core</br>Front End |
| **9** | Block Explorer  | To explore the Vega blocks with an open source block explorer backed by a database | [Issue](https://github.com/vegaprotocol/specs-internal/issues/453) | @davidsiska-vega | Core</br>Front End |


## Stretch Tasks
| Priority | Feature | Because | Details | Owner </br>(Spec Lead) | Sub-Function |
|:---------:|---------|---------|:------:|:------:|:------:|
| **1** | Transfers between Vega pubkeys | Because we dont like the Eth gas fees | Spec/Issue TBC| @davidsiska-vega | Core |
| **2** | 🤑 Incentivised data-node implementation | Because we want to incentivise other parties to run instances of the data node. Stretch because we need datanode-v2 first | [Project](https://github.com/orgs/vegaprotocol/projects/92)| @davidsiska-vega | Core |


### Refactors
| Priority | Feature | Because | Details | Owner </br>(Spec Lead) | Sub-Function |
|:---------:|---------|---------|:------:|:------:|:------:|
| **1** | Fractional order sizes  | We need to support more prevision | [Spec](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0052-fractional-orders-positions.md) | @davidsiska-vega | Core</br>Front End |
| **2** | Internalize ethereum-event-forwarder | To simplify the deployment of vega and minimize the interaction with external softwares | [Issue](https://github.com/vegaprotocol/vega/issues/4553) | @core | Core |
| **3** | Rewrite Dockerised Vega | Dockerised Vega is hard to maintain and is slowing us down | [Issue](https://github.com/orgs/vegaprotocol/projects/95#card-68976394) | @core | Devops</br>Core |
| **TBC** | Internalize the wallet | ?? - needs to have the core open source first: To simplify the deployment of vega and minimize the interaction with external softwares | [Issue](https://github.com/vegaprotocol/vega/issues/4562) | @core | Core |

