Feature name: candles

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.

# Summary
Candle charts are used to visualise trades over fixed length periods of time. Each period has an `open`, `close`, `high` and `low` value which can be represented as a candle on a chart. The time period length is selected from a predefined set of possible lengths. The node is responsible for generating real time candle information a well as offering access to historic values.


# Guide-level explanation
The candles api allows a client to receive real time updates to the candle information for a given market as well as historic data created since the opening of the market. When the client requests data they specify the `interval` value which is the length of time for each candle. Such time periods can be 1 minute, 5 minutes, 15 minutes etc. During real time updates a candle message will be sent out when even a trade occurs ont he market so that the mark prices moves. The candle message will contain information about the interval size of the candle, the start time of the period and the open, close, high, low and volume values for the trades within this period.

For historic data the client can request candle data for any valid interval size and either between two points in time or for a time relative to the current time up to the current time.

e.g. 
RequestHistoricCandleData(5MIN, "01-01-2020:00:00", "01-01-2020:12:00")
RequestHistoricCandleData(1D, "01-01-2020:00:00")


# Reference-level explanation

Candle data is divided up into time periods all with equal size given by the interval size. The open price for a candle is the mark price when the candle interval time is started. Every trade that occurs inside that candle time period is used to update the high/low and volume value. Then when the period ends the close price is set to the current mark price. As a new candle period is started as soon as one finishes, the close price of the first will always be the same as the open price for the next.

During an auction no trades occur and thus there is no change in mark price. In the case of the opening auction there is no mark price set at all until after the auction is complete. In these case we would create candle messages with an empty volume value to indicate that no trades had taken place. This would also happen if the client queried for historic data that included a period of auction.

The generation of the candle data and the process of distributing the message is decoupled so that they do not have to happen at the same frequency. This allows us to control the message and data rate coming out from the node even when the mark price is changed rapidly.


# Pseudo-code / Examples
If you have some data types, or sample code to show interactions, put it here

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
