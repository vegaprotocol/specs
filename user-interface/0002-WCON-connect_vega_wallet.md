# Connect Vega wallet + select keys

## Connect wallet for the first time

When looking to use Vega Via a user interface e.g. Dapp (Decentralized web App), I...

- **should** see a link to get a Vega wallet (in case I don't already have one) <a name="xxxx-WALL-001" href="#xxxx-WALL-001">xxxx-WALL-001</a>
- **should** see a link to connect that opens up connection options <a name="xxxx-WALL-001" href="#xxxx-WALL-001">xxxx-WALL-001</a>
- **must** select a connection method / wallet type: <a name="xxxx-WALL-002" href="#xxxx-WALL-002">xxxx-WALL-002</a>
- if Rest:
  - **must** have the option to input a non-default Wallet location <a name="xxxx-WALL-003" href="#xxxx-WALL-003">xxxx-WALL-003</a>
  - **should** warn if the dapp is unable the see a wallet is running at the wallet location  <a name="xxxx-WALL-004" href="#xxxx-WALL-004">xxxx-WALL-004</a>
  - **must** submit attempt to connect to wallet <a name="xxxx-WALL-005" href="#xxxx-WALL-005">xxxx-WALL-005</a>
  - **could** trigger the app to open on the user's machine with a `vegawallet://` prompt <!--<a name="xxxx-WALL-006" href="#xxxx-WALL-006">xxxx-WALL-006</a>-->
  
  - if the wallet does have an existing permission with the wallet: **must** see that wallet is connected <a name="xxxx-WALL-007" href="#xxxx-WALL-007">xxxx-WALL-007</a>
    - if the app uses one key at a time: **should** show what key is active (re-use the last active key) <a name="xxxx-WALL-008" href="#xxxx-WALL-008">xxxx-WALL-008</a>

  - if the wallet does not have an existing permission with the wallet: **must** prompt user to check wallet app to approve the request to connect wallet: See [Connecting to Dapps](0011-WALL-wallet.md#Connecting to dApps) for what should happen in wallet app <a name="xxxx-WALL-009" href="#xxxx-WALL-009">xxxx-WALL-009</a>
  
  - if new keys are given permission: **must** show the user the keys have been approved <a name="xxxx-WALL-010" href="#xxxx-WALL-010">xxxx-WALL-010</a>
    - **should** see [public key(s)](7001-DATA-data_display.md#public-keys) <a name="xxxx-WALL-010" href="#xxxx-WALL-010">xxxx-WALL-010</a>
    - **should** see alias(es) <a name="xxxx-WALL-011" href="#xxxx-WALL-011">xxxx-WALL-011</a>
    - **could** see assets on key(s) <a name="xxxx-WALL-012" href="#xxxx-WALL-012">xxxx-WALL-012</a>
    - **would like to** see positions on key(s) <!--<a name="xxxx-WALL-013" href="#xxxx-WALL-013">xxxx-WALL-013</a>-->
    - if the dapp uses one key at a time: **should** prompt key selection. See [select/switch keys](#select-and-switch-keys). <a name="xxxx-WALL-014" href="#xxxx-WALL-014">xxxx-WALL-014</a>

  - if user rejects connection: **must** see a message saying that the request to connect was denied  <a name="xxxx-WALL-015" href="#xxxx-WALL-015">xxxx-WALL-015</a>
  
  - if the dapp is unable to connect for technical reason (e.g. CORS): **must** see an explanation of the error, and a method of fixing the issue  <a name="xxxx-WALL-016" href="#xxxx-WALL-016">xxxx-WALL-016</a>
  

- ~~Browser wallet~~ `not available yet`
  
- Fairground hosted wallet
  - **must** input a wallet name <a name="xxxx-WALL-017" href="#xxxx-WALL-017">xxxx-WALL-017</a>
  - **must** input a password <a name="xxxx-WALL-018" href="#xxxx-WALL-018">xxxx-WALL-018</a>
  - if success: **must** see that the wallet is connected and details of connected key <a name="xxxx-WALL-019" href="#xxxx-WALL-019">xxxx-WALL-019</a>
  - if failure: **must** see reason for failure <a name="xxxx-WALL-020" href="#xxxx-WALL-020">xxxx-WALL-020</a>
  - *note: the fairground hosted wallet is configured to automatically approve connections from dapps so there is no need to key selection.*
  
- **must** have the option to select a different method / wallet type if I change my mind <a name="xxxx-WALL-021" href="#xxxx-WALL-021">xxxx-WALL-021</a>

... so I can use the interface read data about my key/party or request my wallet to broadcast transactions to a Vega network.

## Disconnect wallet

When wishing to disconnect my wallet, I...

- **must** see an option to disconnect wallet <a name="xxxx-WALL-022" href="#xxxx-WALL-022">xxxx-WALL-022</a>
- **should** see confirmation that wallet has been disconnected <a name="xxxx-WALL-023" href="#xxxx-WALL-023">xxxx-WALL-023</a>
- **should** see prompt to connect a wallet, after disconnect <a name="xxxx-WALL-024" href="#xxxx-WALL-024">xxxx-WALL-024</a>

... so that I can protect my wallet from malicious use or select a different wallet to connect to


## Select and switch keys

when looking to do something with a specific key (or set of keys) from my wallet, I...

- **must** see what key is currently selected (if any) <a name="xxxx-WALL-0025" href="#xxxx-WALL-0025">xxxx-WALL-0025</a>
- **must** see an option to switch keys, and a list of keys that are approved from the connected wallet <a name="xxxx-WALL-026" href="#xxxx-WALL-026">xxxx-WALL-026</a>

- for each key:
  - **must** see the first and last 6 digits of the [public key](7001-DATA-data_display.md#public-keys) <a name="xxxx-WALL-027" href="#xxxx-WALL-027">xxxx-WALL-027</a>
  - **should** be able to see the whole public key <a name="xxxx-WALL-028" href="#xxxx-WALL-028">xxxx-WALL-028</a>
  - **must** be able to copy to clipboard the whole public key <a name="xxxx-WALL-029" href="#xxxx-WALL-029">xxxx-WALL-029</a>
  - **must** see the key name/alias (meta data) <a name="xxxx-WALL-030" href="#xxxx-WALL-030">xxxx-WALL-030</a>
  - **should** see what non-zero assets that kay has <a name="xxxx-WALL-031" href="#xxxx-WALL-031">xxxx-WALL-031</a>
  - **could** see the Total asst balances (inc associated) <a name="xxxx-WALL-032" href="#xxxx-WALL-032">xxxx-WALL-032</a>
  - **would like to see** a breakdown of the accounts. See [collateral / accounts](6001-COLL-collateral.md) <!--<a name="xxxx-WALL-033" href="#xxxx-WALL-033">xxxx-WALL-033</a>-->
  - **would like to** see any active orders or positions. See [collateral / accounts](6001-COLL-collateral.md) <!--<a name="xxxx-WALL-034" href="#xxxx-WALL-034">xxxx-WALL-034</a>-->

- **must** see the option to trigger a re-authenticate so I can use newly created keys <a name="xxxx-WALL-035" href="#xxxx-WALL-035">xxxx-WALL-035</a>

...so that I can select the key(s) that I want to use.