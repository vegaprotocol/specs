# Oregon Trail

* **Status**: Being confirmed
* **Overview** 🤠 Feature readiness for mainnet 1️⃣


## Core

### Features
- Data Sourcing (Spec not yet merged)
  - Signed message data source (OpenOracle/ABI encoded, Protobuf key value?)
  - Time based trigger
  - Simple filters (<=>)
- Settlement at expiry (_[SPEC-0016](https://github.com/vegaprotocol/product/blob/master/specs/0016-product-builtin-future.md#42-final-settlement-expiry)_)
- Fractional order and position sizes (Needs a spec)
  - Orders and positions can be fractional with a configurable by market number of decimal places
  - Validate order sizes are a non-zero multiple of the smallest increment (i.e. )
  - Positions and margin work correctly with fractional orders
  - For engineeering: can be implemented with a decimal data type or uint[256?] same as for amounts
- Limited network life (No spec written)
  - How to finally settle/unwind/do withdrawals after the end
  - Migrating balances between network runs 
- Validators (No spec written, _[Research Paper](https://github.com/vegaprotocol/research-internal/blob/master/validator_rewards/ValPol.pdf)_)
  - Stake delegation
  - Validator rewards (and delegator rewards)
  - Vega interacting with the Tendermint validator power
  - Quality of Life improvements for node runners (_[VIP-1](https://github.com/vegaprotocol/VIPs/pull/1))_
 - Expanded spam protection

### Refactors
- API server split out from the core
- ...

### Limits / Training wheels (refine after January workshop)
 - Max (lifetime) deposit or maximum balance per party (including margin). This may be different for liquidity providers.
 - Withdrawal waiting period
 - Governance to interrupt withdrawal

## Block Explorer
- Open source block explorer
  - Backed by a database

1️⃣ This doesn't mean mainnet happens immediately at the end of this release, just that the features we need for it exist
