# Submit Vega transaction

A dapp sends a transaction to a wallet, that wallet then broadcasts the transaction to a network.  Therefore the following is broken up into two steps. The transaction could fail at either. Generally: Once the transaction has gone to the network a user can use block explorer to track the transaction, but some tracking in Dapp or wallet will help.

When submitting a Vega transaction of any kind, I...

## Track transaction to wallet

if not connected to a Vega wallet:

- **must** be told that I am not connected and given the [option to connect](0012-WCON-connect_vega_wallet.md) (<a name="0003-WTXN-001" href="#0003-WTXN-001">0003-WTXN-001</a>)

if transaction not auto approved by wallet:

- **must** see a prompt to check connected vega wallet to approve transaction (<a name="0003-WTXN-002" href="#0003-WTXN-002">0003-WTXN-002</a>)

if order is approved by wallet:

- **must** see A [transaction hash](7001-DATA-data_display.md#transaction-hash) (<a name="0003-WTXN-003" href="#0003-WTXN-003">0003-WTXN-003</a>)
- **must** see the public key that this transaction was submitted for (<a name="0003-WTXN-004" href="#0003-WTXN-004">0003-WTXN-004</a>)
- **should** see the alias for the key that submitted this transaction (<a name="0003-WTXN-005" href="#0003-WTXN-005">0003-WTXN-005</a>)
- **could** see a prompt to set this app to [auto approve](0001-WALL-wallet.md#approving-transactions) in wallet app (<a name="0003-WTXN-006" href="#0003-WTXN-006">0003-WTXN-006</a>)

if transaction is rejected by wallet:

- **must** see that the order was rejected by the connected wallet (<a name="0003-WTXN-007" href="#0003-WTXN-007">0003-WTXN-007</a>)

if the wallet does not respond:

- **must** be able to cancel attempt to submit transaction (<a name="0003-WTXN-008" href="#0003-WTXN-008">0003-WTXN-008</a>)

if the wallet highlights an issue with the transaction:

- **must** show that the transaction was marked as invalid by the wallet and not broadcast (<a name="0003-WTXN-009" href="#0003-WTXN-009">0003-WTXN-009</a>)
- **should** see the error returned highlighted in context of the form that submitted the transaction in Dapp (<a name="0003-WTXN-010" href="#0003-WTXN-010">0003-WTXN-010</a>)
- **must** show error returned by wallet (<a name="0003-WTXN-011" href="#0003-WTXN-011">0003-WTXN-011</a>)

## Track transaction on network 

- **must** see a link to that transaction in a block explorer for the appropriate network (<a name="0003-WTXN-012" href="#0003-WTXN-012">0003-WTXN-012</a>)
- **must** see the transaction status - TODO Document these (<a name="0003-WTXN-013" href="#0003-WTXN-013">0003-WTXN-013</a>)
- **must** see the network the transaction was broadcast to (<a name="0003-WTXN-018" href="#0003-WTXN-018">0003-WTXN-018</a>)
- **must** see the block the transaction was processed in (<a name="0003-WTXN-014" href="#0003-WTXN-014">0003-WTXN-014</a>)
- **must** show the node the transaction was broadcast to (<a name="0003-WTXN-015" href="#0003-WTXN-015">0003-WTXN-015</a>)
- **must** see the validator that processed the block the transaction was processed in (<a name="0003-WTXN-016" href="#0003-WTXN-016">0003-WTXN-016</a>)
- **must** see the content of the transaction as seen by the network (<a name="0003-WTXN-017" href="#0003-WTXN-017">0003-WTXN-017</a>)

... so I am aware of the transactions status of the transactions my wallet is sending and that are being processed by the network