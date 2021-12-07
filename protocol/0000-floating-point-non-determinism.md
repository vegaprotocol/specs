# Floating-point (non-)determinism

## Summary

Any intermediate results originating from 3rd party-libraries relying on floating-point arithmetic that `vega` depends on need to be put through the consensus layer so that a common value to be used by all nodes can be agreed upon and represented as a `decimal` before any downstream calculations are carried out. The latency requirements of the system imply that such coordination cannot be carried out in a blocking manner, instead it must be scheduled periodically so that values are only updated once consensus requirements have been met. Furthermore, the system should be configured with default values for each such quantity to avoid the need for blocking synchronisation at initialisation time (currently creation of a new market).

## Background

Computations within a blockchain-based system [need to be deterministic](https://docs.tendermint.com/master/introduction/what-is-tendermint.html#a-note-on-determinism) as otherwise application state between nodes replicating it can start to differ potentially leading to a consensus failure. This issue has been long known in a different type of a distributed system: [networked games](https://gafferongames.com/post/floating_point_determinism/).

The two strategies for dealing with the problem have been to either synchronise the entire game state across all agents or to assure that computations yield identical results irrespective of the platform they run on. While the first strategy might work for games with limited state size due to the use of a central server it cannot be applied to a peer-to-peer application like `vega` which relies on low latency. The second strategy is trivial to implement for `integer` or `decimal` data types, but while still possible, much [more complex](https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html) in case of `floating-point` datatypes as it usually involves rewriting a lot of the tooling and libraries that the application relies on.

While `vega` relies on `integer` and `decimal` data types the same cannot be easily achieved for the [`quant`](https://github.com/vegaprotocol/quant) library which is one of its main dependencies. Its reliance on numerical methods, majority of which use floating-point numbers, combined with the need for possibility of rapid addition of new features effectively rules out any attempts at assuring determinism. Any naive strategies like rounding of outputs aren't guaranteed to solve the problem, meaning that potentially critical consensus failure could arise at any time and it's identification and resolution would likely be very time consuming only to alleviate a single symptom of the problem with no additional guarantees on robustness of the system. Hence, a dedicated strategy guaranteeing determinism and low latency while not entirely precluding the use of floating-point numbers needs to be agreed.

## Floating-point consensus mechanism

The reasons outlined above imply that any intermediate computation results which rely on floating-point arithmetic need to be agreed upon by all the nodes and stored as decimals before they can be used for downstream calculations. The latency requirements mean that such synchronisation cannot be carried out on the fly and since such strategy implies treating certain variables as constants until the next update is carried out the mechanism needs to allow flexibility in specifying time- or state-change based events triggering an update for different quantities and to allow to specify fallback behaviour in case update cannot be carried out in time.
[This section](#current-floating-point-dependencies) lists intermediate floating-point results `vega` currently relies on, however it should be assumed that more may appear in the future, hence the implementation of this mechanism should allow to easily add new values to it and to easily retrieve them in various parts of the `vega` codebase.

We will call each such value a **"state variable"**. Currently state variables exist on market level, however in the future some of them could be moved to risk-universe level. State variable value nominated by a single node will be called a **"candidate value"**, whereas a state variable value that has successfully gone through the consensus mechanism and is to be used by each of the nodes will be called a **"consensus value".**

### Types of state variables

Each state variable will be represented as a key-value pair where key will be a `string` and value will either be a single `floating-point` value (scalar) or an array of integer-labelled `floats` (vector). It must be possible to bundle together any number of state variable of any of those types. Each bundle should share:

- [resolution strategy](#resolution-strategy)
- [update strategy](#update-strategy)
- [retirement strategy](#retirement-strategy).

TODO: Do we need to deal with differing integer-labels in vector candidate variables or can we assure they are always constructed in the same way?

### Default values & initialisation

Each state variable must have a default value specified (TODO: Should we have both market and network level default values?). Furthermore, each node should send it's state variable candidate as soon as possible (e.g. at market initialisation) so that defaults can be replaced with consensus values as soon as possible.

### Resolution strategy

It must be possible to prescribe to each bundle of state variables how the consensus value should be chosen from the candidates gathered from the nodes. We should support:

- median,
- average.

It is important to apply the same strategy to all state variables that form a bundle as there may be certain relationships that they need to maintain (e.g. their sum needs to be 1). Furthermore, it should be possible to specify the **quorum** - a minimum number of candidate values from which a new consensus value can be chosen. If quorum is not met the current value should be left as is without updating.

### Update strategy

Update strategy consists of:

- `update trigger` -  either time-based (once every `updateFrequency` seconds, `updateFrequency` of `0` should be interpreted as state variable only being updated at [initialisation](#default-values-initialisation)) or time and state-change based (e.g. `markPrice` changed by more than 10% over last hour) TODO: Mabybe we can just make it event based and recycle price monitoring bound breach somehow (note breach doesn't imply the price will actually change) 
- `polling time` (TODO: better name?) - period of time expressed in seconds from `update trigger` during which candidate values can be submitted (to avoid using stale values), it should always be less than `update frequency` (TODO: doesn't really have to be, just thought it will make things easier).

Please note that the first update (from default value to first consensus value) should be attempted at initialisation (e.g. market creation). Once an update attempt is finished any candidate variables that have been received should be cleared to avoid mixing stale and more up-to-date candidate values of the same variable. (TODO: DO WE NEED TO CONSIDER MULTIPLE CANDIDATES? DO WE NEED TO CONSIDER TIMESTAMPS IN CASE THINGS START GETTING OUT OF WHACK?) The last time a state variable was successfully updated must be recorded so that retirement strategies can work.

### Retirement strategy

Retirement strategy consists of:

- retirement age - period of time in seconds since last update beyond which a state variable is considered stale,
- **retirement action** to be carried out once a state variable is marked as stale.

Following actions must be implemented:

- null: leave the lastest value,
- revert to default: revert back to default value (TODO: market or network if we have both??)

Note every time a state variable is marked a stale an appropriate event should be emitted. Marking a variable as stale should NOT stop further update attempts in the future.

## Current floating-point dependencies

TODO: Not sure if we need to leave this section in, but should be useful as we write the spec

This section outlines floating-point quantities `vega` currently relies on:

- [`CalculateRiskFactors(current *types.RiskResult) (bool, *types.RiskResult)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L24) - calculates risk factors (short and long), called each time time within the application is updated ([`OnChainTimeUpdate(...)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/execution/market.go#L624)) static for log-normal model.
- [`PriceRange(price, yearFraction, probability num.Decimal) (minPrice, maxPrice num.Decimal)`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L25) - calculates risk minimum and maximum price at specified probability level and projection horizon given current price, called from [price montiroing engine](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/monitor/price/pricemonitoring.go#L80) each time bounds are updated.
- [`ProbabilityOfTrading(currentP, orderP *num.Uint, minP, maxP, yFrac num.Decimal, isBid, applyMinMax bool) num.Decimal`](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/risk/model.go#L26) - calculates probability of trading at a specified projection horizon of the specified order given current price and min/max bracket, called from [supplied liquidity engine](https://github.com/vegaprotocol/vega/blob/4be994751b0012b0904e37ad2b0d1540d24abb5e/liquidity/engine.go#L34) each time new liquidity provision orders are deployed.
