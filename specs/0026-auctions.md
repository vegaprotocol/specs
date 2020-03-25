Feature name: auctions
Start date: 2019-12-13
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary

As of right now, vega implements continuous trading, in fact every time an order is placed, vega evaluates it with the other side of the book and if the order crosses, a trade will result from it. This specification will introduce new trading modes for vega as auctions.

# Guide-level explanation
In comparison to continuous trading, the auction mode for a market, is a state of the orderbook where each order placed are just sitting on the book, for a given period of time or until some requirements are met (called `call period`), then the matching orders are uncrossed.

An auction's purpose is to help with price discovery, and are mostly useful in very liquid markets. In traditional markets (where markets open and close every day) we can run an open and closing auction for the price to stabilise at both ends.

# Reference-level explanation
As mentioned earlier, this specification introduces new trading modes. A first one which purpose is to calibrate a market / help with price discovery when a new market is started. A second one meant to be trading only through auction called `Frequent batch auction`.

## First mode (name to be find, but it may just be actually the continuous trading changing to always start with an auction ?)
This trading mode is very similar to the Continuous trading mode for a market. In this configuration, a market will start in auction mode, then once the auction comes to an end the market will switch back to the continuous trading mode, and will stay like until there's a need for it to go in auction mode again (e.g: based on the price changes).
A market cannot be in both mode at the same time and will trade ever in a auction or continuous trading.

As a first implementation this feature is expected to only support starting the markets in auctions, then once the auction reaches an end, switch back to the continuous trading mode forever.

## Frequent batch auction
The frequent batch auction mode is a trading mode in perpetual auction, meaning that all uncrossing on the book is done at the end of auction period, then once this is done, and trades happen, a new auction period is started, and this forever until the market close.
e.g: auctions could be set to last 10 minutes, then every 10 minutes the book would be uncrossing, and generating trades.

## An auction comes to an end
As part of the market framework, we need to be able to specify the duration of auctions period. This should be added as a new setting to the trading modes.
We can also imagine that an auction period could come to an end once a give number of orders have been placed on the system.

### Volume maximising prices
Once the auction period finishs, vega needs to figure out the best price for the order range in the book which can be uncrossed. This is called volumed maximising pricing.
Once this range is decided we will run an algorithm in order to decided what's the best price to create the trades at (the algorithm is specified in a separate specification, @barney, @tamlyn, please edit / link it here, and had detail in here as well as I imagine this is quite weak at the moment).

As a naive/first implementation we should decide the price as being the middle price in the volume maximising range.

## New core APIs related to auctions
These new APIs need to expose data, some of which will be re-calculated each time the state of the book changes and will expose information about the market in auction mode:
- how long the market has been in auction mode
- when does the next auction period start
- how long is a period
- the indicative uncrossing price (e.g: if we uncross now what would be the best bid/ask prices of the trades)
- indicative uncrossing volume

## Restriction for markets in auction modes
Market orders are not permitted while a market is using auction.
Also Fill Or Kill and Immediate Or Cancel time in force are not allowed.

## First/Naive implementation
As a first version we expect:
- A market in continuous trading mode, to be configured so it can start with an auction for a given period of time, then switch to continuous trading for the rest of the life of the market.
- A market to be configured to run in frequent batch auction mode, which could not be changed to a continuous trading later on.

# Pseudo-code / Examples
Possible changes for the TradingMode configuration.
```
enum PricingAlgorithm {
	VolumeAveragePrice = 1,
	// etc ...
}

message AuctionConfig {
	int64 callPeriodDuration = 1;
	PricingAlgorithm algo = 2;
}

message ContinuousTrading {
  bool hasOpeningAuction = 1;
  AuctionConfig config = 2;
}

message FrequentBatchAuction {
	AuctionConfig config = 1;
}

message Market {
  // common market fields
  oneof tradingMode {
    ContinuousTrading continuous = 100;
    FrequentBatchAuction auctions = 101;
  }
}
```
# Acceptance Criteria
- [] As a user, I can configure a market through the market configuration to use auction mode
 - [] I can define an opening auction for a continuous trading market, and the duration of the call period.
 - [] I can define a market to operate as Frequent Batch Auction, and the duration of the call period.
 - [] I can choose what algorithm is used to decided the pricing at the end of the auction period.
- [] As the vega network, in auction mode, all orders are placed in the book but never uncross until the end of the auction period.
- [] As a user, I can place an order when the market is in auction mode, but it will not trade immediately.
- [] As a user, I cannot place a Market order, or and order using FOK or IOC time in force.
- [] As a user, I can get information about the trading mode of the market (through the market framework)
- [] As a user, I can get real time information throught the API about a market in auction mode: indicative crossing price, indicative crossing volume.


# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
