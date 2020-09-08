# V

## Vega time
Vega time is the current time of the chain (decided through consensus); it's based on the timestamp* agreed by the nodes.
Vega needs validators to have a share idea of what time it is, regardless of their location or their clock being incorrect. 
Vega time is determined in Tendermint: ["Tendermint provides a deterministic, Byzantine fault-tolerant, source of time. Time in Tendermint is defined with the Time field of the block header."](https://docs.tendermint.com/master/spec/consensus/bft-time.html)

*The timestamp is an integer that represents the number of seconds elapsed since January 1st 1970 (UTC).
