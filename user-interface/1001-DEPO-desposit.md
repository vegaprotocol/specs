# Deposit

The Vega network has no native assets. All settlement assets exist on another chain and are "bridged" to Vega in one way or another.

In the case of [ERC20 tokens](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/) there is a smart contract on the Ethereum network that acts as a vault (aka bridge) for the tokens that are deposited to Vega. The Vega network then reads the information from this vault about what Vega key to credit these tokens to. While in the Vault the Vega key that owns them (and consequently the ethereum key) may change. The vault then manages how much each ethereum key is able to withdraw from the vault given then changes in ownership that may have happened on Vega. The keys to this vault and managed by the different nodes that make up the Vega network. They verify the the appropriate amounts can be withdrawn by each Ethereum key. At time of writing only ERC20 tokens have been implemented but the pattern is likely the same for other assets/networks.
## ERC20 deposits

When looking to deposit ERC20 assets to an Vega key, I...

- **must** see a link to [connect an ethereum wallet](0004-EWAL-connect_ethereum_wallet.md) that I want to deposit from (1001-DEPO-xxx)
- **must** select the asset that I want to deposit (1001-DEPO-xxx)
  - **should** easily see the assets that there is a non-zero balance for in the connected wallet
- **must** select the [amount of the asset](9001-DATA-data_display.md#asset-balances) that I want to deposit  (1001-DEPO-xxx)
  - **should** see an ability to populate the input with the full balance in the connected wallet
- **must** select the Vega key
  - should be pre-populated with current connected key [link](#)
  - should be able to specify a Vega key that you are not connected with
- See Approved amount 
  - See approve amount 
  - if approved is less than deposit: 
    - approve more 
  - if approve is more than deposit amount: 
    - ETH transaction 
    - feedback 
- Deposit
  - Eth transaction
- Feedback

...so that my Vega key can use these on Vega