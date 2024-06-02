# Candles

Candle data represents the market information within a fixed time window of a market. The candle message will contains the the current price values as well as the price that the market was at when the time windows was started as well was the close price when the time window finishes. Every time the market information changes, the candle data will be updated and sent out to any subscribers of the data. Also when the time window expires and moves into a new window a candle update is sent out. This occures even if no movement has happened in the market.

# Time periods for candles intervals

The following time intervals must be supported by the candle subscription service

* 1 minute interval
* 5 minute interval
* 15 minute interval (default)
* 1 hour interval
* 6 hour interval
* 1 day interval

# Data inside a candle message

The minimum amount of information that must be included in a candle message is:

```
type candle struct {
  high      // The highest price the market has been during this time window 
  low       // The lowest price the market has been during this time window
  open      // The price the market was at when the time window started
  close     // The price the market was at when the time window closed
  volume    // The current traded volume in this time window
  interval  // How long is the time window
}
```

# When are messages sent

A candle message is sent whenever the following is true:
* A trade occurs
* A new time window interval is started

# When do the intervals run

The time windows are created starting from midnight UTC so the 1 day interval will run though each day and start again at midnight. All other intervals start at the same time and roll over when required. This is to ensure that candles recieved from any data node on the network will give very similar results.

# Acceptence Criteria
* Subscriptions can be set up for any of the intervals above (<a name="0012-NP-CAND-001" href="#0012-NP-CAND-001">0012-NP-CAND-001</a>)
* When the mark price changes a candle update is sent (<a name="0012-NP-CAND-002" href="#0012-NP-CAND-002">0012-NP-CAND-002</a>)
* When the mark price moves above the previous high value, the high value is updated (<a name="0012-NP-CAND-003" href="#0012-NP-CAND-003">0012-NP-CAND-003</a>)
* When the mark price moves below the previous low price, the low price is updated (<a name="0012-NP-CAND-004" href="#0012-NP-CAND-004">0012-NP-CAND-004</a>)
* Any orders matched during an interval result in the volume in the candle increasing by the amount matched (<a name="0012-NP-CAND-005" href="#0012-NP-CAND-005">0012-NP-CAND-005</a>)
* At the start of a new interval a candle message is sent even if the market has not changed (<a name="0012-NP-CAND-006" href="#0012-NP-CAND-006">0012-NP-CAND-006</a>)
