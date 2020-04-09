Feature name: Add Asset to Vega
Start date: 2020-04-09
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary
In order for the Vega network to hold value via asset bridges, assets must be added to Vega and that order must be propagated to the appropriate Vega bridge smart contract.  

# Guide-level explanation
### Ethereum-based assets
#### ERC20
To add an ERC20 token-based asset to Vega, a market maker or other interested party will submit the target ethereum token address to the Vega interface (`TODO`).
Once submitted, the request is put through Vega consensus. 
Once accepted through consensus, a multisig signature bundle is aggregated from Vega validator nodes and the signature bundle is then submitted to the appropriate Vega ERC20 bridge by way of the `whitelist_asset` function.
Upon successful execution of the `whitelist_asset` function, that token will be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the contract will raise the `Asset_Deposited` event which will then be consumed and propagated through Vega consensus by way of the Event Queue.
 
#### ERC1155
To add an ERC1155 token-based asset to Vega, a market maker or other interested party will submit the target ethereum smart contract address and asset ID (uint256) to the Vega interface (`TODO`).
Once submitted, the request is put through Vega consensus. 
Once accepted through consensus, a multisig signature bundle is aggregated from Vega validator nodes and the signature bundle is then submitted to the appropriate Vega ERC1155 bridge by way of the `whitelist_asset` function.
Upon successful execution of the `whitelist_asset` function, that token will be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the contract will raise the `Asset_Deposited` event which will then be consumed and propagated through Vega consensus by way of the Event Queue.

### Other blockchains
`TODO`

# Reference-level explanation


# Pseudo-code / Examples


# Acceptance Criteria

