# Pegged and Market Maker orders

## Acceptance Critieria

- TBD


## Summary

Market Makers and some other market participants are interested in maintaining limit orders on the order book that are a defined distance from a reference price (i.e. best bid, mid, best offer/ask, mark price, etc.) rather than at a specific limit price. In addition to being impossible to achieve perfectly through simple Amend commands, this method also creates many additional transactions. These problems are enough of an issue for centralised exchanges that many implement pegged orders, which are automatically repriced when the reference price mocves. For decentralised trading with greater constraints on throughput and potentially orders of magnitude higher latency, pegged orders are all but essential to maintain a healthy and liquid order book.

Pegged orders are limit orders where the price is specified of the form `REFERENCE +/- OFFSET`, therefore 'pegged' is a _price type_, and can be used for any limit order that is valid during continuous trading. A pegged order's price is calculated from the value of the reference price on entry to the order book. Pegged orders that are persistent will be repriced, losing time priority, _after processing any event_ which causes the `REFERENCE` price to change. Pegged orders are not permitted in some trading period types, most notably auctions, and pegged orders that are on the book at the start of such a period will be parked (moved to a separate off-book area) in time priority until they are cancelled or expire, or the market enters a period that allows pegs, in which case they are re-priced and added back to the order book. Pegged orders entered during a period that does not accept them will be added to the parked area. Pegged orders submitted to a market with a main trading mode that does not support pegged orders will be rejected.

Marker Maker orders are a special order type that must be used by Market Makers to fulfil their liqudity provision commitments. Market maker orders consist of a set of peg instructions and sizes which can be used to distribute liquidity over the order book at various distances from the current BBO (Best Bid / Offer). When entered, the total size of a market maker order provide equal to or greater than the amount of liquidity required by their commitment. Where the **probability density function** changes so as to cause a Market Maker's commitment to become umnet, an additional level of 'virtual' volume will be added to the worst priced order on each side of the book as needed to meet the requirements. This virtual volume will scale up and down to exactly meet the requirements, but the size specified in the Market Maker order will never be reduced even if the Market Maker is providing more liqudiity than requird **OR** the Market Maker may be in breach of their requirement until they amend the order of the requirement changes. After _fully_ processing an event (incoming transaction) that causes a Market Maker order to trade, the order will be refreshed, that is, the remaining size at each price level will be returned to the original size specified in the order, assuming the Market Maker has sufficient collateral to meet the margin requirements of the refreshed order along with their updated position. 


## Guide-level explanation

