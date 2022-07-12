# Wallet
A Vega wallet is required for all actions on the Vega chain. See the [wallet docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-wallet) for more on how Crypto wallets work. Wallet gives you multiple keys, each key has a public key that is also known as a [Party](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0017-PART-party.md). The primary job of a wallet app is to [authenticate a users actions](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0022-AUTH-auth.md).

## Get wallet
When on the wallet page of Vega.xyz I can..
- See links to the latest version of the desktop AND command line wallets (as well as github pages)
- See a primary download button is configured for the latest version and the operating system I am using

## Set up wallet / Restore wallet
When opening the wallet for the first time, I..
- am prompted to opt into Analytics
- can restore a wallet from a seed phrase
- can create a new wallet
  - shown back up phrase
  - shown version number
  - get the first key generated automatically

## Configure network
When using the wallet on a network, I..
- get Mainnet and fairground pre-configured (with Mainnet being the default network)
- can create a new network configuration
- can refine the configuration for existing networks (including the ones that come pre-configured)
- `TODO` Changes to the validator set on a given network prompt a change/update to network config
- can remove networks

## Update wallet
When using an older version of a Vega wallet, I..
- am prompted to download a newer version, and given a link to get latest on github
- am warned if the version I am using is not compatible with the version of Vega on the selected network, and given a link to get latest on github

## Log in to a wallet
When using a given wallet, I..
- am required to enter wallet name + passphrase only once per "session"

## Connecting to dApps
When a dapp requests use of a wallet, I..
- am prompted user to either select a wallet or dismiss the prompt 
- `NOTYET` am required to select what keys of a wallet to grant access too
  - can select whole wallet (so that new keys are automatically shared)
  - can select specific keys
  - tainted keys are shown as tainted
- am required to enter wallet passphrase before wallet details are shared
- can retrospectively revoke Dapp's use to Wallet/keys
.. so that I can control what public keys are shared with a dapp and what dapps can prompt me to sign transactions 

## Approving transactions
When a dapp sends a transaction to the wallet for signing and broadcast, I..
- am prompted to approve, reject or ignore the transaction (if auto approve is not on)
- can see [single key transaction](#single-key-transaction) details)
- can see any ignored/dismissed (not rejected or approved) in a transactions area (e.g. history)

.. so that I can verify that the transaction being sent is the one I want

- `NOTYET` only auto approve some transaction types?

## View keys balances + positions/accounts
When looking for a specific balance or asset on a given wallet and network, I..
- can see key total balances of an asset on a given key
- can see a breakdown of all accounts for an asset on a key
- can see key balances when switching keys (to help me find the key I am looking for)
- can search by market name, and see all keys with a margin or liquidity account in that market
- can search by asset name or code, and see all keys with balance of matching assets
- can search for keys my arbitrary metadata added by user
- can see a total of all asset for all keys in a given wallet
.. so that I can find the keys that I am looking for, see how much I have to consolidate (via transfers) or withdraw funds

## Key transactions
When thinking about a recent or specific transaction, I ..
- can see a history of transactions for a wallet and network
- can see pending transactions (Transactions I have not yet approved/rejected)
- can see transactions that have recently been broadcast but not yet seen on the chain
- can see transactions that were rejected by the wallet user (me)
- (for tainted keys) there is a record of attempts to use a tainted key (these did not prompt the user, but allows a user to change permissions)

.. So that I can see what has happened and when

## Single key transaction
when looking at a specific transaction..
- can see the content of the transaction that is being shown
- can see the time request was made
- can see the dapp that made the request
- can see what wallet / key is being used
- can select auto approve for this app (aka don't ask me again)
- am prompted to enter passphrase (if needed)
- can see status of broadcast transactions
- can follow a link to block explorer for broadcast transactions
- can see what node it was broadcast to
- can see what validator mined the block the transaction was included in
- can see at what block and time it was confirmed
- can see if there was a reported error/issue, and the details of the issue
- can see if the transaction was rejected

.. so that I might be able to find all the information about what has happened with mined and un-mind transactions

## Key management
When using vega, I..
- can create new keys (derived from the source of the first)
- am prompted to give keys and alias (optional)
- can see and/or copy to clipboard the full public key
- can change key name/alias
- can amend other arbitrary key meta data
.. so that I can isolate risk to a given key (aka isolate margin), mitigate the risk of a key being comprised, or use multiple trading strategies 

## Taint keys
When protecting myself from use of keys that may be compromised, I..
- can select a key I wish to taint
- am prompted to enter wallet password to taint key
- (tainted keys will not prompt a prompt to sign transaction)
- can see tainted keys as flagged as tainted

.. so that tainted keys can not be used

When I have accidentally tainted a key I..
- Can select a key to un-taint by entering wallet password

..so that I can use the key again

## Isolate keys
See [docs on key isolation](https://docs.vega.xyz/docs/mainnet/tools/vega-wallet/cli-wallet/latest/guides/isolate-keys)
When I want to create an extra level of security for a given key, I..
- `NOTYET` can select a key that I want to isolate
- `NOTYET` am prompted for a password before isolation
- `NOTYET` am instructed as to where the wallet file has been created

## Manually sign a message
When wishing to use my wallet to sign arbitrary messages, I..
- can enter content to be signed with key
- see an option to base64 encode content before signing
- see option to broadcast that to the selected network
- can sign the content and am given a hash of the signed content as well as the message (now encoded)

.. so that I know and can control the details of the message being signed, and can use the message elsewhere (for example to prove I own a wallet)

## Deposit / withdraw / transfer
- `TODO` See prompts to do these things, where do they go? Eth connection?

## Wallet management
When seeking to reduce risk of compromise I..
- can create multiple wallets
- can switch between wallets
- can delete a wallet
- can change wallet name
- can change wallet passphrase
- `NOTYET` can get the recovery phrase for a wallet (at any time not just creation)

## App settings (Not sure if this needs AC?)
- Link or lock a key to a given network