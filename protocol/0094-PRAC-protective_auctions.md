# Protective auctions

The protocol has a number of protective [auctions](./0026-AUCT-auctions.md) to gather more information from market participants before carrying on with price discovery process at times of increased uncertainty or when continuous functioning of the network is disrupted.

## Per-market auctions

Per-market auction applies to an individual market only and are triggered by actions related directly to that market.

### Mark price monitoring  

Mark [price monitoring](./0032-PRIM-price_monitoring.md) is triggered when the next mark price would be significantly higher than what the mark-price history implies.

### Trade price  monitoring

Trade [price monitoring](./0032-PRIM-price_monitoring.md) is triggered when the next traded price would be significantly higher than what the mark-price history implies.

### Governance

Individual markets can also be put into protective auctions using a [governance](./0028-GOVE-governance.md#6-change-market-state) action.

## Network-wide auctions

Network-wide auctions put all of the markets running on a given network into auction. The triggers for those types of auctions are related to functioning of a network as a whole.

### Block time auctions

Block time auctions get triggered when the block time exceeds one of the predefined thresholds expressed in seconds. This should be done as soon as the time since the beginning of the last known block is more than any of the specified thresholds. Once such conditions get detected no more transactions relating to markets get processed before all the markets get put into auction mode. The duration of such an auction should be fixed and related to the block length.
The allowed thresholds and resulting auction periods should be implemented as a lookup-up table, sorted in the ascending order of the threshold and checked backwards. The resulting auction periods should not be summed - the auction period associated with the largest allowed threshold less than the detected block time should be used as the resulting auction duration.

The default settings should be:

  | Threshold | Network-wide auction duration |
  | --------- | ----------------------------- |
  | `10s`     | `1min`                        |
  | `1min`    | `5min`                        |
  | `10min`   | `1h`                          |
  | `1h`      | `1h`                          |
  | `6h`      | `3h`                          |
  | `24h`     | `6h`                          |



## Interaction between different auction modes

When market goes into auction mode from its default trading mode then the auction trigger which caused this should be listed as `trigger` on the API as long as that auction hasn't finished (including cases when it gets extended).

When another trigger gets activated for the market then the end time of auction for that market should be the maximum of the original end time and that implied by the latest trigger. If the original end time is larger then nothing changes. If end time implied by the latest trigger is larger than the end time gets set to this value and the `extension_trigger` field gets set (or overwritten if market has already been in an extended auction at this point) to represent the latest trigger. Governance auction is assumed to have an infinite duration (it can only be ended with an appropriate governance auction and the timing of that action is generally unknown a priori).

## Acceptance criteria

- When the network resumes after a crash (irrespective of how that was achieved) no trades get generated. All markets go into an auction of the same duration. Trades may only be generated in any market once the network-wide auction ends. (<a name="0094-PRAC-001" href="#0094-PRAC-001">0094-PRAC-001</a>)

- When the network resumes after a [protocol upgrade](./0075-PLUP-protocol_upgrades.md) no trades get generated. All markets go into an auction of the same duration. Trades may only be generated in any market once the network-wide auction ends. (<a name="0094-PRAC-002" href="#0094-PRAC-002">0094-PRAC-002</a>)

- When the lookup table for the network-wide auction is specified as:
  
  | Threshold | Network-wide auction duration |
  | --------- | ----------------------------- |
  | `3s`      | `1min`                        |
  | `40s`     | `10min`                       |
  | `2min`    | `1h`                          |

and at some point network determines that the length of the last block was 90s, the network then immediately goes into a network-wide auction with a duration of `10min`. (<a name="0094-PRAC-003" href="#0094-PRAC-003">0094-PRAC-003</a>)

- A market which has been in a per-market auction which was triggered before the network-wide auction was initiated remains in auction mode even if the exit condition for the original per-market auction gets satisfied before the network-wide auction ends. No intermediate trades get generated even in the presence of non-zero indicative volume at the point of that market's per-market auction exit condition being satisfied. The market only goes back into its default trading mode and possibly generates trades once the network-wide auction ends. (<a name="0094-PRAC-004" href="#0094-PRAC-004">0094-PRAC-004</a>)

- A market which has been in a per-market auction which was triggered before the network-wide auction was initiated remains in auction mode once the network-wide auction ends if the exit condition for the original per-market auction hasn't been met at that point and no intermediate trades get generated even in the presence of non-zero indicative volume at the point of network-wide auction end. (<a name="0094-PRAC-005" href="#0094-PRAC-005">0094-PRAC-005</a>)

- When market is in a price monitoring auction which is meant to finish at `10am`, but prior to that time a long block auction finishing at 11am gets triggered then the market stays in auction till `11am`, it's auction trigger is listed as price monitoring auction and it's extension trigger is listed as long block auction.  (<a name="0094-PRAC-006" href="#0094-PRAC-006">0094-PRAC-006</a>)

- When a market's `trigger` or `extension_trigger` is set to represent a governance suspension then no other triggers can affect the market.  (<a name="0094-PRAC-007" href="#0094-PRAC-007">0094-PRAC-007</a>)

- When a market's `trigger` and `extension_trigger` are set to represent that the market went into auction due to the price monitoring mechanism and was later extended by the same mechanism and the auction is meant to finish at `11am`, but now a long block auction is being triggered so that it ends at `10am` then this market is unaffected in any way.  (<a name="0094-PRAC-008" href="#0094-PRAC-008">0094-PRAC-008</a>)