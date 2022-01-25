# Oregon Trail

* **Overview**: 🤠 Feature readiness for trading on mainnet.
* **Result**: A new network named Wild Westnet will be launched based on this milestone, which will point at Ethereum mainnet and be run with Validators none of which are controlled by the Vega team.
* **Milestone Tag** "🤠 Oregon Trail"
* **Target timings**: 6-8 weeks?? (late Feb to coinside with Eth Denver??)


## Key Requirements
| Priority | Feature | Because | Details | Owner </br>(Spec Lead) | Sub-Function | Feature Label |
|:---------:|---------|---------|:------:|:------:|:------:|:------:|
| **1** | Floating point determinism | There is a need to create a state variable engine which reaches consensus on floating point values across validators | [FTCO](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0065-FTCO-floating_point_consensus.md) | @witgaw | Core | [👉 Floating point determinism](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%91%89+Floating+point+determinism%22+is%3Aopen+) |
| **2** | Validator performance  | Because validator rewards will be scaled based on their performance | [VALP](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0064-VALP-validator_performance_based_rewards.md) </br> [VALW](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0066-VALW-validator_tendermint_weights.md) | @core | Core | [⏱ Validator performance](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%E2%8F%B1+Validator+performance%22+is%3Aopen+) |
| **3** | Decentralised validator selection  | Because we are decentrailised and validator selection will be done by delegation | [Open PR](https://github.com/vegaprotocol/specs-internal/pull/766) | @core | Core | [🚦 Validators selection](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%9A%A6+Validators+selection%22+is%3Aopen+) |
| **4** | On-chain Treasury | There needs to be a pool of assets to reward people | [Open Issue](https://github.com/vegaprotocol/specs-internal/issues/800) | @davidsiska-vega | Core | [👑 On-Chain Treasury](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%91%91+On-Chain+Treasury%22+is%3Aopen+) |
| **5** | Market governance proposals | (e.g. weighting by LP shares, granular difficulty control) | [Open Issue](https://github.com/vegaprotocol/specs-internal/issues/774) | @davidsiska-vega | Core | [🏪 Market Governance](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%8F%AA+Market+Governance%22+is%3Aopen+) |
| **6** | Benchmark performance testing | We need to assess risks and resolve any found critical issues before trading is enabled | [QA Task](https://github.com/vegaprotocol/system-tests/issues/352) | @core | Core | [🧪 performance testing](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%A7%AA+performance+testing%22+is%3Aopen+) |
| **7** | Data node v2 | Because users of the protcol often need various data (price history / delegation history / transfers etc.) | [Open PR](https://github.com/vegaprotocol/specs-internal/pull/763) | @Vegaklaus | Research</br>Front-End</br>Core | [🧮 DatanodeV2](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%A7%AE+DatanodeV2%22+is%3Aopen+) |
| **8** | Decimal place conversions  | We need to convert to and from 18dp and account for fees etc. | [Open PR](https://github.com/vegaprotocol/specs-internal/pull/796) | @jeremyletang | Core</br>Front End | [📈 Market decimal places](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%93%88+Market+decimal+places%22+is%3Aopen+) |
| **9** | Block Explorer  | To get the current block explorer working to decide next steps backed by a database | [Issues filter](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3AMVP%2C%22%F0%9F%A7%B1+block+explorer%22+repo%3Aexplorer+is%3Aopen+) | @davidsiska-vega | Core</br>Front End | [🧱 block explorer, mvp](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%A7%B1+block+explorer%22%2Cmvp+is%3Aopen+) |


## Stretch Tasks
| Priority | Feature | Because | Details | Owner </br>(Spec Lead) | Sub-Function | Feature Label |
|:---------:|---------|---------|:------:|:------:|:------:|:------:|
| **1** | Transfers between Vega pubkeys | Because we dont like the Eth gas fees | [Open Issue](https://github.com/vegaprotocol/specs-internal/issues/800) | @davidsiska-vega | Core | [↔️ Transfer between wallets](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%E2%86%94%EF%B8%8F+Transfer+between+wallets%22+is%3Aopen+) |
| **2** | Incentivised data-node implementation | Because we want to incentivise other parties to run instances of the data node. Stretch because we need datanode-v2 first | [Open PR](https://github.com/vegaprotocol/specs-internal/pull/684)| @davidsiska-vega | Core | [🤑 Incentivised data-node](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%A4%91+Incentivised+data-node%22+is%3Aopen+) |


### Refactors
| Priority | Feature | Because | Details | Owner </br>(Spec Lead) | Sub-Function | Feature Label |
|:---------:|---------|---------|:------:|:------:|:------:|:------:|
| **1** | Fractional order sizes  | We need to support more precision | [FPOS](0052-FPOS-fractional_orders_positions.md) | @davidsiska-vega | Core</br>Front-End | [➗ Fractional Orders](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%E2%9E%97+Fractional+Orders%22+is%3Aopen) |
| **2** | Internalize ethereum-event-forwarder | To simplify the deployment of vega and minimize the interaction with external softwares | [Core Issue](https://github.com/vegaprotocol/vega/issues/4553) | @core | Core | [ethereum](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22ethereum%22+is%3Aopen+) |
| **3** | Rewrite Dockerised Vega | Dockerised Vega is hard to maintain and is slowing us down | [Core Issue](https://github.com/orgs/vegaprotocol/projects/95#card-68976394) | @core | Devops</br>Core | [🐉 vegacapsule](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22%F0%9F%90%89+vegacapsule%22+is%3Aopen+) |
| **TBC** | Internalize the wallet | ?? - needs to have the core open source first: To simplify the deployment of vega and minimize the interaction with external softwares | [Core Issue](https://github.com/vegaprotocol/vega/issues/4562) | @core | Core | [wallet](https://github.com/issues?q=is%3Aissue+user%3Avegaprotocol+label%3A%22wallet%22+is%3Aopen+) |

