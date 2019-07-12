# Outline
The network calculates settlement cashflows for all traders with open positions, every time the mark price of the product changes. 

## Design

*Settlement Engine instructs the Collateral Engine via TransferRequests to reallocated collateral between trader's margin accounts based on MTM moves*

1. When the _Mark Price_ changes, the network calculates settlement cash flows for each trader according to the following formula.

```
MTM_MOVE( party ) =  party.PREV_OPEN_VOLUME * ( MARK_PRICE_NEW - MARK_PRICE_PREV ) + SUM(from i=1 to new_trades.length)( new_trade(i).VOLUME(party) * ( MARK_PRICE_NEW - new_trade(i).PRICE ) )
```
*where*

```party.PREV_OPEN_VOLUME``` refers to the trader's open volume at the last MTM calculation.
```new_trades``` refers to any trades that the party has been involved in since the last MTM calculation.
```VOLUME(party)``` is the (signed) volume  of the trade i.e. +ve if the party was a buyer and -ve if a seller.


2. The settlement engine then instructs the collateral engine to *collect* from the margin accounts of those whose change in mark to market has been negative / incurred loss.  This will be collected into the market's *margin* account via a set of transfer requests ( see #81 ).  The collection instruction should first collect from a trader's margin account for the market and then the trader's general account and then the market's insurance pool.  

3. The collateral engine will respond with the resulting ledger entries ( see [settlement](./0002-settlement.md) ).

4. If the net amounts are what the settlement engine requested, the settlement engine will then instruct the collateral engine to *distribute* to the margin accounts of those whose moves have been positive, from the market's *margin* account via a set of transfer requests.

5. If there's not enough money for the reallocation due to some traders having insufficient money in their margin account and general account to handle the price / position move, and if the insurance pool can't cover the full *distribute* requirements, the settlement engine will need to alter the "distribute" amounts before sending them to the collateral engine. The amounts are altered using a formula which is out of scope for this ticket. As a stub implementation distribution can pro-rata the amount in the settlement account between positions by relative position size.

Note: a close out profit / loss is automatically captured in trader margin accounts via mark-to-market reallocation described above. The reduction in open volume will be detected by the risk engine and therefore the required risk margins will adjusted accordingly.

Note: successive MTM settlement transfer requests can be netted by the SE


## Examples

See [here](https://drive.google.com/file/d/18o_sCC5OLS59is4cvSce8lcxQAigCrB1/view?usp=sharing) for examples / scenarios.


