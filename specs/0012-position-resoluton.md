Position resolution is instigated when one or more participant's collateral balance is insufficient to fulfil their settlement or margin liabilities.

**Case 1.** During settlement, either during [mark-to-market settlement](0003-mark-to-market-settlement.md) or for [settlement expiry] (0004-settlement-at-instrument-expiry.md), a set of traders may have insufficient market collateral to cover the required settlement liability. Position resolution is triggered by the settlement engine (#81), atomically, so that the resolution occurs before further blockchain transactions are processed.

Note: Position resolution for settlement only occurs if the insurance pool has insufficient capital to cover the liability shortfall.

**Case 2.** If the risk margin requirements change, traders can find themselves with insufficient capital to cover their positions.

Note: In this situation the insurance pool isn't used to cover their margin liabilities (insurance pool is only used for settlement liabilities).

Position resolution will be immediately triggered if a collateral search fails.

## Position resolution algorithm

See [Whitepaper](../product/wikis/Whitepaper), Section 5.3 , steps 1 - 3

1. Any trader that has insufficient capital to cover their settlement liability has all their open orders on that market are cancelled.

2. The collection of long and short positions that are 'bankrupt' net to give an amount of *either* long or short volume that is "net distressed".  (note, this will only occur in Case 2)

3. The outstanding liability is closed out in the market with a single market order (and hence the network is the counterpart of all trades that result from this market order). The network now has a position (for an instance in time).

4. It then calculates the volume weighted average price of its close outs. The system then generates a set of trades with the bankrupt traders all at the volume weighted average price. The open positions of all the "distressed" traders is now zero.

5. All bankrupt trader's remaining collateral in this market's margin account is confiscated to the market's insurance pool.

**Note:** If the mark-to-market settlement from this order is unable to be covered by the margin accounts of the "distressed" traders, the insurance pool will be used and then loss socialisation.  This will automatically occur due to the way the [mark-to-market settlement](0003-mark-to-market-settlement.md) algorithm works.

## Acceptance Criteria

* [ ] Cancels all orders of "distressed traders"
* [ ] Nets long and short positions correctly
* [ ] Closes out the distressed volume on the order book
* [ ] Open positions of distressed traders are closed