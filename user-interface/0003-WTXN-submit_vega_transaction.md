# Submit Vega transaction

When submitting a Vega transaction of any kind, I...

## track transaction to wallet

if not connected to a Vega wallet:

- **must** be told that I am not connected and given the [option to connect](0002-WCON-connect_vega_wallet.md)

if transaction not auto approved:

- **must** see a prompt to check connected vega wallet to approve transaction

if order is approved by wallet:

- **must** see A hash/Id transaction ID 
- **must** see the public key that this transaction was submitted for 
- **should** see the alias for the key that submitted this transaction
- **could** see a prompt to see this app to [auto approve](0001-WALL-wallet.md#approving-transactions) in wallet app

if transaction is rejected by wallet:

- **must** see that the order was rejected by the connected wallet

if the wallet does not respond:

- **must** be able to cancel attempt to submit transaction

if the wallet highlights an issue with the transaction:

- **must** show that the transaction was marked as invalid by the wallet and not broadcast
- **should** see the error returned highlighted in context of the form that submitted the transaction in Dapp
- **must** show error returned by wallet

## Track transaction on network 
Generally: These should be done in block explorer, could be done in wallet and would like to be done in the app that submitted.

- **must** see a link to that transaction in a block explorer for the appropriate network
- **must** see the transaction status - TODO Document these
- **must** see the block the transaction was processed in
- **must** show the node the transaction was broadcast in
- **must** see the validator that processed the block the transaction was processed in
- **must** see the content of the transaction as seen by the network

... so I am aware of the transactions status interns of being sent to and processed by the network