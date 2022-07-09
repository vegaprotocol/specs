# Wallet
A Vega wallet is required for all actions on the Vega chain. See the [wallet docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-wallet) for more on how Crypto wallets work. Wallet gives you multiple keys, each key has a public key that is also known as a [Party](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0017-PART-party.md). The primary job of a wallet app is to [authenticate a users actions](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0022-AUTH-auth.md).

## Get wallet
When on the wallet page of Vega.xyz...
- There are links to the latest version of the desktop and command line wallets
- a primary download button is configured for the latest version and the operating system I am using

## Update wallet
When using an existing Vega wallet, I am...
- shown there there is a newer version than the one I am using, and given a link to get latest
- warned if the version I am using is not compatible with the version of Vega on the selected network, and given a link to get latest

## Set up wallet / Restore wallet
When opening the wallet for the first time...
- Asked to opt into Analytics
- Can restore a wallet from a seed phrase
- Can Create a new wallet
  - Shown nemonic
  - Shown version number
  - Creating a wallet generates the first key

## Configure network
- Mainent and fairground come pre-configured
- `TODO` Changes to the validator set on a given network prompt a change/update to network config
- Can set up own network
- Can refine the configuration for built in networks
- can see and edit the list of networks 

## Log in to a wallet
- Requires wallet name + passphrase

## Connecting to dApps
When a dapp requests use of a wallet...
- prompts user to either select a wallet or dismiss the prompt 
- `NOTYET` Requires the user to select what keys of a wallet to share
  - Can select all keys (so that new keys are automatically shared)
  - Can select specific keys
- requires the user to enter passphrase before wallet details are shared
... for use by that specific dapp (identified by a URL)
- Can revoke wallet/key - Dapp permisions

## Approving transactions
When a dapp sends a trasnaction to the wallet for signing and broadcast...
- prompts user (if auto approve is not on)
- shown the content of the transaction that is being shown
- shows the time request was made
- Shows the dapp that made the request
- user can select to approve, reject or dismiss
- shown what wallet + key is being used
- prompted to enter passphrase if needed (or not if in session)
- Can select auto approve for this app (aka don't ask me again)
- Pending transaction shown in "key transactions" area
- Shows status of broadcast transactions
- Links to block explorer 

## Create key
- Can create new keys
- Prompted to give keys and alias (optional)
- See/copy full public key

## Key management
- Can edit key aliases (and other metadata)

## View keys balances
- Can see key balances, a total for each asset (for a given network), For selected keys
- Can see a breakdown of all accounts for an asset on a key
- Can see key balances when switching keys
- Can search all keys for asset

## Key transactions
- Can see a history of balances for a given key and network)
  - can see pending transactions (Transactions I have not yet approved)
  - hash
  - date/time
  - transaction content decoded
  - `TODO` ...

## Taint keys

## isolate keys

## Manually sign content
- enter content to be signed with key
- option to base64 encode content before signing
- option to broadcast that to the selected network

## Deposit / withdraw / transfer
- `TODO` See prompts to do these things, where do they go? Eth connection?

## Wallet management
- Can create multiple wallets
- Can switch between wallets
- Can delete wallets
- Can change wallet name
- Can change wallet passphrase
- can back up wallets (get the recovery phrase)

## App settings (Not sure if this needs AC?)
- Link or lock a key to a given network