# Core API

## Background

When interacting with the Vega protocol we need a way to specify a set of APIs that are provided without significant additional processing. 

## Definition

This set of APIs can be thought of as a way of accessing the current state of processing within the network and nodes. They are to be known as **core** APIs. 

When observing data containing a market, party or asset the data should be filterable based on one or more of these (AND operator).

## Write

We define the protocol instruction set within the whitepaper, therefore the **core** API must implement the following instructions:

- Order
  - Submit Order
  - Amend Order
  - Cancel Order
- Collateral
  - Notify Deposit
  - Request Withdrawal
  - Validate Withdrawal
- Authentication
  - *To be confirmed*
- Governance
  - Propose Open Market
  - Propose Close Market
  - Propose Parameter
  - Vote for proposal
   
## Read

To *observe the operation, and validate the state of the protocol, we must be able to obtain data provided by the following domains:

### Market

- List markets available
	- Immutable market framework fields.
- Retrieve a market by market identifier.
   - All parameters for a market, from market definition.
- Observe creation of new markets.
- Observe market updates.

### Market data

- Retrieve and stream market data (all fields described in [0021-market-data-spec.md](./0021-MDAT-market_data_spec.md)) for a market
 
### Party

- List parties available.
- Retrieve a party by party identifier.
   - All parameters for a party, as specified by the party definition.
- Observe creation of new parties.
- Observe party updates.

### Order

- List orders on the book, for all markets, for a party.
- List orders on the book, for a particular market.
- Retrieve an order, if its on the book or parked, for a particular order identifier.
- Current order book depth, for a particular market.
- Order book depth deltas, for a particular market.
- Observe order updates, for all markets.
- Observe order updates, for a particular market.

### Trade

- Observe immutable trades that are created by all markets.
- Observe immutable trades that are created for a particular market and/or party.

### Collateral

- Current margin account balance for a party, per market, per asset.
- Current general account balance for a party, per asset.
- Observe creation of new collateral accounts.
- Observe collateral account updates.

### Risk

- Current risk factors, long and short, for a given market.

### Position
  
- Current long/short position for a party, if they have orders active on a market.
- Observe position changes for a party, if they have orders active on a market.
- Margin levels for the position (i.e. `margin { maintenance, search, initial, release }`)

### Statistics

- Statistics for each market, execution engine and blockchain.
- Observe statistics updates.


**Note: When we observe a particular domain, the data may need a mechanism to push changes to an observer (often known as a subscription), in addition to pulling the data from the source.*