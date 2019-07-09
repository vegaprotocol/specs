# Position Resolution

Position resolution is the mechanism which deals with closing out distressed positions. It is instigated when one or more participant's collateral balance is insufficient to fulfil their settlement or margin liabilities.

## Position resolution algorithm

See [Whitepaper](../product/wikis/Whitepaper), Section 5.3 , steps 1 - 3

1. Any trader that has insufficient capital to cover their settlement liability has all their open orders on that market are cancelled. Note, despite this potentially freeing up margin for the trader, we don't re-look at their collateral utilisation. They remain a 'distressed trader' and position resolution continues.

2. The collection of long and short positions that are 'bankrupt' net to give an amount of *either* long or short volume that is "net distressed". If there is perfect netting (i.e. the total volume of distressed long positions = total volume of distressed short positions), the next two steps won't occur. The positions are all considered to be closed at the _Mark Price_.  

3. The outstanding liability is closed out in the market with a single market order (and hence the network is the counterpart of all trades that result from this market order). The network now has a position (for an instance in time) which is comprised of a set of trades that transacted with the non-distressed traders on the order book. Note, any of the non-distressed traders who through this action have closed out volume need to have these settled against that close out price. Since the whole market is not being marked to market against this volume weighted price, and the price by definition is more beneficial than the last settlement run's mark price, the insurance pool will be used to cover this move.

4. The network then calculates the volume weighted average price of its (new) open position. The system then generates a set of trades with the bankrupt traders all at this volume weighted average price. The open positions of all the "distressed" traders is now zero.

5. All bankrupt trader's remaining collateral in this market's margin account is confiscated to the market's insurance pool.

**Note:** If the mark-to-market settlement from this order is unable to be covered by the margin accounts of the "distressed" traders, the insurance pool will be used and then loss socialisation.  This will automatically occur due to the way the [mark-to-market settlement](0003-mark-to-market-settlement.md) algorithm works.

## Acceptance Criteria

* [ ] Cancels all orders of "distressed traders"
* [ ] Nets long and short positions correctly
* [ ] Closes out the distressed volume on the order book
* [ ] Open positions of distressed traders are closed

