# Connect Vega wallet + select keys

## Connect wallet for the first time

When looking to use Vega Via a user interface e.g. Dapp (Decentralized web App), I...

- **should** see a link to get a Vega wallet (in case I don't already have one) [xxxx-WCON-000](#xxxx-WCON-000 "xxxx-WCON-000")
- **should** see a link to connect that opens up connection options
- **must** select a connection method / wallet type:
- if Rest:
  - **must** have the option to input a non-default Wallet location
  - **should** warn if the dapp is unable the see a wallet is running at the wallet location 
  - **must** submit attempt to connect to wallet 
  - **could** trigger the app to open on the user's machine with a `vegawallet://` prompt
  
  - if the wallet does have an existing permission with the wallet: **must** see that wallet is connected
    - if the app uses one key at a time: **should** show what key is active (re-use the last active key)

  - if the wallet does not have an existing permission with the wallet: **must** prompt user to check wallet app to approve the request to connect wallet: See [Connecting to Dapps](0001-WALL-wallet.md#Connecting to dApps) for what should happen in wallet app
  
  - if new keys are given permission: **must** show the user the keys have been approved
    - **should** see public key(s)
    - **should** see alias(es)
    - **could** see assets on key(s)
    - **would like to** see positions on key(s)
    - if the dapp uses one key at a time: **should** prompt key selection. See [select/switch keys](#select-and-switch-keys).

  - if user rejects connection: **must** see a message saying that the request to connect was denied 
  
  - if the dapp is unable to connect for technical reason (e.g. CORS): **must** see an explanation of the error, and a method of fixing the issue 
  

- ~~Browser wallet~~ `not available yet`
  
- Fairground hosted wallet
  - **must** input a wallet name
  - **must** input a password 
  - if success: **must** see that the wallet is connected and details of connected key
  - if failure: **must** see reason for failure
  - *note: the fairground hosted wallet is configured to automatically approve connections from dapps so there is no need to key selection.*
  
- **must** have the option to select a different method / wallet type if I change my mind

... so I can use the interface read data about my key/party or request my wallet to broadcast transactions to a Vega network.

## Disconnect wallet

When wishing to disconnect my wallet, I...

- **must** see an option to disconnect wallet
- **should** see confirmation that wallet has been disconnected
- **should** see prompt to connect a wallet

... so that I can protect my wallet from malicious use or select a different wallet to connect to


## Select and switch keys

when looking to do something with a specific key (or set of keys) in my wallet, I...

- **must** see what key is currently selected (if any)
- **must** see an option to switch keys, and a list of keys that are approved from the connected wallet

- for each key:
  - **must** see the first and last 6 digits of the public key
  - **should** be able to see the whole public key
  - **must** be able to copy to clipboard the whole public key
  - **must** see the key name/alias (meta data)
  - **should** see what non-zero assets that kay has
  - **could** see the Total asst balances (inc associated)
  - **would like to see** a breakdown of the accounts. See [collateral / accounts](6000-COLL-collateral.md)
  - **would like to** see any active orders or positions. See [collateral / accounts](6000-COLL-collateral.md)

- see the option to trigger a re-authenticate so I can use newly created keys

...so that I can select the key(s) that I want to use.