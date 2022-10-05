# Connect Ethereum wallet

Dapps can connect to an Ethereum wallet to complete Ethereum transactions such as Deposits and withdraws to/from Vega,  Association and more.

## Connecting wallet

When wanting or needing to write to Ethereum, I...

- **must** see a link to connect that opens connection options

- if first time:
  - **must** select a connection method / wallet type: (e.g. wallet connect, injected / metamask)
  - **must** be prompt to check eth wallet (while the dapp waits for a response)
  - **must** see an option to cancel the attempted connection (if the wallet fails to respond)
  - if the app gets multiple keys the user: 
    - **should** be shown the keys returned and given a UI to select a key for use
    - **should** be prompted to select one (in many cases Dapps default to key 0 in the array)
- after first use (if there is a connection to restore):
  - **must** prompt wallet to grant access
  - **should** see previous connection has been recovered
  - **should** see a link to trigger a fresh connection / fetch new keys (in in the case where I now want to use a different wallet to the one I was connected with) [[[TBD Link to ac about multi key select]]]
- once connected:
  - **must** see the connected ethereum wallet [Public key](7001-DATA-data_display.md#public-keys) 

... so I can sign and broadcast Ethereum transactions, use a key address as in input, or read data from ethereum via my connected wallet 

## Disconnecting

When I'm finished using a connected Ethereum wallet I may wish to disconnect...

- **must** see a link to disconnect 
- **must** destroy all session so that hitting connect again connects as if it is the first use
- **should** see a connect button to start a fresh connection (e.g. to a different wallet but via Wallet connect)

... so that I can use a different wallet, or ensure may wallet can not be used by other apps 