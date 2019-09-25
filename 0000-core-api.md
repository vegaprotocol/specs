Feature name: Core API Specification
Start date: YYYY-MM-DD

# Transactions

Submit an API request to post a transaction to the consensus layer. Use an API read call to retrieve the status of submitted transaction.

## Transaction types

- Authentication
  - TBC
- Collateral
  - Deposit
  - Withdraw
- Order
  - Amend
  - Cancel
  - Submit
- TBC

# Read API calls

## Market Framework data

Market framework data is immutable metadata specifying a Market.

Market metadata returned:
- ID
- name
- tradeable instrument
- decimal places (used in UI)
- trading mode (continuous / discrete)

### API calls

- Get all Markets
- Get Market by ID

## Market Data

Market data is data that changes (or at least can change) over time, contained in a running market.

### API calls

- Candles (TBC: core?)
- Depth
- Orders
- Parties (filters: all, with open positions)
- Trades
- Risk data (incl risk factors, ...)

## Account data

TBD: short description

### API calls

- all (filter: type, asset, non-zero balance)
- by market ID (filter: type, asset, non-zero balance)
- by party ID (filter: type, asset, non-zero balance)

## Asset data

Asset data returned:
- short code
- source chain
- full blockchain reference
- decimal places
- TBC

### API calls

- all (filters: TBC)
- by ID

## Collateral data

TBD: short description

### API calls

- TBD

## Market depth data

Market depth summarises the order book at price levels. Buy and sell side are sorted (buy: descending; sell: ascending) such that the first entries in each list are closest to the middle of the market.

Market depth data returned:
- Buy side (sorted by price descending)
  - price
  - number of orders
  - volume at this price only
  - cumulative volume
- Sell side (sorted by price ascending)
  - data as on Buy side

### API calls

- by Market ID

## Order data

Order data returned:

- TBD

### API calls

- all (filters: party ID)
- by ID (post-consensus, having been accepted or rejected)
- by Reference (pre-consensus, not yet having been accepted or rejected)

## Party data

TBD: short description

### API calls

- all (filter: open positions)
- by ID

## Positions data

### API calls

- TBD

## Trade data

TBD: short description

### API calls

- all (filters: order ID; sender party ID; status; timestamp)
- by ID

## Transfer data

Transfer data returned:
- request ID
- transfer ID (TBC)

Notes:
- multiple rows with a request ID are possible if multiple accounts are hit, type, market [opt], from acc, to acc, requested amount, transferred): // all requested including unsuccessful search

### API calls

- all (filter: type, asset)
- by party ID (filter: type, asset)
- by account ID (filter: from/to, type)
- by market ID (filter: type, asset)
