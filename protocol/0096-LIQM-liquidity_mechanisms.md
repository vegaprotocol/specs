# On-Chain Liquidity Mechanisms

## Summary

The aim of the on-chain liquidity mechanisms are to reward parties for supplying competitively priced liquidity and facilitating the growth of a market. At a high level, the liquidity mechanisms are:

- parties [accrue](#accruing-els-points) ELS points over time proportional to their maker fees earned.
- parties are [designated](#designating-liquidity-providers) as LPs on an epoch by epoch basis if they receive above a specified proportion of the markets maker fees.
- parties [receive](#distributing-liquidity-fees) a proportion of the liquidity fees accumulated in an epoch relative to their [accrued](#accruing-els-points) ELS points and [volume of notional](#volume-of-notional) (but only when designated as an LP).

With the above mechanisms the protocol incentives the following desirable behaviour.

- **Early adoption** - parties accrue ELS points which never decay over time. Early adopters of a market will benefit from accrued ELS points for the entire duration of the markets life-cycle.
- **Tight spreads** - parties are incentivised to be at the front of the book as ELS points are only accrued when a party is the non-aggressive side of a trade.
- **Deep liquidity** - parties are incentivised to supply a larger volume of notional liquidity within a configurable range to receive a larger share of the liquidity fees.
- **Active market making** - parties who accumulate a large number of ELS points will still need to be designated as an LP in order to receive a proportion of the liquidity fees accumulated each epoch. Therefore parties are incentivised to continue to provide competitively priced liquidity even after accruing a large number of ELS points.

The mechanisms also enable the following features:

- **Key rotation** - ELS points are implemented as internal assets, as such they can be transferred between keys and traded.

## Network parameters

### `liquidityProvider.proportionRequirement`

A number in the range $[0, 1]$ which defines the minimum proportion of a markets maker fees a party must receive in order to be [designated](#designating-liquidity-providers) as an LP for the next epoch. The parameter should default to `0.1`.

Updates to this parameter will be used the next time LPs are designated, i.e. updating the network parameter will not result in LPs instantly being re-designated.

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

$$\frac{M_{i_j}}{\sum_{k}^{n}{M_{i_j}}} >= N$$

Where:

- $M_{i_j}$ is the maker fees of party ${j}$ in epoch ${i}$
- $N$ the requirement specified by the network parameter `liquidityProvider.proportionRequirement`

By designating parties as LPs on an epoch by epoch basis the protocol ensures:

- "in-active" parties with a large number of ELS points will no longer be rewarded through liquidity mechanisms should they stop providing liquidity (or provide un-competitive liquidity).
- "late-arriving" parties with a small number of ELS points will be rewarded through liquidity mechanisms if they provide competitive liquidity and as such comprise a larger proportion of the markets volume.

## Volume of Notional

The volume of notional is a measure of how much liquidity an LP provided to a market throughout the epoch.

Each LPs `volume of notional` is defined as, the maximum notional volume that they supplied through orders within a specified range for at least N % of the epoch.

The range and required proportion of the epoch are controlled though market configurable SLA parameters:

- `lp_price_range`: a number in the range $[0, 100]$ which defines the range in which an LPs orders will contribute towards their volume of notional, refer to section [instantaneous volume-of-notional](#instantaneous volume of notional) for more details.
- `minimum_time_fraction`: a number in the range $[0, 1]$ which defines the minimum proportion of an epoch an LP must have provided an amount of volume for in order for that amount to be set as their volume of notional, refer to section [calculating the volume of notional](#calculating-the-volume-of-notional) for more details.

### Instantaneous Volume of Notional

To calculate each LPs volume of notional, throughout the epoch, the network must sample and store the current volume of notional supplied by each LP at that point. Call this the instantaneous volume of notional. For now this is done once a block but could be sampled randomly to reduce the amount of data stored.

>[!NOTE]
> Whilst the SLA parameters are uniquely configurable per market, they can also be specified for a liquidity SLA reward metric. As such, for each LP, the network must also track the instantaneous volume of notional provided within each unique price range specified by a reward.

Calculating the notional volume supplied at any given point in time is done as follows:

Whilst in continuous trading:

- If there is no mid price each LP is treated as supplying `0` volume.

- If there is a mid price calculate the volume of notional that is in the range.

```text
(1.0-lp_price_range) x mid <= price levels <= (1+lp_price_range)x mid
```

Whilst in monitoring auctions:

- If there is an indicative uncrossing price calculate the volume of notional that is in the range.

```text
(1.0-lp_price_range) x min(last trade price, indicative uncrossing price) <=  price levels <= (1.0+lp_price_range) x max(last trade price, indicative uncrossing price)
```

- If there is no 'indicative uncrossing price' each LP is treated as supplying `0` volume.

### Calculating the Volume of Notional

At the end of the epoch, before distributing fees, each LPs `volume of notional` is set to the largest volume of notional that was supplied for at least a specified proportion of the epoch, i.e. in a sorted array of supplied liquidity amounts, the commitment amount would be element $i$ where:

$$i= \lceil\text{len(array)}\cdot{\text{minTimeFraction}}\rceil$$

## Distributing Liquidity Fees

At the end of epoch, after each party accrues ELS points for that epochs volume, the accumulated liquidity fees are distributed pro-rata amongst liquidity providers weighted by their accrued ELS points as follows.

$$f_{i_j} = f_{i} \cdot \frac{ELS_j\cdot{V_j}}{\sum_{k}^{n}{ELS_k\cdot{L_k}}}$$

Where:

- $f_{i_j}$ is the liquidity fees distributed to party $j$ in epoch $i$
- $f_{i}$ is the liquidity fees accumulated by the market in epoch $i$
- $ELS_j$ is the current number of ELS points for party $j$
- $V_j$ is the volume of notional of party $j$
