# Oregon Trail

* **Status**: Being confirmed
* **Overview**: 🤠 Feature readiness for mainnet 1️⃣.
* **Result**: A new network named Wild Westnet will be launched based on this milestone, which will point at Ethereum mainnet and be run with Validators none of which are controlled by the Vega team.
* **Project board**: https://github.com/orgs/vegaprotocol/projects/58

## Core

### Features
- [Data Sourcing](https://github.com/orgs/vegaprotocol/projects/19) - [[SPEC-0045](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0045-data-sourcing.md)]
  - ☑ Signed message data source (OpenOracle/ABI encoded, Protobuf key value?)
  - ☑ Time based trigger
  - ☑ Simple filters (<=>)
  - A service that submits Coinlist data
- [Settlement at expiry](https://github.com/orgs/vegaprotocol/projects/5) - [[SPEC-0016](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0016-product-builtin-future.md#42-final-settlement-expiry)]
- [Fractional order and position sizes](https://github.com/orgs/vegaprotocol/projects/69) [[SPEC-0052](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0052-fractional-orders-positions.md)]
  - Orders and positions can be fractional with a configurable by market number of decimal places
  - Validate order sizes are a non-zero multiple of the smallest increment (i.e. )
  - Positions and margin work correctly with fractional orders
- [On Chain Rewards](https://github.com/vegaprotocol/specs-internal/pull/517/files)

### Refactors
- ?

## Block Explorer
- Open source block explorer
  - Backed by a database

1️⃣ This doesn't mean mainnet happens immediately at the end of this milestone, just that the features we need for it exist. This means that no real tokens will be used before this milestone, but that a network *could* be launched that *would* use real, value having tokens.
