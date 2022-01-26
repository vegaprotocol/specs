# Target stake

This spec outlines how to measure how much stake we want committed to a market relative to what is happening on the market (currently open interest).
The target stake is a calculated quantity, utilised by various mechanisms in the protocol:

- If the LPs total committed stake is less than c_1 x `target_stake` we trigger liquidity auction. See [Liquidity Monitoring](./0035-LIQM-liquidity_monitoring.md). Note that there is a one-to-one correspondence between the amount of stake LPs committed and the supplied liquidity. 
The parameter c_1 is a market parameter (with network parameter `market.liquidity.targetstake.triggering.ratio` providing a default value) defined in the [liquidity Monitoring](./0035-LIQM-liquidity_monitoring.md) spec.
- It is used to set the fee factor for the LPs: see [Setting fees and rewarding LPs](./0042-LIQF-setting_fees_and_rewarding_lps.md).

## Definitions / Parameters used
- **Open interest**: the volume of all open positions in a given market.
- `target_stake_time_window` is a market parameter (with network parameter `market.stake.target.timeWindow` giving a default value) defining the length of window over which we measure open interest (see below). This should be measured in seconds and a typical value is one week i.e. `7 x 24 x 3600` seconds.
- `target_stake_scaling_factor` is a market parameter (with network paramter `market.stake.target.scalingFactor` giving a default value) defining scaling between liquidity demand estimate based on open interest and target stake.
- `risk_factor_short`, `risk_factor_long` are the market risk factors, see [the Quant Risk Models spec](./0018-RSKM-quant_risk_models.ipynb).
- `mark_price`, see [mark price](./0009-MRKP-mark_price.md) spec.
- `indicative_uncrossing_price`, see [auction](./0026-AUCT-auctions.md) spec.


### Current definitions

First, `max_oi` is defined  maximum (open interest) measured over a time window, 
`t_window = [max(t-target_stake_time_window,t0),t]`. Here `t` is current time with `t0` being the end of market opening auction. Note that `max_oi` should be calculated recorded per transaction, so if there are multiple OI changes withing the same block (which implies the same timestamp), we should pick the max one, NOT the last one that was processed.

Example 1:
`t_window_for_target_stake = 1 hour`
the market opened at `t_0 = 1:55`. 
We have the following information about open interest over time:
```
[time, OI]
[3:51, 140]
[3:57, 120]
[4:32, 90]
[4:32, 60]
[4:33, 70]
[4:52, 110]
```
and the current time is `4:53`
then the `t_window = [3:53, 4:53]`. The `max_oi` is `120`.

Example 2: As above but the market opened at `t_0 = 4:15`. Then `t_window = [4:15,4:53]` and `max_oi` is `110`. 

From `max_oi` we calculate 

`target_stake = reference_price x max_oi x target_stake_scaling_factor x rf`,

where `reference_price` is `mark_price` when market is in continuous trading mode and `indicative_uncrossing_price` during auctions (if it's available, otherwise use `mark_price` which may be 0 in case of an opening auction), and `rf = max(risk_factor_short, risk_factor_long)`. Note that currently we always have that `risk_factor_short >= risk_factor_long` but this could change once we go beyond futures... so safer to take a `max`.
Note that the units of `target_stake` are the settlement currency of the market as those are the units of the `reference_price`.

Example 3: if `target_stake_scaling_factor = 10`, `rf = 0.004` and `max_oi = 120` then `target_stake = 4.8`.

### APIs
* target stake
  * return current (real-time) target stake when market is in default trading mode.
  * return theoretical (based on idicative uncrossing volume) target stake when market is in auction mode.

### Acceptance Criteria
* examples showing a growing list (before we hit t-window) (<a name="0041-TSTK-001" href="#0041-TSTK-001">0041-TSTK-001</a>)
* examples showing a list that drops off values (<a name="0041-TSTK-002" href="#0041-TSTK-002">0041-TSTK-002</a>)
* if new value that isn't a maximum, the liquidity demand doesn't change. (<a name="0041-TSTK-003" href="#0041-TSTK-003">0041-TSTK-003</a>)
