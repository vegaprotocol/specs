Feature name: mark-to-market-settlement

# Acceptance Criteria

- For a position with a negative settlement amount:
  - [ ] If settlement amount <= the trader’s margin account balance: 
    - entire settlement amount is transferred from trader’s margin account to the market’s temporary settlement account
  - [ ] If settlement amount > trader’s margin account balance  and <= trader's margin account balance + general account balance for the asset: 
    - the full balance of the trader’s margin account is transferred to the market’s temporary settlement account
    - the remainder, i.e. difference between the amount transferred from the margin account and the settlement amount, is transferred from the trader’s general account for the asset to the market’s temporary settlement account
  - [ ] If settlement amount > trader’s margin account balance + trader’s general account balance for the asset: 
    - the full balance of the trader’s margin account is transferred to the market’s temporary settlement account
    - the full balance of the trader’s general account for the assets are transferred to the market’s temporary settlement account
    - the minimum insurance pool account balance for the market & asset, and the remainder, i.e. the difference between the total amount transferred from the trader’s margin + general accounts and the settlement amount, is transferred from the insurance pool account for the market to the temporary settlement account for the market

- [ ] The total market's positive mark-to-market moves are equal in size to the negative mark-to-market moves.
- [ ] The total amount *collected* by the network should be less than  or equal to the sum of all of the negative settlement amounts (in absolute size)
- [ ] If a trader's settlement amount is positive and the amount collected, i.e. the balance of the temporary settlement account, equals the sum of all negative settlement amounts (in absolute size), every trader with a positive settlement amount receives that amount transferred to their margin account from the temporary settlement account.
-  [ ] If the total amount *collected* by the network, as determined by the balance of the market’s margin account, is less than the sum of all of the negative settlement amount amounts (in absolute size), for all traders with a positive settlement amount, an amount  is transferred from the market’s margin account to each trader’s margin account that is less than or equal to their settlement amount amount.
- [ ] The total amount of *collected* collateral equals the total amount of *distributed* collateral.

- [ ] The market's settlement account balance is zero at the start of the market-to-market settlement process
- [ ] After completing the mark-to-market settlement process, the market’s settlement account balance is zero
- If the mark price hasn't changed:
  - [ ] A trader with no change in open position size has no transfers in or out of their margin account
  - [ ] A trader with no change in open volume:
- [ ] Not sure if this is testable now, but previous mark price should be the one a stored with the position not at the market level to ensure we are capturing move since last MTM settlement regardless of ‘out of band’ mark price updates



# Summary
The network calculates the change in mark to market valuation and generates settlement cashflows for each party's gains/losses every time the [mark price](./0009-mark-price.md) of the market changes.

# Guide-level explanation


# Reference-level explanation

Settlement instructions are generated based on the change in market value of the open positions of a party.  

The steps followed are:

1. When the [mark price](./0009-mark-price.md) changes, the network calculates settlement cash flows for each party according to the following formula.

```
SETTLEMENT_AMT( party ) =  party.PREV_OPEN_VOLUME * (product.value(current_price) - product.value(prev_mark_price)) + SUM(from i=1 to new_trades.length)( new_trade(i).volume(party) * (product.value(current_price) - new_trade(i).price ) )
```

*where*

```product.value(current_price)``` uses for ```current_price``` the latest calculation of the [mark price](./0009-mark-price.md)
```party.PREV_OPEN_VOLUME``` refers to the party's open volume at the last MTM calculation.
```new_trades``` refers to any trades that the party has been involved in since the last MTM calculation.
```volume(party)``` is the (signed) volume  of the trade i.e. +ve if the party was a buyer and -ve if a seller.

```SETTLEMENT_AMT < 0``` , means the party will have collateral deducted from their accounts to cover their position.  Conversely,  if  ```SETTLEMENT_AMT > 0```  the trader will receive collateral  into their account.


2. The settlement function calculates how much to *collect* from the margin accounts of those whose change in mark to market has been negative / incurred loss.  This will be collected into the market's *margin* account via a set of transfer requests.  The collection instruction should first collect from a trader's margin account for the market and then the trader's general account and then the market's insurance pool.  

3. This will result in ledger entries  being formulated ( see [settlement](./0002-settlement.md) ) which adhere to double entry accounting and record the actual transfers that occurred on the ledger.

4. If the net amounts are what was requested, the settlement function will formulate instructions to *distribute* to the margin accounts of those whose moves have been positive according to the amount they are owed. These transfers will be requested to debit from the market's *margin* account and credit the traders who have a  positive mark-to-market.

5. If there's not enough money for the reallocation due to some traders having insufficient money in their margin account and general account to handle the price / position move, and if the insurance pool can't cover the full *distribute* requirements, the settlement function will need to alter the "distribute" amounts accordingly. The amounts are altered using a formula which is out of scope for this ticket. As a stub implementation distribution can pro-rata the amount in the settlement account between positions by relative position size.

Note: a close out profit / loss is automatically captured in trader margin accounts via mark-to-market reallocation described above. The reduction in open volume will be used when risk margins are next calculated.

Note: successive mark-to-market settlement transfer requests can be netted.

# Pseudo-code / Examples



# Test cases

See [here](https://drive.google.com/file/d/18o_sCC5OLS59is4cvSce8lcxQAigCrB1/view?usp=sharing) for examples / scenarios.


