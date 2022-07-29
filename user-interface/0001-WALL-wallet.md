# Wallet
A Vega wallet is required to submit transaction on the Vega chain (place cancel orders etc). See the [wallet docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-wallet) for more on how Crypto wallets work. 
A wallet can contain many public/private key pairs, The public part of each key pair is known the [Party](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0017-PART-party.md) sometimes just refereed to as a key. The primary job of a wallet app is to [authenticate a users actions](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0022-AUTH-auth.md).

## Get wallet
When on the wallet page of Vega.xyz I can...

- See links to the latest version of the desktop and command line wallets (inc github repos) <a name="0001-WALL-0001" href="#0001-WALL-0001">0001-WALL-0001</a>
- See a primary download button is configured for the latest version and the operating system I am using <a name="0001-WALL-0002" href="#0001-WALL-0002">0001-WALL-0002</a>

...so I can download and run the wallet app on my machine

## Set up wallet / Restore wallet
When opening the wallet for the first time, I...

- am prompted to opt into (or stay out of) analytics <a name="0001-WALL-0003" href="#0001-WALL-0003">0001-WALL-0003</a> `Must`
- can restore a wallet from a seed phrase <a name="0001-WALL-0004" href="#0001-WALL-0004">0001-WALL-2004</a>
- can create a new wallet <a name="0001-WALL-0005" href="#0001-WALL-2005">0001-WALL-2005</a>
  - shown back up phrase <a name="0001-WALL-0006" href="#0001-WALL-0006">0001-WALL-0006</a>
  - shown version number <a name="0001-WALL-0007" href="#0001-WALL-0007">0001-WALL-0007</a>
  - get the first key generated automatically <a name="0001-WALL-0008" href="#0001-WALL-0008">0001-WALL-0008</a>

...so I can sign transactions

## Configure network
When using the wallet on a network, I...

- get Mainnet and fairground pre-configured (with Mainnet being the default network) <a name="0001-WALL-0009" href="#0001-WALL-0009">0001-WALL-0009</a>
- can create a new network configuration <a name="0001-WALL-0010" href="#0001-WALL-0010">0001-WALL-0010</a>
- can refine the configuration for existing networks (including the ones that come pre-configured)
- `TODO` Changes to the validator set on a given network prompt a change/update to network config
- can remove networks

...so I can broadcast transactions to, and read information from a vega network in my app

## Update wallet
When using an older version of a Vega wallet, I...

- am prompted to download a newer version, and given a link to get latest on github
- am warned if the version I am using is not compatible with the version of Vega on the selected network, and given a link to get latest on github

...So the version of the ap I am using works with the network I am using

## Log in to a wallet
When using a given wallet, I...

- am required to enter wallet name + passphrase only once per "session"

... so that other users of my machine can not use my wallet, and I am not bothered frequently

## Connecting to dApps
When a dapp requests use of a wallet, I...

- am prompted user to either select a wallet or dismiss the prompt 
- `NOTYET` am required to select what keys of a wallet to grant access too
  - can select whole wallet (so that new keys are automatically shared)
  - can select specific keys
  - tainted keys are shown as tainted
- am required to enter wallet passphrase before wallet details are shared
- can retrospectively revoke Dapp's use to Wallet/keys

... so that I can control what public keys are shared with a dapp and what dapps can prompt me to sign transactions 

## Approving transactions
When a dapp sends a transaction to the wallet for signing and broadcast, I...

- am prompted to approve, reject or ignore the transaction (if auto approve is not on)
- can see [single key transaction](#single-key-transaction) details)
- can see any ignored/dismissed (not rejected or approved) in a transactions area (e.g. history)

... so that I can verify that the transaction being sent is the one I want

- `NOTYET` only auto approve some transaction types?

## View keys balances + positions/accounts
When looking for a specific balance or asset on a given wallet and network, I...

- can see key total balances of an asset on a given key
- can see a breakdown of all accounts for an asset on a key
- can see key balances when switching keys (to help me find the key I am looking for)
- can search by market name, and see all keys with a margin or liquidity account in that market
- can search by asset name or code, and see all keys with balance of matching assets
- can search for keys my arbitrary metadata added by user
- can see a total of all asset for all keys in a given wallet
 
... so that I can find the keys that I am looking for, see how much I have to consolidate (via transfers) or withdraw funds

## Key transactions
When thinking about a recent or specific transaction, I ...

- can see a history of transactions for a wallet and network
- can see pending transactions (Transactions I have not yet approved/rejected)
- can see transactions that have recently been broadcast but not yet seen on the chain
- can see transactions that were rejected by the wallet user (me)
- (for tainted keys) there is a record of attempts to use a tainted key (these did not prompt the user, but allows a user to change permissions)

... so that I can see what has happened and when

## Single key transaction
when looking at a specific transaction...

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
When using vega, I...

- can create new keys (derived from the source of the first)
- am prompted to give keys and alias (optional)
- can see and/or copy to clipboard the full public key
- can change key name/alias
- can amend other arbitrary key meta data

... so that I can isolate risk to a given key (aka isolate margin), mitigate the risk of a key being comprised, or use multiple trading strategies 

## Taint keys
When protecting myself from use of keys that may be compromised, I..

- can select a key I wish to taint
- am prompted to enter wallet password to taint key
- (tainted keys will not prompt a prompt to sign transaction)
- can see tainted keys as flagged as tainted

... so that tainted keys can not be used

When I have accidentally tainted a key I...

- Can select a key to un-taint by entering wallet password

...so that I can use the key again

## Isolate keys
See [docs on key isolation](https://docs.vega.xyz/docs/mainnet/tools/vega-wallet/cli-wallet/latest/guides/isolate-keys)
When I want to create an extra level of security for a given key, I...

- `NOTYET` can select a key that I want to isolate
- `NOTYET` am prompted for a password before isolation
- `NOTYET` am instructed as to where the wallet file has been created

... so I can store some keys in an extra secure way

## Manually sign a message
When wishing to use my wallet to sign arbitrary messages, I...

- can enter content to be signed with key
- see an option to base64 encode content before signing
- see option to broadcast that to the selected network
- can sign the content and am given a hash of the signed content as well as the message (now encoded)

.. so that I know and can control the details of the message being signed, and can use the message elsewhere (for example to prove I own a wallet)

## Deposit / withdraw / transfer
- `TODO` See prompts to do these things, where do they go? Eth connection?

## Wallet management
When seeking to reduce risk of compromise I...

- can create multiple wallets
- can switch between wallets
- can delete a wallet
- can change wallet name
- can change wallet passphrase
- `NOTYET` can get the recovery phrase for a wallet (at any time not just creation)

... so that I can administrate my wallets

## App settings (Not sure if this needs AC?)
- Link or lock a key to a given network
