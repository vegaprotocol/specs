# Floating-point consensus

## Summary

Any intermediate results originating from 3rd party-libraries relying on floating-point arithmetic that `vega` depends on need to be put through the consensus layer so that a common value to be used by all nodes can be agreed upon and represented as a `decimal` before any downstream calculations are carried out. The latency requirements of the system imply that such coordination cannot be carried out in a blocking manner, instead it must be scheduled periodically so that values are only updated once consensus requirements have been met. Furthermore, the system should be configured with default values for each such quantity to avoid the need for blocking synchronisation at initialisation time (currently creation of a new market).

## Background

Computations within a blockchain-based system [need to be deterministic](https://docs.tendermint.com/master/introduction/what-is-tendermint.html#a-note-on-determinism) as otherwise application state between nodes replicating it can start to differ potentially leading to a consensus failure. This issue has been long known in a different type of a distributed system: [networked games](https://gafferongames.com/post/floating_point_determinism/).

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

Default risk factors are to be `1.0` for futures (so until a value has been calculated and agreed all trades are over-collateralised).  
Risk factor calculation should be triggered as soon as market is proposed.

Default probability of trading should be `100` ticks on either side of best bid and best ask with `0.005` probability of trading each. As soon as there is the auction uncrossing price in the opening auction an event should be triggered to calculate the probabilities of trading using the indicative uncrossing price as an input.

Default price monitoring bounds should be calculated (as a decimal point calc directly in core) as `10%` on either side of the indicative uncrossing price and used as default. As soon as an indicative uncrossing price is available calculate the real bounds using the full risk model + consensus mechanism.

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

When we say a trigger should trigger calculation of all we currently mean: 
1) risk factors
2) price monitoring bounds
3) probabilities of trading
but as Vega evolves there may be more things.

Implement the following state variable update events:
- market enactment, this should trigger risk factor calculation. 
- time-based trigger, governed by network parameter `network.floatingPointUpdates.delay` set by default to `5m`. For each market the clock should start ticking at the end of the opening auction and then reset by any event that "recalculates all". This event should recalculate all.      
- opening auction sees uncrossing price for first time: probabilities of trading and price monitoring should be calculated.  
- auction (of any type) ending: probabilities of trading and price monitoring should be calculated.  

## Current floating-point dependencies

This section outlines floating-point quantities `vega` currently relies on:

- [`CalculateRiskFactors(current *types.RiskResult) (bool, *types.RiskResult)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L24) - calculates risk factors (short and long), called each time time within the application is updated ([`OnChainTimeUpdate(...)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/execution/market.go#L624)) static for log-normal model.
- [`PriceRange(price, yearFraction, probability num.Decimal) (minPrice, maxPrice num.Decimal)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L25) - calculates risk minimum and maximum price at specified probability level and projection horizon given current price, called from [price montiroing engine](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/monitor/price/pricemonitoring.go#L80) each time bounds are updated.
- [`ProbabilityOfTrading(currentP, orderP *num.Uint, minP, maxP, yFrac num.Decimal, isBid, applyMinMax bool) num.Decimal`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L26) - calculates probability of trading at a specified projection horizon of the specified order given current price and min/max bracket, called from [supplied liquidity engine](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/liquidity/engine.go#L34) each time new liquidity provision orders are deployed.
