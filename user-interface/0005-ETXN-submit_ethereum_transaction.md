# Submit Ethereum transaction

## Know transaction I'm signing
When about to click to prompt Eth wallet to sign a transaction, I...

- **should** see the contract address I am about to interact with
- **should** see the function name I am about to interact with

...so I know what to expect when my wallet asks me to sign
## Track transactions to wallet

after clicking to submit an eth transaction to a connected wallet, I...

- **must** see prompt to check Ethereum wallet to approve transactions

... so I know I need to go to my wallet app to approve the transaction
## Tracking Eth transactions on Ethereum
after approving a transaction in my wallet app, I...

- **should** see link to the transaction etherscan
- **must** see the transactions status (Pending, confirmed, etc) on Ethereum by reading Ethereum (via connected wallet or the back up node specified in the app) 
- **must** see how many blocks ago the transaction was confirmed by the eth node being read

... so I can see the status of the transaction and debug as apropriate
## Tracking eth transactions having their affect on Vega
Note: it is common for inter-blockchain applications to wait a certain amount of block before crediting money, as this reduces the risk of double spend in the case of forks or chain roll backs. There is a Vega environment variable the defines how long vega waits.

Uf the eth transaction I've just submitted changes the state of the Vega network (e.g. a deposit from eth appearing as credited to my vega key on vega), I...

- **should** see how many Ethereum blocks Vega needs to wait before changing the state of Vega
- **should** see how many blocks have passed or remain until the required number has been met
- **must** see whether the expect action has taken place on Vega (e.g. credited Vega key)

... so I know vega has been updated with the current 