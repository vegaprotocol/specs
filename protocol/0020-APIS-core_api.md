# Core API

Core APIS are those APIS that can interact with the network, but do not require any extra data processing than that which is required to run the network. Richer, more complete API endpoints live in a separate executable - imaginatively called Data Node. This document covers the functionality that is required to interact with the network via Core APIS.

Core APIS are endpoints in REST and GRPC only. Vega core previously provided GraphQL endpoints, but this is now only served by Data Node.

## Write

There is one 'write' endpoint - `transaction`, which will accept signed transaction bundles.

## Read

> **[REST API documentation](https://docs.vega.xyz/testnet/api/rest/core/core-service-submit-transaction)**

To *observe the operation, and validate the state of the protocol, we must be able to obtain data provided by the following domains:*

### Governance

- List all [governance proposals](./0028-GOVE-governance.md), regardless of state
- List all proposals, filtered by the [party identitifier](./0017-PART-party.md) of the party that created it.
- Retrieve a specified proposal
- List all [votes](./0028-GOVE-governance.md#voting-for-a-proposal)
- List [governance stake](./0059-STKG-simple_staking_and_delegating.md) for a specific party
- List [delegations](./0059-STKG-simple_staking_and_delegating.md) for a specific party

### Market

- List all known [markets](./0001-MKTF-market_framework.md)
  - **Note**: This will not include markets that have not passed a governance vote. To query for these, query [governance](#governance)
- Retrieve a specific market by market identifier.
  - All parameters for a market, from market definition.
  - Retrieve and stream market data (all fields described in [0021-MDATA - market data](./0021-MDAT-market_data_spec.md)) for a market
- List all [assets](./0040-ASSF-asset_framework.md)
  - **Note**: This will not include assets that have not passed a governance vote. To query for these, query [governance](#governance)

### Party

- List all known [parties](./0017-PART-party.md).

### [Network wide limits](./0078-NWLI-network_wide_limits.md)

- Return number of pegged orders across all the markets.

### Configuration

- List all [Network Parameters](./0054-NETP-network_parameters.md) and their current value

### Consensus data

> **[REST API documentation](https://docs.vega.xyz/testnet/category/api/rest/core/core-service)**

Separate from the state of trading, we need to be able to see that the network is operational.

- Get statistics
  - This includes data such as backlog length, che current version of the application
- Get the current block height
- Get the current timestamp, aka Vega Time

## Acceptance Criteria

On any Vega node, I can:

| Requirement | Acceptance Criteria code |
|-----------|:------------------------:|
| List all governance proposals via REST & GRPC |<a name="0020-APIS-001" href="#0020-APIS-001">0020-APIS-001</a>|
| List all governance proposals by a specified party via REST & GRPC             |<a name="0020-APIS-002" href="#0020-APIS-002">0020-APIS-002</a> |
| Retrieve a specific governance proposals by id via REST & GRPC             |<a name="0020-APIS-003" href="#0020-APIS-003">0020-APIS-003</a> |
| Retrieve a list of votes via REST & GRPC |<a name="0020-APIS-004" href="#0020-APIS-004">0020-APIS-004</a>|
| Retrieve the governance stake for a specified party via REST & GRPC |<a name="0020-APIS-005" href="#0020-APIS-005">0020-APIS-005</a>|
| List all markets via REST & GRPC |<a name="0020-APIS-006" href="#0020-APIS-006">0020-APIS-006</a>|
| Retrieve a specific market via REST & GRPC | <a name="0020-APIS-007" href="#0020-APIS-007">0020-APIS-007</a>|
| Retrieve all assets via REST & GRPC | <a name="0020-APIS-008" href="#0020-APIS-008">0020-APIS-008</a>|
| List all party IDs via REST & GRPC | <a name="0020-APIS-009" href="#0020-APIS-009">0020-APIS-009</a>|
| List all network parameters & their current values via REST & GRPC | <a name="0020-APIS-010" href="#0020-APIS-010">0020-APIS-010</a>|
| Retrieve the current block height REST & GRPC | <a name="0020-APIS-011" href="#0020-APIS-011">0020-APIS-011</a>|
| Retrieve the current vega time REST & GRPC | <a name="0020-APIS-012" href="#0020-APIS-012">0020-APIS-012</a>|
| Retrieve statistics about the network via REST & GRPC | <a name="0020-APIS-013" href="#0020-APIS-013">0020-APIS-013</a>|
| Submit a valid transaction via REST & GRPC | <a name="0020-APIS-014" href="#0020-APIS-014">0020-APIS-014</a>|

## See also

- [0022-AUTH Authentication](./0022-AUTH-auth.md) details what makes a transaction invalid or valid for submission
- [0062-SPAM Spam protection](./0022-AUTH-auth.md) may also influence which transactions are accepted by submit
