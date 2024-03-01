# Composite prices

## Introduction

Prices are composed to create mark price and on perpetual futures markets a view of what the price on the vega side is for purposes of comparing to the underlying price and an eventual funding calculation.
Mark price is used by Vega protocol to calculate mark-to-market cashflows, feed the risk calculation, to provide ``unrealised'' profit-and-loss (PnL) information and drive price monitoring.

For perpetual futures markets there should be a composite *mark price* configuration and a composite *market price for funding* configuration so that the market can, potentially use different mark price for mark-to-market and price monitoring and completely different price for calculating funding.

Every market will have a mark price upon leaving opening auction.
This means that either (a) the proposed mark price methodology has produced a value during the opening auction or (b) if it has not, upon leaving the opening auction the first mark price is set to the auction uncrossing price regardless of the mark price methodology.
Subsequent updates will follow the set methodology.

## Proposed composite price methodology

We update the mark at the end of every mark price period and the funding price possibly at a different frequency (also set as network parameter specifying a period).
In the sequel both will be referred to as "mark price period".

### Price from observed trades

Existing network or market parameters that enter into this:

- Length of mark price period given by $\delta = $`network.markPriceUpdateMaximumFrequency`.

New market parameters that enter into this:

- $\alpha \in [0,1]$ decay weight.
- $p \in \mathbb N$ a decay power and in practice we'd want to support only $p \in \{1,2,3\}$.

Calculate $\hat P^{\text{trades}}$ which is simply trade-size-weighted average of all eligible trades over the mark price period.
Let $P_s$ to be price at time $s$ and $w_s$ the weight set as the volume traded at the price at time $s$.
Let $\delta > 0$ be the mark price period length.
Let $\alpha \geq 0$ decay weight and $p\in \mathbb N$ a decay power.
With this define
$$
K(s,t) = 1 - \alpha\frac{(t-s)^p}{\delta^p}\,.
$$
and
$$
W(t-\delta, t) := \int_{(t-\delta) \vee 0}^t K(s,t) w_s\, ds
$$
so that finally
$$
\hat P_t := \frac{1}{W(t-\delta, t)} \int_{(t-\delta) \vee 0}^t K(s,t) w_s \,P_s \,ds\,.
$$
As a sanity check note that if $P_s = P$ for all $s\in (t-\delta, t]$ we get
$$
\hat P_t := \frac{P}{W(t-\delta, t)} \int_{(t-\delta) \vee 0}^t K(s,t) w_s \,ds = P\,.
$$

### Price observed from the order book

Existing network or market parameters or calculation outputs that enter into this:

- $f_\text{initial scaling}$ is the `initial\_margin` in `market.margin.scalingFactors`.
- $f_\text{slippage}$ is the linear slippage factor in market proposal.
- $f_\text{risk}$ refers to either the long or short risk factors output by the risk model.

New market parameters that enter into this:

- Let $C$ be some cash amount e.g. $500$ USDT would be entered as $500 00000$ respecting the $5$ asset decimals.

Let $C$ be some cash amount e.g. $500$ USDT.
Calculate how much this can be leveraged to $N = C\frac{1}{f_{\text{risk}} + f_{\text{slippage}}} \frac{1}{f_{\text{initial scaling}}}$ i.e. you multiply $C$ by the maximum possible leverage.
For sell side calculate $V_{\text{sell}} = \frac{N}{P_{\text{best ask}}}$ where you set $f_{\text{risk}}$ to be the one for long.
For buy side calculate $V_{\text{buy}} = \frac{N}{P_{\text{best bid}}}$ where you set $f_{\text{risk}}$ to be the one for short.
Calculate $\hat P^{\text{book}}$ which is the time average ``mid'' price seen on the book: if there is at least volume $V_{\text{sell}}$ on the sell side and at least $V_{\text{buy}}$ on the buy side:
$$
P^{\text{book}}_s :=
\frac12 \left(\text{sell vwap for volume $V_{\text{sell}}$}+\text{buy vwap for volume $V_{\text{buy}}$}\right)\,,
$$
if not, don't include it in the time average.
If $C$ (the initial cash amount to consider) is set to $0$ then it's the usual mid price.
During auctions $P^{\text{book}}_s$ is set to the indicative uncrossing price.

### Prices observed from data sourcing framework (oracles)

New market parameters that enter into this:

- Entire oracle definition for each of the data sources, in particular source and update freq / schedule.

Obtain $(P^{\text{oracle}}_i)_{i=1}^n$ if $n \in \{0\}\cup \mathbb N$ oracle sources are defined.

### Median of observations

Set $L^{i}=L^{i}(s)$, $i=1,\ldots,n+2$ to be the functions which reports when a given price source from the list above was last updated and $(\delta_i)_{i=1}^d$ values defining when a given price is too old.
If for all $t-L_i(t) > \delta_i$ then all sources are stale and we do not update this source. 
If at least for one $i$ we have $t-L_i(t) < \delta_i$ we do
$$
M((P_i)_{i=1}^{2+n}) = \text{median}(\{P_i : t-L_i(t) < \delta_i\}) \,.
$$
The median is calculated as follows: sort the prices in ascending or descending order. If $n$ is an odd number then choose the value that's in the middle of the sorted list.
If you have even number add the two in the middle up and divide by $2$.
The median price source value should update whenever any of its input price sources have been updated or whenever time has passed and a previously current source has gone stale.
The median price source will have update time set to the latest time any of the input sources were updated (it will not be set to the time when it was last recalculated just because an input has gone stale).

### Composing with weighted average

New market parameters that enter into this:

- $(w_i)_{i=1}^{3+n}$ weights.
- $(\delta_i)_{i=1}^d$ specifying how old a source update can be before source is considered stale. If set to $0$ we'd want an update with the same vega time.

We allow weights: take $(w_i)_{i=1}^{3+n}$. This allows in particular picking individual sources.
We also set $L^{i}=L^{i}(s)$, $i=1,\ldots,n+3$ be the functions which reports when a given price was last updated and $(\delta_i)_{i=1}^d$ values defining when a given price is too old.
From this we update the weights as follows:
$$
\hat w^i := \frac{w_i \mathbf{1}_{t-L^i(t)<\delta^i}}{\sum_j w_j\mathbf{1}_{t-L^j(t)<\delta^j}}\,.
$$
I.e. we pick those that have been updated recently enough and we re-weight.
$$
M((P_i)_{i=1}^{3+n}) = \sum_{i=1}^{n+3} \hat w^i P_i \,.
$$

### Composing with median

New market parameters that enter into this:

- $(\delta_i)_{i=1}^d$ specifying how old a source update can be before source is considered stale. If set to $0$ we'd want an update with the same vega time.

Set $L^{i}=L^{i}(s)$, $i=1,\ldots,n+3$ to be the functions which reports when a given price was last updated and $(\delta_i)_{i=1}^d$ values defining when a given price is too old.
If for all $t-L_i(t) > \delta_i$ then all sources are stale and we do not update the mark price.
If at least for one $i$ we have $t-L_i(t) < \delta_i$ we do
$$
M((P_i)_{i=1}^{3+n}) = \text{median}(\{P_i : t-L_i(t) < \delta_i\}) \,.
$$
I.e. we do a median of the non-stale prices.
