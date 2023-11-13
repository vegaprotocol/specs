# Floating-point consensus

## Summary

Any intermediate results originating from 3rd party-libraries relying on floating-point arithmetic that `vega` depends on need to be put through the consensus layer so that a common value to be used by all nodes can be agreed upon and represented as a `decimal` before any downstream calculations are carried out. The latency requirements of the system imply that such coordination cannot be carried out in a blocking manner, instead it must be scheduled periodically so that values are only updated once consensus requirements have been met. Furthermore, the system should be configured with default values for each such quantity to avoid the need for blocking synchronisation at initialisation time (currently creation of a new market).

## Background

Computations within a blockchain-based system [need to be deterministic](https://docs.tendermint.com/v0.34/introduction/what-is-tendermint.html#a-note-on-determinism) as otherwise application state between nodes replicating it can start to differ potentially leading to a consensus failure. This issue has been long known in a different type of a distributed system: [networked games](https://gafferongames.com/post/floating_point_determinism/).

The two strategies for dealing with the problem have been to either synchronise the entire game state across all agents or to assure that computations yield identical results irrespective of the platform they run on. While the first strategy might work for games with limited state size due to the use of a central server it cannot be applied to a peer-to-peer application like `vega` which relies on low latency. The second strategy is trivial to implement for `integer` or `decimal` data types, but while still possible, much [more complex](https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html) in case of `floating-point` datatypes as it usually involves rewriting a lot of the tooling and libraries that the application relies on.

While `vega` relies on `integer` and `decimal` data types the same cannot be easily achieved for the [`quant`](https://github.com/vegaprotocol/quant) library which is one of its main dependencies. Its reliance on numerical methods, majority of which use floating-point numbers, combined with the need for possibility of rapid addition of new features effectively rules out any attempts at assuring determinism. Any naive strategies like rounding of outputs aren't guaranteed to solve the problem, meaning that potentially critical consensus failure could arise at any time and it's identification and resolution would likely be very time consuming only to alleviate a single symptom of the problem with no additional guarantees on robustness of the system. Hence, a dedicated strategy guaranteeing determinism and low latency while not entirely precluding the use of floating-point numbers needs to be agreed.

## Floating-point consensus mechanism

The reasons outlined above imply that any intermediate computation results which rely on floating-point arithmetic need to be agreed upon by all the nodes and stored as decimals before they can be used for downstream calculations. The latency requirements mean that such synchronisation cannot be carried out on the fly and since such strategy implies treating certain variables as constants until the next update is carried out the mechanism needs to allow flexibility in specifying time- or state-change based events triggering an update for different quantities and to allow to specify fallback behaviour in case update cannot be carried out in time.
[This section](#current-floating-point-dependencies) lists intermediate floating-point results `vega` currently relies on, however it should be assumed that more may appear in the future, hence the implementation of this mechanism should allow to easily add new values to it and to easily retrieve them in various parts of the `vega` codebase.

We will call each such value a **"state variable"**. Currently state variables exist on market level, however in the future some of them could be moved to risk-universe level. State variable value nominated by a single node will be called a **"candidate value"**, whereas a state variable value that has successfully gone through the consensus mechanism and is to be used by each of the nodes will be called a **"consensus value"**.

Each state variable will be represented as a key-tolerance-value triple.
The key will be a `string`.
The tolerance will be a `decimal` which will be provided by the quant library producing this and must be *deterministic* (ie it is either hard coded in the library or produced without floating point arithmetic).
The value will be a single `floating-point`, this will be provided by the quant library as a result of some floating point calculation.
State variables will be bundled together by the event that triggered their update.

### Default values & initialisation

Each state variable must have a default value specified (can be hardcoded for now).

Default risk factors are to be `1.0` for futures (so until a value has been calculated and agreed all trades are over-collateralised) with a tolerance of `1e-6`.
Risk factor calculation should be triggered as soon as market is proposed.

Default probability of trading should be `100` ticks on either side of best bid and best ask with probability of trading for each one them equal to the default value of probability of trading between best bid and best ask as per [0034-PROB-prob_weighted_liquidity_measure](./0034-PROB-prob_weighted_liquidity_measure.ipynb). As soon as there is the auction uncrossing price in the opening auction an event should be triggered to calculate the probabilities of trading using the indicative uncrossing price as an input. Tolerance should be set to `1e-6`.

Default price monitoring bounds should be calculated (as a decimal point calculation directly in core) as `10%` on either side of the indicative uncrossing price and used as default. As soon as an indicative uncrossing price is available calculate the real bounds using the full risk model + consensus mechanism. Tolerance should be set to `1e-6`.

The market should *not* leave the opening auction if any of the the risk factors, probabilities of trading or price monitoring bounds haven't passed at least one round of resolution as this would indicate a badly specified market.

### Resolution strategy

Here we describe how the consensus value should be chosen from the candidates gathered from the nodes.

Each calculation will be triggered by the specified [event](#update-events). Each event will have a unique identifier (hash). Any candidate key-tolerance-value triples should be submitted along with that hash as part of a bundle.
We wait for 2/3 (rounded up) answers with matching identifier to be submitted.
If all candidate values for a given variable are equal to each other then just accept that value.
If all values in a bundle are accepted then the whole bundle is accepted and the values in core are updated with the appropriate decimal representations.

If at least one value differs then:

1) Emit an event announcing this (if there are many such events this indicates either an unstable risk calculation or malicious nodes).
1) A node is chosen at random with probability equal to tendermint weight to propose a bundle of values, submit as candidate and to be voted upon by other nodes. Each node should vote with their tendermint weight. A node will vote `yes` to the proposed bundle if all the values are within the prescribed tolerance and `no` otherwise.
The bundle is accepted if `(2/3)` of nodes by tendermint weight vote to accept the bundle.
If the bundle is rejected go back to selecting a node at random by tendermint weight and repeat.
This is repeated until a value has been accepted.
1) This may continue indefinitely. It will only be terminated when a new event arrives asking for a calculation with new inputs. If we got here emit an event announcing this (we either have a really badly unstable calculation or malicious nodes).
1) If update hasn't been achieved after `3` update events an appropriate event should be emitted to indicate that market is operating with stale state variables.

Note that the state variable calculation inputs need to be gathered when the event triggering the re-calculation has been announced (this is deterministic) so that all calculations are done with the same inputs for the same event.

### Update events

Implement the following state variable update events:

- market enactment,
- time-based trigger, governed by network parameter `network.floatingPointUpdates.delay` set by default to `5m` - for each market the clock should start ticking at the end of the opening auction and then be reset by any other update event following it
- opening auction sees uncrossing price for first time,
- auction (of any type) ending.

The following quantities should be recalculated by the associated triggers:

1) risk factors: market enactment
2) price monitoring bounds: all triggers except market enactment
3) probabilities of trading: all triggers except market enactment

## Current floating-point dependencies

This section outlines floating-point quantities `vega` currently relies on:

- [`CalculateRiskFactors(current *types.RiskResult) (bool, *types.RiskResult)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L24) - calculates risk factors (short and long), called each time time within the application is updated ([`OnChainTimeUpdate(...)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/execution/market.go#L624)) static for log-normal model.
- [`PriceRange(price, yearFraction, probability num.Decimal) (minPrice, maxPrice num.Decimal)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L25) - calculates risk minimum and maximum price at specified probability level and projection horizon given current price, called from [price monitoring engine](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/monitor/price/pricemonitoring.go#L80) each time bounds are updated.
- [`ProbabilityOfTrading(currentP, orderP *num.Uint, minP, maxP, yFrac num.Decimal, isBid, applyMinMax bool) num.Decimal`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L26) - calculates probability of trading at a specified projection horizon of the specified order given current price and min/max bracket, called from [supplied liquidity engine](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/liquidity/engine.go#L34) each time new liquidity provision orders are deployed.

## Acceptance criteria

1. Floating-point values get initialised and updated correctly (<a name="0065-FTCO-001" href="#0065-FTCO-001">0065-FTCO-001</a>). For product spot: (<a name="0065-FTCO-005" href="#0065-FTCO-005">0065-FTCO-005</a>)
    - A market is proposed and initially it has the following default values:
        - Risk factors:
            - Short: 1.0
            - Long: 1.0
        - Probability of trading: 0.005.
        - Price monitoring bounds:
            - Up: 10%,
            - Down: 10%.
    - Upon market enactment risk factors get calculated (their values change from defaults).
    - When the opening auction sees uncrossing price for the first time (there are two overlapping orders from buy and sell side on the order book) price monitoring bounds and probability of trading get calculated (their values change from defaults).
    - When the opening auction ends (choose uncrossing price that's different from first indicative uncrossing price) price monitoring bounds and probability of trading get recalculated.
    - When the market goes into price monitoring auction the state variables stay the same as prior to its' start, when that auction concludes (choose a price that's not been traded at before) price monitoring bounds and probability of trading get recalculated again and the time-based trigger countdown gets reset.
    - When the time-based trigger elapses price monitoring bounds and probability of trading get recalculated.

1. Event announcing diverging values gets emitted (<a name="0065-FTCO-004" href="#0065-FTCO-004">0065-FTCO-004</a>). For product spot: (<a name="0065-FTCO-006" href="#0065-FTCO-006">0065-FTCO-006</a>)
   - For all the state variables nodes submit candidate values that differ by up to half the tolerance.
   - The event announcing the fact that at least one of the values differed gets emitted.
   - Since differences are within tolerance the consensus successfully chooses a consensus value and systems keeps running as expected (market goes into continuous trading mode accepts orders and generates trades).

1. Consensus failure event gets emitted (<a name="0065-FTCO-002" href="#0065-FTCO-002">0065-FTCO-002</a>). For product spot: (<a name="0065-FTCO-007" href="#0065-FTCO-007">0065-FTCO-007</a>)
   - A market is proposed and initially has default values specified in the scenario above.
   - Upon market enactment risk factors get submitted by nodes, one of the nodes submits a value that is higher than tolerance.
   - An appropriate event is sent to signal that at least one of the values differed.
   - Consensus still works, value submitted by other nodes gets used.
   - Opening auction concludes, risk factor values submitted by all the nodes differ by more than tolerance between each other.
   - None of the values submitted by nodes get accepted, market is running with previously calculated risk factors.
   - Situation continues for 2 more risk factor update attempts (can be time-based or auction).
   - Market still runs with previously calculated risk factors, but an event informing that the market is using stale values gets emitted.

1. Market cannot leave opening auction with default values (<a name="0065-FTCO-003" href="#0065-FTCO-003">0065-FTCO-003</a>). For product spot: (<a name="0065-FTCO-008" href="#0065-FTCO-008">0065-FTCO-008</a>)
   - A market is proposed and initially has default values specified in the scenario above.
   - Upon market enactment risk factors get calculated (their values change from defaults).
   - When the opening auction sees uncrossing price for the first time (there are two overlapping orders from buy and sell side on the order book) price monitoring bounds get calculated, but probability of trading get doesn't pass consensus (all nodes submit conflicting values)
   - An appropriate event is sent to signal that at least one of the values differed.
   - Time-based trigger attempts another update, but that one doesn't succeed either.
   - The market never goes into continuous trading mode.
