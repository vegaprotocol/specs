# Outline
The network calculates the mark to market for all traders with open positions, every time the mark price of the product changes. 

## Design

*Settlement Engine instructs the Collateral Engine via TransferRequests to reallocated collateral between trader's margin accounts based on MTM moves*

1. After every change in mark price, the change in [mark to market](../wikis/Trading-and-Protocol-Glossary#mark-to-market) of all [open positions](../wikis/Trading-and-Protocol-Glossary#open-position) is calculated by the position engine.  

2. The settlement engine then instructs the collateral engine to *collect* from the margin accounts of those whose change in mark to market has been negative / incurred loss.  This will be collected into the market's *margin* account via a set of transfer requests ( see #81 ).  The collection instruction should first collect from a trader's margin account for the market and then the trader's general account and then the market's insurance pool.  

3. The collateral engine will respond with the resulting ledger entries ( see [settlement](./0002-settlement.md) ).

4. If the net amounts are what the settlement engine requested, the settlement engine will then instruct the collateral engine to *distribute* to the margin accounts of those whose moves have been positive, from the market's *margin* account via a set of transfer requests.

5. If there's not enough money for the reallocation due to some traders having insufficient money in their margin account and general account to handle the price / position move, and if the insurance pool can't cover it, the settlement engine will initiate position resolution (See [position resolution](./0012-position-resolution.md)).  

6. A close out profit / loss is automatically captured in trader margin accounts via mark-to-market reallocation described above. The reduction in open volume will be detected by the risk engine and therefore the required risk margins will adjusted accordingly.

7. Any time the margin requirements or MTM values change (including due to position reduction, risk factor change or MTM gain / loss) the excess margin above the margin requirement is released if the excess margin amount is > margin release threshold

8. Released means that a transfer request is submitted to the CE to remove the required funds from the trader's margin account for that market to the trader's main account

Note: successive MTM settlement transfer requests can be netted by the SE


## Examples


