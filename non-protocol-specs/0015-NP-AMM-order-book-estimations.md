
# AMM Order Book Levels Estimator

Whilst generating a limit order book shape, i.e. the prices and associated volumes available at each price, is trivially achievable by simply aggregating the various component limit orders, this is harder to achieve for the active AMMs on a market. This is due to the fact that the volumes at which they would trade each price level within their range is not immediately obtainable without some calculations. Whilst these calculations are not heavy, and are routinely performed as part of trading, expanding out the entire range of an AMM with a large range may be prohibitive both in time taken (when updating frequently) and also in storage space, as there may be a non-zero volume at every possible tick level over a large range, necessitating a large array in which to store it.

In order to alleviate these issues, a heuristic should be used to govern how these AMMs are expanded out into levels for display, both in terms of how frequently these levels are updated and how far away from the mid price levels are calculated at each price level vs a larger gap. This spec aims to codify that heuristic.

## Update Frequency

The largest improvement to processing requirements from update frequency heuristics comes from the fact that an AMM will only update it's price levels when it is either amended or someone trades with it. Therefore the calculations generating a curve of volumes from AMM prices should be cached between these points and only updated when an AMM is amended or when a trade with an AMM occurs. This can be further improved if all curves from individual AMMs are stored separately alongside an aggregate volume in which case only the impacted AMM curve can be updated whilst all others remain static.

## Update Depth

The second consideration is the depth to which markets should be expanded at every individual price level, and what should be done after this point. As this information is purely used for informational purposes these options can be set (including some sensible defaults) at a per-datanode level rather than mandating a single set across the network. These values should be applicable across markets, so are defined in percentage terms:

  1. **amm_full_expansion_percentage**: This is the percentage difference above and below the market mid price to which the AMMs should be fully expanded at each price level.
  1. **amm_estimate_step_percentage**: Once above (or below) these bounds the calculation should only occur at larger steps. These step sizes are governed in percentage terms again (and are in reference to a percentage of the mid price).
  1. **amm_max_estimated_steps**: The maximum number of estimated steps to return. Once this number have been calculated nothing further is returned.

The calculation of the order book shape should combine these three values by using the `volume to trade between two price levels` calculations utilised by the core engine to iteratively calculate the volume quoted by a given AMM at each price level outwards from the center. (Note that AMMs which were outside of range at the intial mid price may come into range during the iteration and should be included if so.) Once the percentage full expansion bounds have been reached the gaps between prices become those specified by the step percentage value, however the calculation remains the same beyond that.