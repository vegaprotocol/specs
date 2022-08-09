# Connect Vega wallet + select keys

## Connect wallet for the first time

When looking to use Vega Via a user interface e.g. Dapp (Decentralized web App), I...

- **should** see a link to get a Vega wallet (in case I don't already have one) <a name="0002-WCON-036" href="#0002-WCON-036">0002-WCON-036</a>
- **should** see a link to connect that opens up connection options <a name="0002-WCON-001" href="#0002-WCON-001">0002-WCON-001</a>
- **must** select a connection method / wallet type: <a name="0002-WCON-002" href="#0002-WCON-002">0002-WCON-002</a>
- if Rest:
  - **must** have the option to input a non-default Wallet location <a name="0002-WCON-003" href="#0002-WCON-003">0002-WCON-003</a>
  - **should** warn if the dapp is unable the see a wallet is running at the wallet location  <a name="0002-WCON-004" href="#0002-WCON-004">0002-WCON-004</a>
  - **must** submit attempt to connect to wallet <a name="0002-WCON-005" href="#0002-WCON-005">0002-WCON-005</a>
  - **could** trigger the app to open on the user's machine with a `vegawallet://` prompt <!--<a name="0002-WCON-006" href="#0002-WCON-006">0002-WCON-006</a>-->
  
  - if the wallet does have an existing permission with the wallet: **must** see that wallet is connected <a name="0002-WCON-007" href="#0002-WCON-007">0002-WCON-007</a>
    - if the app uses one key at a time: **should** show what key is active (re-use the last active key) <a name="0002-WCON-008" href="#0002-WCON-008">0002-WCON-008</a>

  - if the wallet does not have an existing permission with the wallet: **must** prompt user to check wallet app to approve the request to connect wallet: See [Connecting to Dapps](0011-WCON-wallet.md#Connecting to dApps) for what should happen in wallet app <a name="0002-WCON-009" href="#0002-WCON-009">0002-WCON-009</a>
  
  - if new keys are given permission: **must** show the user the keys have been approved <a name="0002-WCON-010" href="#0002-WCON-010">0002-WCON-010</a>
    - **should** see [public key(s)](7001-DATA-data_display.md#public-keys) <a name="0002-WCON-037" href="#0002-WCON-037">0002-WCON-037</a>
    - **should** see alias(es) <a name="0002-WCON-011" href="#0002-WCON-011">0002-WCON-011</a>
    - **could** see assets on key(s) <a name="0002-WCON-012" href="#0002-WCON-012">0002-WCON-012</a>
    - **would like to** see positions on key(s) <!--<a name="0002-WCON-013" href="#0002-WCON-013">0002-WCON-013</a>-->
    - if the dapp uses one key at a time: **should** prompt key selection. See [select/switch keys](#select-and-switch-keys). <a name="0002-WCON-014" href="#0002-WCON-014">0002-WCON-014</a>

  - if user rejects connection: **must** see a message saying that the request to connect was denied  <a name="0002-WCON-015" href="#0002-WCON-015">0002-WCON-015</a>
  
  - if the dapp is unable to connect for technical reason (e.g. CORS): **must** see an explanation of the error, and a method of fixing the issue  <a name="0002-WCON-016" href="#0002-WCON-016">0002-WCON-016</a>
  

- ~~Browser wallet~~ `not available yet`
  
- Fairground hosted wallet
  - **must** input a wallet name <a name="0002-WCON-017" href="#0002-WCON-017">0002-WCON-017</a>
  - **must** input a password <a name="0002-WCON-018" href="#0002-WCON-018">0002-WCON-018</a>
  - if success: **must** see that the wallet is connected and details of connected key <a name="0002-WCON-019" href="#0002-WCON-019">0002-WCON-019</a>
  - if failure: **must** see reason for failure <a name="0002-WCON-020" href="#0002-WCON-020">0002-WCON-020</a>
  - *note: the fairground hosted wallet is configured to automatically approve connections from dapps so there is no need to key selection.*
  
- **must** have the option to select a different method / wallet type if I change my mind <a name="0002-WCON-021" href="#0002-WCON-021">0002-WCON-021</a>

... so I can use the interface read data about my key/party or request my wallet to broadcast transactions to a Vega network.

## Disconnect wallet

When wishing to disconnect my wallet, I...

- **must** see an option to disconnect wallet <a name="0002-WCON-022" href="#0002-WCON-022">0002-WCON-022</a>
- **should** see confirmation that wallet has been disconnected <a name="0002-WCON-023" href="#0002-WCON-023">0002-WCON-023</a>
- **should** see prompt to connect a wallet, after disconnect <a name="0002-WCON-024" href="#0002-WCON-024">0002-WCON-024</a>

... so that I can protect my wallet from malicious use or select a different wallet to connect to


## Select and switch keys

when looking to do something with a specific key (or set of keys) from my wallet, I...

- **must** see what key is currently selected (if any) <a name="0002-WCON-025" href="#0002-WCON-025">0002-WCON-025</a>
- **must** see an option to switch keys, and a list of keys that are approved from the connected wallet <a name="0002-WCON-026" href="#0002-WCON-026">0002-WCON-026</a>

- for each key:
  - **must** see the first and last 6 digits of the [public key](7001-DATA-data_display.md#public-keys) <a name="0002-WCON-027" href="#0002-WCON-027">0002-WCON-027</a>
  - **should** be able to see the whole public key <a name="0002-WCON-028" href="#0002-WCON-028">0002-WCON-028</a>
  - **must** be able to copy to clipboard the whole public key <a name="0002-WCON-029" href="#0002-WCON-029">0002-WCON-029</a>
  - **must** see the key name/alias (meta data) <a name="0002-WCON-030" href="#0002-WCON-030">0002-WCON-030</a>
  - **should** see what non-zero assets that kay has <a name="0002-WCON-031" href="#0002-WCON-031">0002-WCON-031</a>
  - **could** see the Total asst balances (inc associated) <a name="0002-WCON-032" href="#0002-WCON-032">0002-WCON-032</a>
  - **would like to see** a breakdown of the accounts. See [collateral / accounts](6001-COLL-collateral.md) <!--<a name="0002-WCON-033" href="#0002-WCON-033">0002-WCON-033</a>-->
  - **would like to** see any active orders or positions. See [collateral / accounts](6001-COLL-collateral.md) <!--<a name="0002-WCON-034" href="#0002-WCON-034">0002-WCON-034</a>-->

- **must** see the option to trigger a re-authenticate so I can use newly created keys <a name="0002-WCON-035" href="#0002-WCON-035">0002-WCON-035</a>

...so that I can select the key(s) that I want to use.