# Withdraw
Withdrawing funds is a two step process. First the Vega network needs to approve that the funds can be released (not required for margin on open positions or in liquidity bond). Then using a signature from nodes of the Vega network the user will need to run a function on bridge contract to release the funds from the contract into the native wallet of that chain. At time of writing only ERC20 assets are supported.
See [Specs for eth bridge](../protocol/0031-ETHB-ethereum_bridge_spec.md) and [docs](https://docs.vega.xyz/docs/mainnet/concepts/vega-protocol#withdrawals) on withdrawals.

At the time of writing only ERC20 assets are supported and it is only possible to withdraw one asset at a time.

## Prepare an ERC20 withdraw from Vega

When wishing to withdraw some of an ERC20 asset from Vega, I...

- **must** be prompted to complete any incomplete withdrawals that exist for connected keys (see [complete withdrawal](#complete-erc20-withdraw-on-ethereum))

- **must** select the asset to withdraw
  - **should not** see option to select assets where I a zero [total balance](7001-DATA-data_display.md) (note this should also avoid `Pending` assets from appearing in the list)
  - **must** see the general balance I have for that asset
  - **should** see balances to the full number of decimal places possible for that asset
  - **should** see the total balances of the assets I have
  - **could** see a breakdown of other accounts I have in this asset and their balances

- **must** select the amount of the asset I wish to withdraw
  - **should** have an easy option (link button) to withdraw the full amount in general balance (e.g. pre-populate the amount input)
  - **must** be able to specify as many decimal places as the asset supports
- **must** be warned if the amount is greater than general balance

Note: balances can change frequently when users have open positions. Apps should show up to date information (subscription), and make it easy to fill in the amount this isn't going to make the input invalid as the amount in general balances changes.

- **must** specify the Ethereum address that can claim the withdrawal (e.g. where you are withdrawing too)
  - should be able to easily select an Ethereum key the app is already connected to
  - should be able to withdraw to a different Ethereum key to the one the app is connected to

- if there is a withdraw delay:
  - **must** see how much of the selected asset can be withdrawn before hitting the withdraw delay 
    - **must** see what the withdraw delay is in hours and mins
    - **must** see how large a withdrawal (or sum of withdrawals) needs to be to hit the `withdraw delay threshold`
  - **must** must how much I have withdrawn in the last `withdraw delay period`.
  - **must** be warned if this withdraw will hit a the delay

- **must** submit a withdraw [vega transaction](0003-WTXN-submit_vega_transaction.md)
- if the preparing the withdraw on Vega fails:
  - **must** be directed back to the withdraw form (containing the submitted values) and see an explanation of why the transaction failed, so I can fix and resubmit

- if the preparing the withdraw on Vega is successful:
  -  **must** see that withdraw is complete and ready with withdraw
  - if this withdraw will not hit the withdrawal threshold:
    - **should** be prompted to complete the transaction on ethereum (see [complete ERC20 withdraw](#complete-erc20-withdraw-from-ethereum-bridge))
    **could** be directed to a list of incomplete withdrawals
  - if this withdraw will hit withdrawal threshold: 
    - **must** see that the withdraw has been complete and is in the list waiting for the delay to pass (see [Complete ERC20 withdrawal](#complete-erc20-withdraw-from-ethereum-bridge))

...so that I can get the details required to release my funds from the the Ethereum ERC20 bridge.

## Complete ERC20 withdraw from Ethereum bridge

When looking to submit the Ethereum transaction the release funds from the Vega bridge into my Ethereum wallet, I...


- must see a link to [connect an ethereum wallet]()
- must see a link to submit an ethereum transaction
- must submit the transaction
- if successful:
- if failed:

... so the funds I withdrew from Vega are credited to my Ethereum key

## Withdraw history

When looking to at complete

- **must** be able to navigate to a list prepared withdrawals for the [connected to a vega wallet + key(s)](0002-WCON-connect_vega_wallet.md)

- for each prepared withdraw:
  - **must** see the asset being withdrawn
  - **must** see the [amount](7001-DATA-data_display.md#asset-balances) being withdrawn
  - **must** see the destination of the withdrawal (e.g. Recipient Eth address)
  - should see the date with withdraw was prepared
  - could see the full signiture bundle from Vega node (for use on Ethereum)
  - for withdraws that are in progress:
    - must see the status of the withdraw
  - for completed withdraws:
    - **must** see when it was completed on ethereum
    - **must** see a link to ethereum transaction on etherscan
  - for withdraws that have not been completed on the external chain (e.g. Ethereum):
    - must see a link to complete the withdraw. See [complete ERC20 withdrawal](#complete-erc20-withdraw-from-ethereum-bridge).