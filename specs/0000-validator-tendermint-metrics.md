Feature name: Validator Tendermint Performance Metrics
Start date: 2021-03-11

# Acceptance Criteria
- [ ] For each Tendermint block, a list of validators (by public key or IP address) that voted in the block is available. This list either:
  - [ ] lists all voters, and orders the voters by vote arrival time (so that the first 2/3 can be deduced); or
  - [ ] lists only the first 2/3 of voters
- [ ] For each validator, a list of vote arrival times is available
- [ ] After a network has been active for some minimum amount of time (say 100 blocks), statistics for vote time (mean, standard deviation, percentiles) are available for each validator
- [ ] By looking at the above statistics, it is clear which validators (if any) are at the end of high-latency network connections.
- [ ] If possible, also provide statistics on the point-to-point connection speeds between validators (e.g., measuring the time
      between sending a message and receiving an ack, if that exists.

Listing all voters is preferable if the API allows that reliably
The protocol halso as a pre-vote which is interesting (ig the API gives us that data, too)
Slowness could also come from computational overload; this might be interesting for us to know for other reasons.

# Summary
Validator nodes are located across the world, and therefore have internet connections with varying levels of latency between them.
They also might have different levels of computational or communication ressources; while someone who is far away and thus has
a higher latency at least contributes to diversity, someone who sits in a central place with an underpowered server is slowing everyone
down.

Tendermint consensus requires more than two thirds of validators sign pre-commit votes for a block at the same round ([ref](https://docs.tendermint.com/master/nodes/validators.html#committing-a-block)). It is of interest to gather statistics on the timing of vote submission in order to analyse over time which validators are signing and communicating their votes quickly enough to be in the first two thirds of nodes that are actively participating in consensus.

As external validators participate in short-lived iterations of Testnet or early Mainnet, these statistics will help rank validators, which will inform the decision (made not by Vega but by an external organisation/foundation of some sort) on which validators are best for later long-lived iterations of Testnet and Mainnet.

Also, in later versions, some form of performance evaulation will be linked to rewards.

# Guide-level explanation
Tendermint has API endpoints that provide access to performance statistics (or enough raw data from which statistics can be calculated) of validators as they participate in consensus with varying levels of latency.

# Reference-level explanation
To be decided: Should this be implemented in Tendermint, or Vega, or (if all required Tendermint data is already available) an external application or script of some sort.

# Examples
Tendermint API endpoints that provide some information already exist:

`GET /block?height=_`: https://lb.testnet.vega.xyz/tm/block?height=2

Output extract (extraneous info removed):

```json
{
  "result": {
    "block": {
      "last_commit": {
        "height": "1",
        "round": "0",
        "signatures": [
          {
            "validator_address": "2D1D611B64C32B9836BEBDA7FC630CF6B0067862",
            "timestamp": "2021-03-03T20:29:15.840457189Z",
            "signature": "...=="
          },
          {
            "validator_address": "6582E9708C325466F1CE7F5DE6D23E39DEB17888",
            "timestamp": "2021-03-03T20:29:15.995539603Z",
            "signature": "...=="
          },
          {
            "validator_address": "6E3A3F9173DF0F9B36330CDFCBCD3E07E29F8AC8",
            "timestamp": "2021-03-03T20:29:15.980285035Z",
            "signature": "...=="
          },
          {
            "validator_address": "7A3AE3A6E39443BF60141EFEEAF0047071B8E533",
            "timestamp": "2021-03-03T20:29:15.797754378Z",
            "signature": "...=="
          },
          {
            "validator_address": "BB3FD703B1E42F8158291F2F260122F8ACAEE1CC",
            "timestamp": "2021-03-03T20:29:15.674719552Z",
            "signature": "...=="
          }
        ]
      }
    }
  }
}
```

In the above example, all 5 validators voted, but only 4/5 were required to get over the 2/3 threshold:

| Validator public key                       | Vote arrival time                | Necessary for consensus |
| :----------------------------------------- | :------------------------------: | :---------------------- |
| `BB3FD703B1E42F8158291F2F260122F8ACAEE1CC` | `2021-03-03T20:29:15.674719552Z` | Yes |
| `7A3AE3A6E39443BF60141EFEEAF0047071B8E533` | `2021-03-03T20:29:15.797754378Z` | Yes |
| `2D1D611B64C32B9836BEBDA7FC630CF6B0067862` | `2021-03-03T20:29:15.840457189Z` | Yes |
| `6E3A3F9173DF0F9B36330CDFCBCD3E07E29F8AC8` | `2021-03-03T20:29:15.980285035Z` | Yes |
| `6582E9708C325466F1CE7F5DE6D23E39DEB17888` | `2021-03-03T20:29:15.995539603Z` | No  |

