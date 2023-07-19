# Target stake

## Target stake for derivatives markets (cash settled futures / perpetuals...)

This spec outlines how to measure how much stake we want committed to a market relative to what is happening on the market (currently open interest).
The target stake is a calculated quantity, utilised by various mechanisms in the protocol:

- If the LPs total committed stake is less than c_1 x `target_stake` we trigger liquidity auction. See [Liquidity Monitoring](./0035-LIQM-liquidity_monitoring.md). Note that there is a one-to-one correspondence between the amount of stake LPs committed and the supplied liquidity.
The parameter c_1 is a market parameter (with network parameter `market.liquidity.targetstake.triggering.ratio` providing a default value) defined in the [liquidity Monitoring](./0035-LIQM-liquidity_monitoring.md) spec.
- It is used to set the fee factor for the LPs: see [Setting fees and rewarding LPs](./0042-LIQF-setting_fees_and_rewarding_lps.md).

### Definitions / Parameters used

- **Open interest**: the volume of all open positions in a given market.
- `market.stake.target.timeWindow` is a market parameter defining the length of window over which we measure open interest (see below). This should be measured in seconds and a typical value is one week i.e. `7 x 24 x 3600` seconds.
- `market.stake.target.scalingFactor` is a market parameter defining scaling between liquidity demand estimate based on open interest and target stake.
- `risk_factor_short`, `risk_factor_long` are the market risk factors, see [the Quant Risk Models spec](./0018-RSKM-quant_risk_models.ipynb).
- `mark_price`, see [mark price](./0009-MRKP-mark_price.md) spec.
- `indicative_uncrossing_price`, see [auction](./0026-AUCT-auctions.md) spec.

#### Current definitions

First, `max_oi` is defined  maximum (open interest) measured over a time window,
`t_window = [max(t-market.stake.target.timeWindow,t0),t]`. Here `t` is current time with `t0` being the end of market opening auction. Note that `max_oi` should be calculated recorded per transaction, so if there are multiple OI changes withing the same block (which implies the same timestamp), we should pick the max one, NOT the last one that was processed.

If the market is in auction mode the `max_oi` can only increase while `auction duration` <= `market.stake.target.timeWindow`. Once the market's been in the auction for more than `market.stake.target.timeWindow` the `max_oi` is whatever the current positions and `indicative_uncrossing_volume` imply - specifically, this allows the `target_stake` to drop as a result of trades generated in the auction so that `target_stake` > `supplied_stake` (even in absence of changes to `supplied_stake`) and the market can go back to its default trading mode.

Example 1:
`t_market.stake.target.timeWindow = 1 hour`
the market opened at `t_0 = 1:55`.
We have the following information about open interest over time:

```math
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

`target_stake = reference_price x max_oi x market.stake.target.scalingFactor x rf`,

where `reference_price` is `mark_price` when market is in continuous trading mode and `indicative_uncrossing_price` during auctions (if it's available, otherwise use `mark_price` which may be 0 in case of an opening auction), and `rf = max(risk_factor_short, risk_factor_long)`. Note that currently we always have that `risk_factor_short >= risk_factor_long` but this could change once we go beyond futures... so safer to take a `max`.
Note that the units of `target_stake` are the settlement currency of the market as those are the units of the `reference_price`.

Example 3: if `market.stake.target.scalingFactor = 10`, `rf = 0.004` and `max_oi = 120` then `target_stake = 4.8`.

#### APIs

- target stake
  - return current (real-time) target stake when market is in default trading mode.
  - return theoretical (based on indicative uncrossing volume) target stake when market is in auction mode.

#### Acceptance Criteria

- examples showing a growing list (before we hit time window) (<a name="0041-TSTK-001" href="#0041-TSTK-001">0041-TSTK-001</a>)
- examples showing a list that drops off values (<a name="0041-TSTK-002" href="#0041-TSTK-002">0041-TSTK-002</a>)
- if open interest changes to a value that is less then or equal to the maximum open interest over the time window and if the mark price is unchanged, then the liquidity demand doesn't change. (<a name="0041-TSTK-003" href="#0041-TSTK-003">0041-TSTK-003</a>)
- Change of `market.stake.target.scalingFactor` will immediately change the scaling between liquidity demand estimate based on open interest and target stake, hence immediately change the target stake. (<a name="0041-TSTK-004" href="#0041-TSTK-004">0041-TSTK-004</a>)
- Change of `market.stake.target.timeWindow` will immediately change the length of time window over which open interest is measured, hence will immediately change the value of `max_oi`. (<a name="0041-TSTK-005" href="#0041-TSTK-005">0041-TSTK-005</a>)

## Target stake for spot markets

See [spot market spec](0080-SPOT-product_builtin_spot.md).3600s

The target stake of a market is calculated as a fraction of the maximum `total_stake` over a rolling time window. The fraction is controlled by the parameter `scaling_factor` and the length of the window is controlled by the parameter `time_window`.

```pseudo
e.g.

Given: the following total_stake values

    [time, total_stake] = [[17:59, 12000], [18:01, 11000], [18:30, 9000], [18:59, 10000]]

If: the time value and market parameters are

    current_time = 19:00

    time_window = 3600s
    target_stake_factor = 0.25

Then: the target stake value is

    target_stake = 0.25 * 11000 = 2750 DAI
```

The above design ensures the `target_stake` of a market is unable to fluctuate dramatically over the window. Controlling the `target_stake` impacts the `total_stake` as reducing the commitment beyond `maximum_reduction_amount` means the LPs will be charged a penalty for doing so.

### Acceptance criteria

Too be decided.
