# Browser Wallet

## Create app password

As a browser wallet user I want to create a password for my browser wallet app So that I can secure my wallets and keys on this device

- When I haven't submitted my password, I can go back to the previous step (<a name="1101-BWAL-001" href="#1101-BWAL-001">1101-BWAL-001</a>)
- I can see an explanation of what the password is for and that it cannot be used to recover my keys or recover itself (<a name="1101-BWAL-002" href="#1101-BWAL-002">1101-BWAL-002</a>)
- I can enter a password for the browser wallet (<a name="1101-BWAL-003" href="#1101-BWAL-003">1101-BWAL-003</a>)
- I can verify the password I set for my browser wallet (to help ensure I typed it correctly and can replicate it) (<a name="1101-BWAL-004" href="#1101-BWAL-004">1101-BWAL-004</a>)
- I can verify that I understand that Vega doesn't store and therefore can't recover this password if I lose it (<a name="1101-BWAL-005" href="#1101-BWAL-005">1101-BWAL-005</a>)
- I can NOT submit an empty password (<a name="1101-BWAL-006" href="#1101-BWAL-006">1101-BWAL-006</a>)
- I can submit the password I entered (<a name="1101-BWAL-007" href="#1101-BWAL-007">1101-BWAL-007</a>)
- When I have submitted my new password, I am given some feedback that it was set successfully (<a name="1101-BWAL-008" href="#1101-BWAL-008">1101-BWAL-008</a>)
- When I have submitted my new password, I am taken to the next step (<a name="1101-BWAL-009" href="#1101-BWAL-009">1101-BWAL-009</a>)
- When I have submitted my new password, I can NOT go back to the previous step (<a name="1101-BWAL-010" href="#1101-BWAL-010">1101-BWAL-010</a>)

## Create or import wallet

As a browser wallet user I want to decide whether to create a new wallet or import an existing one So that I understand my options and don't waste time creating a new wallet when I already created one elsewhere

- I can choose to create a wallet (<a name="1101-BWAL-011" href="#1101-BWAL-011">1101-BWAL-011</a>)
- I can choose to import an existing wallet (<a name="1101-BWAL-012" href="#1101-BWAL-012">1101-BWAL-012</a>)

## Create wallet and key pair

As a browser wallet user When I am using the browser wallet for the first time I want to create a new wallet (and key pair) So that I can get started using Console / another Vega dapp to trade / take part in governance

- I am provided with a recovery phrase for my new wallet that is initially hidden from view(<a name="1101-BWAL-013" href="#1101-BWAL-013">1101-BWAL-013</a>)
- I can see an explanation of what the recovery phrase is for and that it cannot be recovered itself (<a name="1101-BWAL-014" href="#1101-BWAL-014">1101-BWAL-014</a>)
- I can choose when to reveal/show the recovery phrase (<a name="1101-BWAL-015" href="#1101-BWAL-015">1101-BWAL-015</a>)
- I can copy the recovery phrase into my clipboard (<a name="1101-BWAL-016" href="#1101-BWAL-016">1101-BWAL-016</a>)
- I can verify that I understand that Vega doesn't store and therefore can't recover this recovery phrase if I lose it (<a name="1101-BWAL-017" href="#1101-BWAL-017">1101-BWAL-017</a>)
- I am given feedback that my wallet was successfully created (<a name="1101-BWAL-018" href="#1101-BWAL-018">1101-BWAL-018</a>)
- I am redirected to the next step - opt in to error reporting (<a name="1101-BWAL-019" href="#1101-BWAL-019">1101-BWAL-019</a>)
- The new Wallet name and key pair are auto generated in the background "Wallet" "Vega Key 1" (<a name="1101-BWAL-020" href="#1101-BWAL-020">1101-BWAL-020</a>)
- When I have already created a wallet, I am redirected to the landing page where I can view that wallet (rather than the onboarding flow) (<a name="1101-BWAL-021" href="#1101-BWAL-021">1101-BWAL-021</a>)

## Confirm recovery phrase

As a wallet user I want to validate I have "recorded" or saved the recovery phrase accurately So that I feel secure and confident to go ahead

- I can confirm I have written down / saved my recovery phrase by entering parts of it again in the UI(<a name="1101-BWAL-022" href="#1101-BWAL-022">1101-BWAL-022</a>)
- There is a way to go back to see the full recovery phrase if I have written / saved it incorrectly (<a name="1101-BWAL-023" href="#1101-BWAL-023">1101-BWAL-023</a>)
- I can click to continue to the next step of onboarding once I've successfully entered the relevant parts of the phrase (<a name="1101-BWAL-024" href="#1101-BWAL-024">1101-BWAL-024</a>)
- There is a way to understand if the details I've entered are incorrect e.g. highlight in red (<a name="1101-BWAL-025" href="#1101-BWAL-025">1101-BWAL-025</a>)

## View network connected to

As a browser wallet user I want to know which vega network my browser wallet is connected to So that I know if I am on the network I expect to be, and whether I am transacting with real or fake assets

- The browser wallet defaults to use the Fairground network (<a name="1101-BWAL-026" href="#1101-BWAL-026">1101-BWAL-026</a>)
- I can see which vega network the browser wallet is connected to from everywhere in the app(<a name="1101-BWAL-027" href="#1101-BWAL-027">1101-BWAL-027</a>)

## Create key pairs

As a wallet user I want to be able to create multiple key pairs in my wallet So that I can use different keys for different

- I can create a new key pair from the wallet view (<a name="1101-BWAL-028" href="#1101-BWAL-028">1101-BWAL-028</a>)
- New key pairs are assigned a name automatically "Vega Key 1" "Vega Key 2" etc.(<a name="1101-BWAL-029" href="#1101-BWAL-029">1101-BWAL-029</a>)
- New key pairs are listed in order they were created - oldest first(<a name="1101-BWAL-030" href="#1101-BWAL-030">1101-BWAL-030</a>)

## Remember where I am in the onboarding flow

As a browser wallet user When I have started onboarding in the browser wallet and I close the extension / browser I want to be able to reopen the extension and it remember where I was in the onboarding flow So that I don't have to start again

- I can close the extension and when I reopen it it opens on the same page / view (<a name="1101-BWAL-031" href="#1101-BWAL-031">1101-BWAL-031</a>)
- When I reopen the extension after last viewing the recovery phrase and hadn't yet acknowledged and moved to the next step, it opens on the recover phrase step with the recovery phrase hidden(<a name="1101-BWAL-032" href="#1101-BWAL-032">1101-BWAL-032</a>)

## Connect all key(s) only

As a wallet user I want to connect my key(s) to a dapp So that I can verify transactions like orders, transfers etc.

- There is a way to approve or deny a connection request (<a name="1101-BWAL-033" href="#1101-BWAL-033">1101-BWAL-033</a>)
- I can see a visual representation of the dapp requesting access e.g. the favicon (<a name="1101-BWAL-034" href="#1101-BWAL-034">1101-BWAL-034</a>)
- I can see what approving a connection request enables the site / dapp to do (<a name="1101-BWAL-035" href="#1101-BWAL-035">1101-BWAL-035</a>)
- I can see the URL of the site / dapp requesting access(<a name="1101-BWAL-036" href="#1101-BWAL-036">1101-BWAL-036</a>)
- All new connections are for all keys in a wallet and all future keys added to the wallet(<a name="1101-BWAL-037" href="#1101-BWAL-037">1101-BWAL-037</a>)
- There is a way to understand that i.e. this connection request gives access to ALL my keys now and in the future (<a name="1101-BWAL-038" href="#1101-BWAL-038">1101-BWAL-038</a>)
- When I go away from the extension and come back to the connected site, the browser extension remembers the connection and does not ask me to reconnect (<a name="1101-BWAL-039" href="#1101-BWAL-039">1101-BWAL-039</a>)
- There is a visual way to understand that a connection has been successful(<a name="1101-BWAL-040" href="#1101-BWAL-040">1101-BWAL-040</a>)

## Approve transaction request

As a browser wallet user I want to be able to approve a transaction request So that I can verify and complete the action I am trying to make on the vega dapp I'm using

- When I view a transaction request I can choose to approve it (<a name="1101-BWAL-041" href="#1101-BWAL-041">1101-BWAL-041</a>)
- When I approve a transaction I can see confirmation that the transaction has been approved (<a name="1101-BWAL-042" href="#1101-BWAL-042">1101-BWAL-042</a>)
- When I approve a transaction the transaction gets signed and the approved status gets fed back to the dapp that requested it (<a name="1101-BWAL-043" href="#1101-BWAL-043">1101-BWAL-043</a>)
- When I approve a transaction after I have approved it we revert to the next transaction if there's a queue OR we revert to the key view (the front / homepage) (<a name="1101-BWAL-044" href="#1101-BWAL-044">1101-BWAL-044</a>)

## Reject transaction request

As a browser wallet user I want to be able to reject a transaction request So that I can prevent a transaction going through that I don't recognise as mine, or have changed my mind on / identified a mistake etc.

- When I view a transaction request I can choose to reject it(<a name="1101-BWAL-045" href="#1101-BWAL-045">1101-BWAL-045</a>)
- When I reject a transaction I can see confirmation that the transaction has been rejected (<a name="1101-BWAL-046" href="#1101-BWAL-046">1101-BWAL-046</a>)
- When I reject a transaction the transaction does not get signed and the rejected status gets fed back to the dapp that requested it (<a name="1101-BWAL-047" href="#1101-BWAL-047">1101-BWAL-047</a>)
- When I reject a transaction after I have rejected it we revert to the next transaction if there's a queue OR we revert to the key view (start / home page) (<a name="1101-BWAL-048" href="#1101-BWAL-048">1101-BWAL-048</a>)

## View trasaction request (generic)

As a user I want to recognise transactions that are not orders or withdraw / transfer requests with at least the bear minimum information needed to proceed So that I can continue my task (e.g. governing, staking)

- When the dapp requests a transaction with a key we don't know about, we don't see a request in the wallet but instead send an error back to the dapp(<a name="1101-BWAL-049" href="#1101-BWAL-049">1101-BWAL-049</a>)
- When the dapp requests a transaction type / or includes transaction details that we don't recognise, we don't present the transaction request in the wallet but provide an error to the dapp that feeds back that the transaction can not be processed (<a name="1101-BWAL-050" href="#1101-BWAL-050">1101-BWAL-050</a>)
- When the user opens the extension (or it has automatically opened) they can immediately see a transaction request (<a name="1101-BWAL-051" href="#1101-BWAL-051">1101-BWAL-051</a>)
- If the browser extension is closed during a transaction request, the request persists (<a name="1101-BWAL-052" href="#1101-BWAL-052">1101-BWAL-052</a>)
- For transactions that are not orders or withdraw / transfers, there is a standard template with the minimum information required i.e. (<a name="1101-BWAL-053" href="#1101-BWAL-053">1101-BWAL-053</a>) -- [ ] Transaction title -- [ ] Where it is from e.g. console.vega.xyz with a favicon -- [ ] The key you are using to sign with a visual identifier -- [ ] When it was received -- [ ] Raw JSON details
- It is visually similar to other transaction types but essentially has less of the human readable detail(s) (design note) (<a name="1101-BWAL-054" href="#1101-BWAL-054">1101-BWAL-054</a>)
- I can copy the raw json to my clipboard (<a name="1101-BWAL-055" href="#1101-BWAL-055">1101-BWAL-055</a>)

## Log in (next time password expires)

As a wallet user I want a way to enter my password when my login has expired So that I can continue with my task

- When I have quit my browser, and then reopened, I am asked to enter my browser extension password(<a name="1101-BWAL-056" href="#1101-BWAL-056">1101-BWAL-056</a>)
- I am informed if I enter my password incorrectly (<a name="1101-BWAL-057" href="#1101-BWAL-057">1101-BWAL-057</a>)