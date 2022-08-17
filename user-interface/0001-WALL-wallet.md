# Wallet
A Vega wallet is required to prepare and submit transaction on Vega  (place, cancel, orders etc). See the [wallet docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-wallet) for more on how "crypto" wallets work. 

A wallet can contain many public/private key pairs. The public part of each key pair is known the [Party](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0017-PART-party.md) sometimes just referred to as a key or public key. The primary job of a wallet app is to [authenticate a user's actions](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0022-AUTH-auth.md).

## Get wallet
When on the wallet page of Vega.xyz, I...

- **must** see links to the latest version of the desktop and command line wallets (inc github repos) <a name="0001-WALL-001" href="#0001-WALL-001">0001-WALL-001</a>
- **must** see a primary download button is configured for the latest version and the operating system I am using <a name="0001-WALL-002" href="#0001-WALL-002">0001-WALL-002</a>

...so I can download and run the wallet app on my machine and use it to interact with the Vega mainnet

## Set up wallet / Restore wallet
When opening the wallet for the first time, I...

- **must** be prompted to opt into (or stay out of) analytics <a name="0001-WALL-003" href="#0001-WALL-003">0001-WALL-003</a>
- **must** be able to restore a wallet from a seed phrase <a name="0001-WALL-004" href="#0001-WALL-004">0001-WALL-004</a>
- **must** be able to create a new wallet <a name="0001-WALL-005" href="#0001-WALL-005">0001-WALL-005</a>
  - **must** be shown the back up phrase <a name="0001-WALL-006" href="#0001-WALL-006">0001-WALL-006</a>
  - **must** shown version number <a name="0001-WALL-007" href="#0001-WALL-007">0001-WALL-007</a>
  - **must** see the first key without having to "add key" <a name="0001-WALL-008" href="#0001-WALL-008">0001-WALL-008</a>

...so I can sign transactions

## Configure network
When using the wallet on a network, I...

- **must** have Mainnet and Fairground (testnet) pre-configured (with Mainnet being the default network) <a name="0001-WALL-009" href="#0001-WALL-009">0001-WALL-009</a>
- **must** be able to create a new network configuration  <a name="0001-WALL-010" href="#0001-WALL-010">0001-WALL-010</a>
- **must** be able refine the configuration for existing networks (including the ones that come pre-configured) <a name="0001-WALL-011" href="#0001-WALL-011">0001-WALL-011</a>
- **must** be able to remove networks <a name="0001-WALL-013" href="#0001-WALL-013">0001-WALL-013</a>

...so I can broadcast transactions to, and read information from a vega network in my wallet app

## Update wallet
When using an older version of a Vega wallet than the current official release, I...

- **must** be prompted to download a newer major release version, and given a link to get latest on github <a name="0001-WALL-014" href="#0001-WALL-014">0001-WALL-014</a>
- **must** be warned if the version I am using is not compatible with the version of Vega on the selected network, and I am given a link to get latest compatible version on github <a name="0001-WALL-015" href="#0001-WALL-015">0001-WALL-015</a>

... so the version of the wallet app I am using works with the network I am using

## Log in to a wallet
When using a given wallet, I...

- **must** select a wallet and enter the pasphrase only once per "session" <a name="0001-WALL-016" href="#0001-WALL-016">0001-WALL-016</a>

... so that other users of my machine can not use my wallet, and I am not asked to re-enter frequently

## Connecting to Dapps
When a dapp requests use of a wallet, I...

- **must** be prompted to either select a wallet or dismiss the prompt  <a name="0001-WALL-017" href="#0001-WALL-017">0001-WALL-017</a>
- `TODO` am required to select what keys of a wallet to grant access to <!--<a name="0001-WALL-018" href="#0001-WALL-018">0001-WALL-018</a>-->
  - `TODO:` **must** be able to select whole wallet (so that new keys are automatically shared)  <!--<a name="0001-WALL-019" href="#0001-WALL-019">0001-WALL-019</a>-->
  - `TODO:` **must** be able to select specific [keys](7001-DATA-data_display.md#public-keys)<!-- <a name="0001-WALL-020" href="#0001-WALL-020">0001-WALL-020</a> -->
  - `TODO` tainted keys **must** be shown as tainted <a name="0001-WALL-021" href="#0001-WALL-021">0001-WALL-021</a>
- **must** enter wallet passphrase before wallet details are shared <a name="0001-WALL-022" href="#0001-WALL-022">0001-WALL-022</a>
- **must** be able to retrospectively revoke Dapp's access to Wallet/keys <a name="0001-WALL-023" href="#0001-WALL-023">0001-WALL-023</a>

... so that I can control what public keys are shared with a dapp and what dapps can prompt me to sign transactions 

## Approving transactions
When a dapp sends a transaction to the wallet for signing and broadcast, I...

- **must** be prompted to approve, reject or ignore the transaction (if auto approve is not on) <a name="0001-WALL-024" href="#0001-WALL-024">0001-WALL-024</a>
- **must** see the details of the transaction. See [details of transaction](#transaction-detail). <a name="0001-WALL-025" href="#0001-WALL-025">0001-WALL-025</a>
- **must** see any ignored/dismissed in a transactions area along with pending, approved and rejected transactions (e.g. history). See [Transactions](#transactions).

... so I can verify that the transaction being sent is the one I want

## View keys balances + positions/accounts
When looking for a specific balance or asset on a given wallet and network, I...

- **must** see total balances of an asset for each key <a name="0001-WALL-027" href="#0001-WALL-027">0001-WALL-027</a>
- **must** see a breakdown of all accounts for an asset on a key <a name="0001-WALL-028" href="#0001-WALL-028">0001-WALL-028</a>
- **should** see a summary of balances when switching keys (to help me find the key I am looking for) <a name="0001-WALL-029" href="#0001-WALL-029">0001-WALL-029</a>
- **would like to** be able to search by market name/code, and see all keys with a margin or liquidity account in matching markets <a name="0001-WALL-030" href="#0001-WALL-030">0001-WALL-030</a>
- **should** be able to search by asset name or code, and see all keys with balance of matching assets <a name="0001-WALL-031" href="#0001-WALL-031">0001-WALL-031</a>
- **should** be able to search for arbitrary metadata added by user to keys <a name="0001-WALL-032" href="#0001-WALL-032">0001-WALL-032</a>
- **must** be able to see a total of all asset for all keys in a given wallet <a name="0001-WALL-033" href="#0001-WALL-033">0001-WALL-033</a>
 
... so that I can find the keys that I am looking for, see how much I have to consolidate (via transfers) or withdraw funds

## Transactions
When thinking about a recent or specific transaction, I ...

- **must** see a history of transactions for a wallet and network <a name="0001-WALL-034" href="#0001-WALL-034">0001-WALL-034</a>
- **must** see pending transactions (Transactions I have not yet approved/rejected) <a name="0001-WALL-035" href="#0001-WALL-035">0001-WALL-035</a>
- **must** see transactions that have recently been broadcast but not yet seen on the chain <a name="0001-WALL-036" href="#0001-WALL-036">0001-WALL-036</a>
- **must** see transactions that were rejected by the wallet user (me) <a name="0001-WALL-037" href="#0001-WALL-037">0001-WALL-037</a>
- (for tainted keys) **should** see attempts to use a tainted key (these did not prompt the user, but allows a user to change permissions) <a name="0001-WALL-038" href="#0001-WALL-038">0001-WALL-038</a>

... so that I can ensure my wallet is being used appropriately and find transaction I might have missed

## Transaction detail
when looking at a specific transaction...

- **must** see the content of the transaction decoded <a name="0001-WALL-039" href="#0001-WALL-039">0001-WALL-039</a>
- **must** see the time request to sign and send was made <a name="0001-WALL-040" href="#0001-WALL-040">0001-WALL-040</a>
- **should** see the dapp that made the request <!-- <a name="0001-WALL-041" href="#0001-WALL-041">0001-WALL-041</a> -->
- **must** see what wallet / key is being used <a name="0001-WALL-042" href="#0001-WALL-042">0001-WALL-042</a>
- **should** be able to select auto approve for this app (aka don't ask me again) <!-- <a name="0001-WALL-043" href="#0001-WALL-043">0001-WALL-043</a> -->
- **must** be prompted to enter passphrase (when needed to sign + broadcast transaction) <a name="0001-WALL-044" href="#0001-WALL-044">0001-WALL-044</a>
- **must** see [status of broadcasted transactions](0003-WTXN-submit_vega_transaction.md#track-transaction-on-network). <a name="0001-WALL-045" href="#0001-WALL-045">0001-WALL-045</a>
- **must** be able to follow a link to block explorer for broadcasted transactions <a name="0001-WALL-046" href="#0001-WALL-046">0001-WALL-046</a>
- **should** see what node it was broadcast to <a name="0001-WALL-047" href="#0001-WALL-047">0001-WALL-047</a>
- **could** see what validator mined the block the transaction was included in <a name="0001-WALL-048" href="#0001-WALL-048">0001-WALL-048</a>
- **must** see at what block and time it was confirmed <a name="0001-WALL-049" href="#0001-WALL-049">0001-WALL-049</a>
- **must** see if there was a reported error/issue, and the details of the issue <a name="0001-WALL-050" href="#0001-WALL-050">0001-WALL-050</a>
- **must** see if the transaction was rejected, and why <a name="0001-WALL-051" href="#0001-WALL-051">0001-WALL-051</a>

.. so I can find all the information about what has happened with mined and un-mined transactions

## Key management
When using a Vega wallet, I...

- **must** be able to create new keys (derived from the source of wallet) <a name="0001-WALL-052" href="#0001-WALL-052">0001-WALL-052</a>
- **should** be prompted to give keys an alias (user can ignore) <a name="0001-WALL-053" href="#0001-WALL-053">0001-WALL-053</a>
- **must** see full public key or be able to copy it to clipboard <a name="0001-WALL-054" href="#0001-WALL-054">0001-WALL-054</a>
- **must** be able to change key name/alias <a name="0001-WALL-055" href="#0001-WALL-055">0001-WALL-055</a>
- **must** be able to amend other arbitrary key meta data <a name="0001-WALL-056" href="#0001-WALL-056">0001-WALL-056</a>

... so I can manage risk (e.g. isolate margin), mitigate the damage of a key being compromised, or use multiple trading strategies 

## Taint keys
When protecting myself from use of keys that may be compromised, I..

- **must** select a key I wish to taint <a name="0001-WALL-057" href="#0001-WALL-057">0001-WALL-057</a>
- **must** be prompted to enter wallet password to taint key <a name="0001-WALL-058" href="#0001-WALL-058">0001-WALL-058</a>
- (Dapps that request use of tainted keys **must** not prompt a prompt user to sign transaction) <a name="0001-WALL-059" href="#0001-WALL-059">0001-WALL-059</a>
- **must** see tainted keys flagged as tainted <a name="0001-WALL-060" href="#0001-WALL-060">0001-WALL-060</a>

... so that tainted keys must not be used

When I have accidentally tainted a key I...

- **must** select a key to un-taint and be required to enter wallet password <a name="0001-WALL-061" href="#0001-WALL-061">0001-WALL-061</a>

...so that I must use the key again

## Isolate keys
See [docs on key isolation](https://docs.vega.xyz/docs/mainnet/tools/vega-wallet/cli-wallet/latest/guides/isolate-keys)
When I want to create an extra level of security for a given key, I...

- `TODO` must select a key that I want to isolate
- `TODO` am prompted for a password before isolation
- `TODO` am instructed as to where the wallet file has been created

... so I must store some keys in an extra secure way

## Manually sign a message
When wishing to use my wallet to sign arbitrary messages, I...

- **must** enter content to be signed with key  <a name="0001-WALL-062" href="#0001-WALL-062">0001-WALL-062</a>
- **must** see an option to base64 encode content before signing <a name="0001-WALL-063" href="#0001-WALL-063">0001-WALL-063</a>
   - **should** only have the option to broadcast valid Vega transactions to a selected network <a name="0001-WALL-064" href="#0001-WALL-064">0001-WALL-064</a>
- **must** be able to submit/sign the content and am given a hash of the signed content as well as the message (now encoded) <a name="0001-WALL-065" href="#0001-WALL-065">0001-WALL-065</a>
  - **must** be able to [track progress](0003-WTXN-submit_vega_transaction.md#track-transaction-on-network) of broadcast transaction <a name="0001-WALL-071" href="#0001-WALL-071">0001-WALL-071</a>

.. so I can control of the message being signed, and can use the message elsewhere (for example to prove I own a wallet)

## Wallet management
When seeking to reduce risk of compromise I...

- **must** be able to create multiple wallets <a name="0001-WALL-066" href="#0001-WALL-066">0001-WALL-066</a>
- **must** be able to switch between wallets <a name="0001-WALL-067" href="#0001-WALL-067">0001-WALL-067</a>
- **must** be able to delete a wallet <a name="0001-WALL-068" href="#0001-WALL-068">0001-WALL-068</a>
- **must** be able to change wallet name <a name="0001-WALL-069" href="#0001-WALL-069">0001-WALL-069</a>
- **must** be able to change wallet passphrase <a name="0001-WALL-070" href="#0001-WALL-070">0001-WALL-070</a>
- `TODO:` **should** be able to link some wallets to specific networks

... so that I must administrate my wallets

## App settings (Not sure if this needs AC?)
- TODO Link or lock a key to a given network
