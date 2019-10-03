Feature name: mark-to-market-settlement
Start date: YYYY-MM-DD
Specification PR: 

# Acceptance Criteria

- [ ] The positive mark-to-market moves are equal in size to the negative mark-to-market moves.
- [ ] When the MTM_MOVE of a trader is negative, they will have that amount attempt to be deducted from their margin account first, then their general account  (for that collateral asset) and finally from the market's insurance pool account.
- [ ] The total amount *collected* by the network should be less than  or equal to the sum of all of the negative MTM_MOVE amounts (in absolute size)
- [ ] When the MTM_MOVE of a trader is positive they will receive that amount into their margin account if and only if  the total amount *collected*  by the network equalled the sum of all of the negative MTM_MOVE amounts (in absolute size).
- [ ] If  the total amount *collected*  by the network is less than the sum of all of the negative MTM_MOVE amounts (in absolute size) all traders with a positive MTM_MOVE will  receive / be *distributed* some amount less than the size of their MTM_MOVE amount.
- [ ] The total amount *collected* collateral equals the total amount of *distributed* collateral.


# Summary
The network calculates the change in mark to market valuation and generates settlement cashflows for each party's gains/losses every time the [mark price](./0009-mark-price.md) of the market changes.

# Guide-level explanation


# Reference-level explanation

Settlement instructions are generated based on the change in market value of the open positions of a party.  


The steps followed are:


1. When the [mark price](./0009-mark-price.md) changes, the network calculates settlement cash flows for each party according to the following formula.

```
MTM_MOVE( party ) =  party.PREV_OPEN_VOLUME * (product.value(mark_price) - product.value(prev_mark_price)) + SUM(from i=1 to new_trades.length)( new_trade(i).volume(party) * (product.value(current_price) - new_trade(i).price ) )
```

*where*

```product.value(mark_price)``` refers to the latest calculation of the [mark price](./0009-mark-price.md)
```party.PREV_OPEN_VOLUME``` refers to the party's open volume at the last MTM calculation.
```new_trades``` refers to any trades that the party has been involved in since the last MTM calculation.
```volume(party)``` is the (signed) volume  of the trade i.e. +ve if the party was a buyer and -ve if a seller.

```MTM_MOVE < 0``` , means the party will have collateral deducted from their accounts to cover their position.  Conversely,  if  ```MTM_MOVE > 0```  the trader will receive collateral  into their account.


2. The settlement function calculates how much to *collect* from the margin accounts of those whose change in mark to market has been negative / incurred loss.  This will be collected into the market's *margin* account via a set of transfer requests.  The collection instruction should first collect from a trader's margin account for the market and then the trader's general account and then the market's insurance pool.  

3. This will result in ledger entries  being formulated ( see [settlement](./0002-settlement.md) ) which adhere to double entry accounting and record the actual transfers that occurred on the ledger.

4. If the net amounts are what was requested, the settlement function will formulate instructions to *distribute* to the margin accounts of those whose moves have been positive according to the amount they are owed. These transfers will be requested to debit from the market's *margin* account and credit the traders who have a  positive mark-to-market.

5. If there's not enough money for the reallocation due to some traders having insufficient money in their margin account and general account to handle the price / position move, and if the insurance pool can't cover the full *distribute* requirements, the settlement function will need to alter the "distribute" amounts accordingly. The amounts are altered using a formula which is out of scope for this ticket. As a stub implementation distribution can pro-rata the amount in the settlement account between positions by relative position size.

Note: a close out profit / loss is automatically captured in trader margin accounts via mark-to-market reallocation described above. The reduction in open volume will be used when risk margins are next calculated.

Note: successive mark-to-market settlement transfer requests can be netted.

# Pseudo-code / Examples



# Test cases

See [here](https://drive.google.com/file/d/18o_sCC5OLS59is4cvSce8lcxQAigCrB1/view?usp=sharing) for examples / scenarios.


