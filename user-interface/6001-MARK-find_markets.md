# Find markets

## Closed Markets

- **Must** see market's instrument code (<a name="6001-MARK-001" href="#6001-MARK-001">6001-MARK-001</a>)
- **Must** see market's instrument name (sometimes labelled 'description') (<a name="6001-MARK-002" href="#6001-MARK-002">6001-MARK-002</a>)
- **Must** see status (<a name="6001-MARK-003" href="#6001-MARK-003">6001-MARK-003</a>)
- **Must** see the settlement date (<a name="6001-MARK-004" href="#6001-MARK-004">6001-MARK-004</a>)
  - **Must** use `marketTimestamps.closed` field if market is indeed closed (<a name="6001-MARK-005" href="#6001-MARK-005">6001-MARK-005</a>)
  - **Must** fallback to using the `settlement-expiry-date:<date>` if market is not fully settled but trading is terminated (<a name="6001-MARK-006" href="#6001-MARK-006">6001-MARK-006</a>)
  - **Must** indicate if the date shown is 'expected' (metadata value) or if it is the true closed datetime (`marketTimestamps.closed`) (<a name="6001-MARK-007" href="#6001-MARK-007">6001-MARK-007</a>)
  - **Must** show the date formatted for the user's locale (<a name="6001-MARK-008" href="#6001-MARK-008">6001-MARK-008</a>)
  - **Must** link to the trading termination oracle spec (<a name="6001-MARK-009" href="#6001-MARK-009">6001-MARK-009</a>)
  - **Could** show the settlement date as words relative to now (E.G. '2 days ago') (<a name="6001-MARK-010" href="#6001-MARK-010">6001-MARK-010</a>)
- **Must** show the last best bid price (<a name="6001-MARK-011" href="#6001-MARK-011">6001-MARK-011</a>)
- **Must** show the last best offer price (<a name="6001-MARK-012" href="#6001-MARK-012">6001-MARK-012</a>)
- **Must** show the final mark price (<a name="6001-MARK-013" href="#6001-MARK-013">6001-MARK-013</a>)
- **Must** show the settlement price (<a name="6001-MARK-014" href="#6001-MARK-014">6001-MARK-014</a>)
  - **Must** link to the settlement data oracle spec (<a name="6001-MARK-015" href="#6001-MARK-015">6001-MARK-015</a>)
  - **Must** retrieve settlement data from corresponding oracle spec (<a name="6001-MARK-016" href="#6001-MARK-016">6001-MARK-016</a>)
- **Could** show current connected user's PNL for that market (<a name="6001-MARK-017" href="#6001-MARK-017">6001-MARK-017</a>)
- **Must** show the settlement asset (<a name="6001-MARK-018" href="#6001-MARK-018">6001-MARK-018</a>)
  - **Must** be able to view full asset details (<a name="6001-MARK-019" href="#6001-MARK-019">6001-MARK-019</a>)
- **Must** provide a way to copy the market ID (<a name="6001-MARK-020" href="#6001-MARK-020">6001-MARK-020</a>)
