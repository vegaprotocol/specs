# Withdraw

## Prepare an ERC20 withdraw

When wishing to withdraw an some of an ERC20 asset from Vega, I...

- must see incomplete withdrawal (see [complete withdrawal](#complete-erc20-withdraw-on-ethereum))
- must select the asset I wish with withdraw
  - should not see option to select assets that I a zero [total balance](7001-DATA-data_display.md) in (note this should also avoid `Pending` assets from appearing in the list)
  - should see the total balances of the assets I have

- each single withdrawal has a cap, you have to wait x (withdraw delays < block time stamp>) time before you can do more


## Complete ERC20 withdraw on Ethereum