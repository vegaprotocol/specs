# Connect Ethereum wallet

Dapps can connect to an Ethereum wallet to complete Ethereum transactions such as Deposits and withdraws to/from Vega,  Association and others.
There is a standard-ish pattern that Dapps can use for doing so but an evolving standard for how these are displayed to the user.

## Connecting

When wanting or needing to use Ethereum, I...

- **must** see a link to connect

first use (no connection to restore):

- **must** select the method for connecting to the wallet (e.g. wallet connect, injected / metamask)
- **must** be prompt to check eth wallet (while the dapp waits for a response)
- if the app gets multiple keys the user **should** be shown the keys returned and given a Ui to select a key for use. but in many cases Dapps default to key 0 in the array.

after first use (if there is a connection to restore):

- **should** recovered previous connection / prompt wallet to grant access
- **should** see a link top trigger a fresh connection/ fetch new keys (in in the case where I now want to use a different wallet to the one I was connected with) [[[TBD Link to ac about multi key select]]]

When connected:

- **must** see the connected ethereum wallet [Public key](7001-DATA-data_display.md#public-keys)

... so I can use sign and broadcast Ethereum transactions, use a key address as in input, or read data from ethereum via my connected wallet 

## Disconnecting

When I'm finished using a connected Ethereum wallet I may wish to disconnect...

- **must** see a link to disconnect 
- **must** destroy all session so that hitting connect again connects as if it is the first use
- **should** see a connect button to start a fresh connection

... so that I can use a different wallet, or ensure may wallet can not be used by other apps