# Position resolution

## Acceptance Criteria

- All orders of "distressed traders" are cancelled (<a name="0012-POSR-001" href="#0012-POSR-001">0012-POSR-001</a>)
- Open positions of distressed traders are closed (<a name="0012-POSR-002" href="#0012-POSR-002">0012-POSR-002</a>)
- One market order is submitted for the net liability (<a name="0012-POSR-003" href="#0012-POSR-003">0012-POSR-003</a>)
- Mark Price is never updated during position resolution (<a name="0012-POSR-004" href="#0012-POSR-004">0012-POSR-004</a>)
- Non-distressed traders who trade with the network because their open orders are hit during the close out trade have their positions settled correctly. (<a name="0012-POSR-005" href="#0012-POSR-005">0012-POSR-005</a>)
- When a distressed party has a [staking account](./0013-ACCT-accounts.md) with the same currency as the settlement currency of the market where it's distressed the staking account is NOT used in margin search and liquidation. (<a name="0012-POSR-006" href="#0012-POSR-006">0012-POSR-006</a>)
- When a party is distressed at the point of leaving an auction it should get closed out as soon as the market returns to continuous trading mode and all the parked orders (pegged and LP) get added back to the order book. (<a name="0012-POSR-008" href="#0012-POSR-008">0012-POSR-008</a>)

## Summary

Position resolution is the mechanism which deals with closing out distressed positions on a given market. It is instigated when one or more participant's collateral balance is insufficient to fulfil their settlement or margin liabilities.

## Guide-level explanation

## Reference-level explanation

Any trader that has insufficient collateral to cover their margin liability is referred to as a "distressed trader".

### Position resolution algorithm

See [Whitepaper](https://vega.xyz/papers/vega-protocol-whitepaper.pdf), Section 5.3 , steps 1 - 3

1. A "distressed trader" in cross-margining mode has all their open orders on that market cancelled. Note, the network must then recalculate their margin requirement on their remaining open position, perform one final margin search and if they now have sufficient collateral (i.e. aren't in the close out zone) they are no longer considered a distressed trader and not subject to position resolution. The market may at any point in time have multiple distressed traders that require position resolution. They are 'resolved' together in a batch.
1. The batch of distressed open positions that require position resolution may be comprised of a collection of long and short positions. The network calculates the overall net long or short position. This tells the network how much volume (either long or short) needs to be sourced from the order book. For example, if there are 3 distressed traders with +5, -4 and +2 positions respectively.  Then the net outstanding liability is +3. If this is a non-zero number, do Step 3.
1. This net outstanding liability is sourced from the market's order book via a single market order (in above example, that would be a market order to sell 3 on the order book) executed by the network as a counterpart. This internal entity is the counterpart of all trades that result from this single market order and now has a position which is comprised of a set of trades that transacted with the non-distressed traders on the order book. Note, the network's order should not incur a margin liability. Also, these new positions (including that incurred by the network) will need to be "MTM settled". This should happen after Step 5 to ensure we don't bankrupt the insurance pool before collecting the distressed trader's collateral.  This has been included as Step 6.
1. The network then generates a set of trades with all the distressed traders all at the volume weighted average price of the network's (new) open position.   These trades should be readily distinguished from the trades executed by the network counterpart in Step 3 (suggest by a flag on the trades)
    1. Note, If there was no market order (i.e step 3 didn't happen) the close-out price is the most recently calculated _Mark Price_. See Scenario 1 below for the list of resulting trades for the above example. The open positions of all the "distressed" traders is now zero and the networks position is also zero. Note, no updates to the _Mark Price_ should happen as a result of any of these trades (as this would result in a new market-wide mark to market settlement at this new price and potentially lead to cascade close outs).
1. All bankrupt trader's remaining collateral in their margin account for this market is confiscated to the market's insurance pool.
1. If an order was executed on the market (in Step 3), the resulting trade volume between the network and passive orders must be mark-to-market settled for all parties involved including the network's internal 'virtual' party. As the network's closeout counterparty doesn't have collateral, any funds it 'owes' will be transferred from the insurance fund during this settlement process (as defined in the [settlement spec](./0003-MTMK-mark_to_market_settlement.md).). It's worth noting that the network close-out party must never have margins calculated for it. This also should naturally happen because no margin calculations would happen during the period that the network temporarily (instantaneously) has an open position, as the entire position resolution process must happen atomically.

### Note

- Entire distressed position should always be liquidated - even if reducing position size, by say 50%, would result in the remaining portion being above the trader's maintenance margin.
- When there's insufficient volume on the order-book to close out a distressed position no action should be taken: the position remains open and any amounts in trader's margin account should stay there. Same principle should apply if upon next margin recalculation the position is still distressed.
- If the party is distressed at a point of leaving auction it should be closedout immediately (provided there's enough volume on the book once all the pegged and liquidity provision orders get redeployed).

## Examples and Pseudo code

### _Scenario -  All steps_

`Trader1 open position: +5`
`Trader1 open orders:  0`
`Trader2 open position: -4`
`Trader2 open orders:   0`
`Trader3 open position: +2`
`Trader3 open orders:   0`

#### STEP 1

No traders are removed from the distressed trader list.

#### STEP 2

`NetOutstandingLiability = 5 - 4 + 2 = 3`

#### STEP 3

```json
LiquiditySourcingOrder: {
  type: 'market',
  direction: 'sell',
  size: 3
}

LiquiditySourcingTrade1: {
  buyer: Trader4,
  seller: Network,
  size: 2,
  price: 120,
  type: 'liquidity-sourcing'
}

LiquiditySourcingTrade2: {
  buyer: Trader5,
  seller: Network,
  size: 1,
  price: 100,
  type: 'liquidity-sourcing'

}

```

#### STEP 4

Close out trades are generated with the distressed traders

```json
CloseOutTrade1 {
  buyer: Network,
  seller: Trader1,
  size: 5,
  price: 113.33,
  type: 'safety-provision'
}

CloseOutTrade2 {
  buyer: Trade2,
  seller: Network,
  size: 4,
  price: 113.33,
  type: 'safety-provision'
}

CloseOutTrade3 {
  buyer: Network,
  seller: Trader3,
  size: 2,
  price: 113.33,
  type: 'safety-provision'
}
```

This results in the open position sizes for all distressed traders and the network entities to be zero.

`// OpenPosition of Network =  -3 +5 -4 +2 = 0`
`// OpenPosition of Trader1 =  +5 -5 = 0`
`// OpenPosition of Trader2 = -4 +4 =  0`
`// OpenPosition of Trader3 =  +2 - 2 = 0`

#### STEP 5

The collateral from distressed traders is moved to the insurance pool

```json
// sent by Settlement Engine to the Collateral Engine
TransferRequest1 {
  from: [Trader1_MarginAccount],
  to: MarketInsuranceAccount,
  amount: Trader1_MarginAccount.size, // this needs to be the full amount
}

TransferRequest2 {
  from: [Trader2_MarginAccount],
  to: MarketInsuranceAccount,
  amount: Trader2_MarginAccount.size, // this needs to be the full amount
}

TransferRequest3 {
  from: [Trader3_MarginAccount],
  to:  MarketInsuranceAccount,
  amount: Trader3_MarginAccount.size, // this needs to be the full amount
}
```

#### STEP 6

Traders from step 3 need to be settled.

Prior to STEP 3 trades, assume Trader 4 and Trader 5 had the following open positions.

`// OpenPosition of Trader4 =  -3`
`// OpenPosition of Trader5 =  15`

Trader 4 has therefore closed out 2 contracts through the `LiquiditySourcingTrade` 1. These need to be settled against the trade price.

```json
TransferRequest4 {
  from: [MarketInsuranceAccount],
  to:  Trader4_MarginAccount,
  amount: (120 - PreviousMarkPrice) * -2, // this is the movement since the last settlement multiplied by the volume of the closed out amount
}

```
