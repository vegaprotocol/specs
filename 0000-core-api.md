# Core APIs

## Transactions

Submit API to post to consensus layer
Get API to retrieve status of submitted TX

TODO: list all transactions here


## Read APIs

### Market (Framework):

TODO: short description

Data returned:
- xxxx

APIs
- Get All
- Get by market ID

### Market Data (= mark price, ...):
- By market ID

Risk data (= risk factors, ...):
- By market ID

// maybe N/A for Nicenet?
Assets (= short code, source chain, full blockchain ref., decimal places, ...):
- By ID..

Order:
- By ID
- By sender party ID (filters: status, timestamp)
- By market ID (filters: status, timestamp)

Trade:
- By ID
- By sender party ID (filters: status, timestamp)
- By market ID (filters: status, timestamp)

Party:
- By ID
- All (filter: open positions)
- Market, (filter: open positions or any positions)

Position:
- ...

Accounts:
- By party ID (filter: type, asset, non-zero balance)
- By market ID (filter: type, asset, non-zero balance)
- All (filter: type, asset, non-zero balance)

Transfers (= req id, transfer id? - multiple rows with a req5 ID are possible if multiple accounts are hit, type, market [opt], from acc, to acc, requested amount, transferred): // all requested including unsuccessful search
- By party ID (filter: type, asset)
- By account ID (filter: from/to, type)
- By market ID (filter: type, asset)
- All (filter: type, asset)