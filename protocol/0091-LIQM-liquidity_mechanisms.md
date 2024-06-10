# On-Chain Liquidity Mechanisms

## Summary

The aim of the on-chain liquidity mechanisms are to reward parties for supplying competitively priced liquidity and facilitating the growth of a market. At a high level, the liquidity mechanisms are:

- parties [accrue](#accruing-els-points) ELS points over time proportional to their maker fees earned.
- parties are [designated](#designating-liquidity-providers) as LPs on an epoch by epoch basis if they receive above a specified proportion of the markets maker fees.
- parties [receive](#distributing-liquidity-fees) a proportion of the liquidity fees accumulated in an epoch relative to their accrued ELS points (but only when designated as an LP).

With the above mechanisms the protocol incentives the following desirable behaviour.

- **Early adoption** - parties accrue ELS points which never decay over time. Early adopters of a market will benefit from accrued ELS points for the entire duration of the markets life-cycle.
- **Tight spreads** - parties are incentivised to be at the front of the book as ELS points are only accrued when a party is the non-aggressive side of a trade.
- **Active market making** - parties who accumulate a large number of ELS points will still need to be designated as an LP in order to receive a proportion of the liquidity fees accumulated each epoch. Therefore parties are incentivised to continue to provide competitively priced liquidity even after accruing a large number of ELS points.

The mechanisms also enable the following features:

- **Key rotation** - ELS points are implemented as internal assets, as such they can be transferred between keys and traded.

## Network parameters

### `liquidityProvider.proportionRequirement`

A number in the range $[0, 1]$ which defines the minimum proportion of a markets maker fees a party must receive in order to be [designated](#designating-liquidity-providers) as an LP for the next epoch. The parameter should default to `0.1`.

Updates to this parameter will be used the next time LPs are designated, i.e. updating the network parameter will not result in LPs instantly being redesignated.

## Accruing ELS Points

Whenever a market proposal is enacted (passes opening auction), an internal Vega asset is created to track the ELS points of that market. For a successor market, a new asset should not be created and instead the ELS asset of the parent market should be used.

At the end of each epoch, each party accrues ELS points for the relevant market as follows:

$$ELS_{i_j} = V_{i_j} \cdot 10^{-Q}$$

Where:

- $ELS_{j}$ is the ELS points accrued by party $j$ in epoch $i$
- $V_{i_j}$ is the notional maker fees of party $j$ in epoch $i$
- $Q$ is the quantum of the asset in which the markets prices are expressed in (settlement for future and perpetual markets, quote for spot markets) 

> [!NOTE]
> the maker fees is scaled by the assets quantum such that 1 ELS point is earned for approx. every 1 USD of maker fees received.

## Designating Liquidity Providers

A party will only be able to receive liquidity fees or earn liquidity rewards providing they are designated as an LP for that epoch.

A party will only be designated as an LP providing they received more than a specified proportion of the markets total maker fees in the previous epoch, let this requirement be $N$ (the network parameter `liquidityProvider.proportionRequirement`). Throughout the epoch the network will track each parties maker fees, $M$.  At the end of epoch $i$, a party will be designated as an LP for epoch $i+1$ providing:

$$\frac{V_{i_j}}{\sum_{k}^{n}{M_{i_j}}} >= N$$

Where:

- $M_{i_j}$ is the maker fees of party ${j}$ in epoch ${i}$
- $N$ the requirement specified by the network parameter `liquidityProvider.proportionRequirement` 

By designating parties as LPs on an epoch by epoch basis the protocol ensures:

- "in-active" parties with a large number of ELS points will no longer be rewarded through liquidity mechanisms should they stop providing liquidity (or provide uncompetitive liquidity).
- "late-arriving" parties with a small number of ELS points will be rewarded through liquidity mechanisms if they provide competitive liquidity and as such comprise a larger proportion of the markets volume.

## Distributing Liquidity Fees

At the end of epoch, after each party accrues ELS points for that epochs volume, the accumulated liquidity fees are distributed pro-rata amongst liquidity providers weighted by their accrued ELS points as follows.

$$f_{i_j} = f_{i} \cdot \frac{ELS_{j}}{\sum_{k}^{n}{ELS_{k}}}$$

Where:

- $f_{i_j}$ is the liquidity fees distributed to party $j$ in epoch $i$
- $f_{i_j}$ is the liquidity fees accumulated by the market in epoch $i$
- $ELS_{j}$ is the current number of ELS points for party $j$
