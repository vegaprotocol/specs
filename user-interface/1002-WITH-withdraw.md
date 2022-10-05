# Withdraw
Withdrawing funds is a two step process. First the Vega network needs to approve that the funds can be released (not required for margin on open positions or in liquidity bond etc), this also sets the address that the withdraw will be credited to. Then the user will need to run a function on bridge contract to release the funds from the bridge contract they were deposited too (and pay the gas to do so). They do this using a signature supplied by nodes of the Vega network in Step 1. Although this is a two step process technically effort should be put into making it feel like one, then handle exceptions (like delays on withdrawals) as required.

See [Specs for eth bridge](../protocol/0031-ETHB-ethereum_bridge_spec.md) and [docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-protocol#withdrawals) on withdrawals. See also the [specs on delays to withdrawals](../non-protocol-specs/0003-NP-LIMI-limits_aka_training_wheels.md#withdrawal-limits).

## Prepare an ERC20 withdraw from Vega

When wishing to withdraw some of an ERC20 asset from Vega, I...

- **should** be prompted to complete any existing incomplete withdrawals that exist for connected keys (see [complete withdrawal](#complete-erc20-withdraw-on-ethereum))

Note: It is better to encourage the completion of started withdraws as soon as possible after starting them. This is because the validator set could theoretically change enough to make the node signatures that authorize the withdrawal invalid.

- **should** be warned that they will need to pay gas on the withdrawal before starting 
- **could** show the current gas fees BEFORE preparing the withdrawal (note: this is already a requirement for all [ethereum transactions](0005-ETXN-submit_ethereum_transaction.md)) 

Note: A user may want to delay preparing a withdrawal if gas fees on the network are particularly high at the time

- **must** select the asset to withdraw
  - **should not** see option to select assets where I a zero [total balance](7001-DATA-data_display.md#asset-balances) (note this should also avoid `Pending` assets from appearing in the list)
  - **must** see the general balance I have for that asset
  - **should** see balances to the full number of decimal places possible for that asset
  - **should** see the total balances of the assets I have
  - **could** see a breakdown of other accounts I have in this asset and their balances

- **must** select the [amount](7001-DATA-data_display.md#asset-balances) of the asset I wish to withdraw
  - **should** have an easy option (link/button) to withdraw the full amount in general balance (e.g. pre-populate the amount input)
  - **must** be able to specify as many decimal places as the asset supports
- **must** be warned if the amount is greater than general balance
- **should** see a link to a faucet on the selected asset (only if there is one)

Note: balances can change frequently when users have open positions. Apps should show up to date information (subscription), and make it easy to fill in the amount this isn't going to make the input invalid as the amount in general balances changes.

- **must** specify the Ethereum address that can claim the withdrawal (e.g. where you are withdrawing too)
  - **should** be able to easily select an Ethereum key the app is already connected to
  - **should** be able to withdraw to a different Ethereum key to the one the app is connected to
  - **should** be warned if the input does not look like an ethereum address (wrong number of digits, not starting with 0x etc)

- if there is a withdraw delay on the selected [asset](7001-DATA-data_display.md#asset-balances):
  - **should** see what the withdraw delay is in hours and mins (if hit)
  - **should** see how large a withdrawal (or sum of withdrawals) needs to be to hit the `withdraw delay threshold`
  - **should** see how much I have withdrawn in the last `withdraw delay period`
  - **must** be warned if this withdraw will hit a the delay

- **must** be warned if there are known reasons that the prepared withdrawal will not work
- **must** submit a withdraw [vega transaction](0003-WTXN-submit_vega_transaction.md)

- if the preparing the withdraw on Vega fails:
  - **must** be directed back to the withdraw form (containing the submitted values) and see an explanation of why the transaction failed, so I can fix and resubmit

- if the preparing the withdraw on Vega is successful:
  -  **must** see that withdraw is complete
  - if this withdraw will not hit the withdrawal threshold:
    - **should** be prompted to complete the transaction on ethereum (see [complete ERC20 withdraw](#complete-erc20-withdraw-from-ethereum-bridge))
    - **could** be directed to a list of incomplete withdrawals
  - if this withdraw will hit withdrawal threshold: 
    - **must** see that the withdraw has been complete and is in the list waiting for the delay to pass

...so that I can get the details required to release my funds from the the Ethereum ERC20 bridge.

## Withdraws list / history

When looking to either complete a withdraw or view past withdraws, I...

- **must** be able to navigate to a list prepared withdrawals for the [connected to a vega wallet + key(s)](0002-WCON-connect_vega_wallet.md)

- for each prepared withdraw:
  - **must** see the asset being withdrawn
  - **must** see the [amount](7001-DATA-data_display.md#asset-balances) being withdrawn
  - **must** see the destination of the withdrawal (e.g. Recipient Eth address)
  - **should** see the date with withdraw was prepared
  - **could** see the full signature bundle from Vega node (for use on Ethereum)
  - for withdraws that are in progress:
    - **must** see the status of the withdraw (e.g. pending)
  - for completed withdraws:
    - **could** see when it was completed on native chain (e.g. ethereum)
    - **must** see a link to the transaction on native block explorer (e.g. etherscan)
  - for withdraws that have not been completed on the external chain, but are not delayed (e.g. Ethereum):
    - **must** see a link to complete the withdraw. See [complete ERC20 withdrawal](#complete-erc20-withdraw-from-ethereum-bridge).
  - for withdrawals that have a delay in place before the transaction can be completed:
    - **should** see much of the delay remains before it can be completed

... so I can complete withdrawals or find details of previous ones

## Complete ERC20 withdraw from Ethereum bridge

When looking to submit the Ethereum transaction to release funds from the Vega bridge into my Ethereum wallet, I...

- **must** see a link to [connect an ethereum wallet](0004-EWAL-connect_ethereum_wallet.md) if not already connected
- **must** see a link to [submit the ethereum transaction to finish withdrawal](0005-ETXN-submit_ethereum_transaction.md)
- **could** be warned if the connected ethereum wallet is different to the one that the withdraw is going to credit

Note: this is permitted but is a good reminder to the user about what to expect

- if successful: 
  - **must** see asset balances have been updated post withdrawal
  - **must** see the list of withdrawals (with updated status)
  - **could** see prompt to start another transaction or complete another incomplete one 
- if failed:
  - **must** see a description of why the transaction failed, and advised what to do (e.g. bad signature)
  - **must** be returned to a state where I can correct anything that is wrong, and attempt to submit the transaction again
  - **should** see a link to docs about withdrawals for trouble shooting (e.g. if the signer set has changed significantly since the withdraw was prepared)
  - **should** see status of incomplete withdrawals (so I can confirm the withdraw I attempted to complete is incomplete)

... so the funds I withdrew from Vega are credited to my Ethereum key 