# Liquidity provision mechanics

The point of liquidity provision on Vega is to incentivise people to place orders on the market that maintain liquidity on the book.
This is done via a financial commitment and reward + penalty mechanics, and through the LP commitment transaction that announces that a party is entering the liquidity provision (LP) service level agreement (SLA).


Important note on wording:

- liquidity provision / liquidity COMMITMENTs are the amount of stake a liquidity provider places as a bond on the market to earn rewards.
- the COMMITMENT is converted via a multiplicative network parameter `market.liquidity.stakeToCcyVolume` to a liquidity OBLIGATION, measured in price level x volume i.e. settlement currency of the market.

## Network and market parameters

### Network parameters

- `market.liquidity.bondPenaltyParameter` - used to calculate the penalty to liquidity providers when they fail to support their open position through sufficient `general+margin` balance.
Valid values: any decimal number `>= 0` with a default value of `0.1`.
- `market.liquidity.sla.nonPerformanceBondPenaltySlope` - used to calculate how much is the LP bond slashed if they fail to reach the minimum SLA. Valid values: any decimal number `>= 0` with a default value of `2.0`.
- `market.liquidity.sla.nonPerformanceBondPenaltyMax` - used to calculate how much is the LP bond slashed if they fail to reach the minimum SLA. Valid values: any decimal number `>= 0` and `<=1.0` with a default value of `0.5`.
- `market.liquidity.maximumLiquidityFeeFactorLevel` - used in validating fee amounts that are submitted as part of the LP commitment transaction. Note that a value of `0.05 = 5%`. Valid values are: any decimal number `>=0` and `<=1`. Default value `1`.
- `market.liquidity.stakeToCcyVolume` - used to translate a commitment to an obligation. Any decimal number `>0` with default value `1.0`.
- `validators.epoch.length` - LP rewards from liquidity fees are paid out once per epoch according to whether they met the "SLA" (implied by `market.liquidity.commitmentMinTimeFraction`) and their previous performance (for the last n epochs defined by `market.liquidity.performanceHysteresisEpochs`), see [epoch spec](./0050-EPOC-epochs.md).
- `market.liquidity.earlyExitPenalty` (decimal ≥0), sets how much LP forfeits of their bond in case the market is below target stake and they wish to reduce their commitment. If set to `0` there is no penalty for early exit, if set to `1` their entire bond is forfeited if they exit their entire commitment, if set >1, their entire bond will be forfeited for exiting `1/earlyExitPenalty` of their commitment amount.
- `market.liquidity.probabilityOfTrading.tau.scaling` sets how the probability of trading is calculated from the risk model; this is used to [measure the relative competitiveness of LPs supplied volume](0042-LIQF-setting_fees_and_rewarding_lps.md).
- `market.liquidity.minimum.probabilityOfTrading.lpOrders` sets a lower bound on the result of the probability of trading calculation.
- `market.liquidity.feeCalculationTimeStep` (time period e.g. `1m`) controls how often the quality of liquidity supplied by the LPs is evaluated and fees arising from that period are earmarked for specific parties. Minimum valid value `0`. Maximum valid value `validators.epoch.length`.

### Market parameters

All market parameters can be set / modified as part of [market proposal](0028-GOVE-governance.md) / market change proposal and the new value take effect at the first new epoch after enactment.

- `market.liquidity.priceRange` (decimal) - this is a percentage price move (e.g. `0.05 = 5%`) from `mid_price` during continuous trading or indicative uncrossing price during auctions.

- `market.liquidity.commitmentMinTimeFraction` (decimal) —  minimum fraction of time LPs must spend "on the book" providing their committed liquidity. This is a decimal number in the interval $[0,1]$ i.e. both limits included. When set to $0$ the SLA mechanics are switched off for the market entirely.

- `market.liquidity.performanceHysteresisEpochs` (uint) - number of liquidity epochs over which past performance will continue to affect rewards.

- `market.liquidity.slaCompetitionFactor` - the maximum fraction of their accrued fees an LP that meets the SLA implied by `market.liquidity.commitmentMinTimeFraction` will lose to LPs that achieved a higher SLA performance than them.

For LP reward calculations based on the SLA see the [0042-LIQF spec](./0042-LIQF-setting_fees_and_rewarding_lps.md).


## Mechanism overview

At a high level, the liquidity mechanism in Vega allows Liquidity Providers (LPs) to commit liquidity to a market and "bid" to set the liquidity fee on the market. LPs that meet this commitment are rewarded from the fee revenue. This is done by:

- Requiring LPs to meet an SLA (i.e. % of time spent providing liquidity within the defined range) in order to be rewarded.

- Rewarding LPs more for better performance against the SLA vs other LPs, ensuring there is an incentive to do more than the bare minimum and more than other LPs, if market conditions allow.

- Penalising LPs that commit and do not meet the SLA, to reduce the attractiveness of opportunistically going after rewards with no intention to meet the SLA in more challenging conditions, and of leeching style attacks on the rewards.

Once committed LPs attempt to meet their commitment by placing and maintaining normal orders on the market. They may use pegged or priced limit orders, along with features like post only and iceberg (or more accurately, transparent iceberg) to control their risk. Non-persistent orders, parked pegged orders, and stop-loss orders do not count towards an LP's supplied liquidity and therefore cannot be used to meet the SLA.


## Commit liquidity network transaction

Any Vega participant can apply to become a liquidity provider (LP) on a market by submitting a transaction to the network which includes the following

1. Market ID
1. COMMITMENT AMOUNT: liquidity commitment amount (specified as a unitless number that represents the amount of settlement asset of the market)
1. FEES: nominated [liquidity fee factor](./0029-FEES-fees.md), which is an input to the calculation of taker fees on the market, as per [setting fees and rewarding lps](./0042-LIQF-setting_fees_and_rewarding_lps.md)

Accepted if all of the following are true:

- The transaction is valid: the submitting party has sufficient collateral in their general account to meet the size of their nominated commitment amount.
- The market is in a state that accepts new liquidity provision [market lifecycle spec](./0043-MKTL-market_lifecycle.md).


## Commitment amount

### Processing the commitment

When a commitment is made the liquidity commitment amount is assumed to be specified in terms of the settlement currency of the market.
There is an minimum LP stake which is `market.liquidityProvision.minLpStakeQuantumMultiple x quantum` where `quantum` is specified per asset, see [asset framework spec](./0040-ASSF-asset_framework.md).

If the participant has sufficient collateral to cover their commitment, the commitment amount (stake) is transferred from the participant's general account to their (maybe newly created) [liquidity provision bond account](./0013-ACCT-accounts.md#liquidity-provider-bond-accounts) (new account type, 1 per liquidity provider per market and asset where they are committing liquidity, created as needed).
For clarity, liquidity providers will have a separate [margin account](./0013-ACCT-accounts.md#trader-margin-accounts) and [bond account](./0013-ACCT-accounts.md#liquidity-provider-bond-accounts).

A new or increased commitment will get activated in two stages.(*) First the commitment amount (increase) will get transferred from general to bond account.
Their obligation for providing liquidity under SLA is determined by their commitment from the beginning of the current epoch (so, in particular, for a new LP, it's 0).
Second, at the beginning of the next epoch (after the rewards/penalties for present LPs have been evaluated), the commitment amount is noted, and the LP is expected to provide sufficient liquidity for the epoch.

(*) The exception is the end of the opening auction of the market. The LPs that submit a commitment during the opening auction become the market LPs as soon as the opening auction ends.

The fee for the market is only [updated at the epoch boundary using the "auction" mechanism set here](0042-LIQF-setting_fees_and_rewarding_lps.md).

Liquidity provider bond account:

- Each active market has one bond account per liquidity provider, per settlement asset for that market.
- When a liquidity provider transaction is approved, the size of their staked bond is immediately transferred from their general account to this bond account.
- A liquidity provider can only prompt a transfer of funds to or from this account by (re)submitting the LP commitment  transaction: a valid transaction to create, increase, or decrease their commitment to the market.
  - Transfers to/from this account also occur when it is used for settlement or margin shortfall, when penalties are applied, and if the account is under-collateralised because of these uses and is subsequently topped up to the commitment amount during collateral search (see below)
- Collateral withdrawn from this account may only be transferred to either:
  - The insurance pool of the market for markets trading on margin or the network treasury for the asset (for spot markets) (in event of penalties/slashing)
  - The liquidity provider's margin account or the network's settlement account/other participant's margin accounts (during a margin search and mark to market settlement) in the event that they have zero balance in their general account.
  - The liquidity provider's general account (in event of liquidity provider reducing their commitment)

### Liquidity provider proposes to amend commitment amount

The commitment transaction is also used to amend any aspect of their liquidity provision obligations.
A participant may apply to amend their commitment amount by submitting a transaction for the market with a revised commitment amount.

`proposed-commitment-variation = new-proposed-commitment-amount - old-commitment-amount`

An increase in amendment is actioned immediately but only has implications for rewards / penalties at start of the next epoch.

1) the amount is immediately transferred from the party's general account to their bond account. However we keep track of commitment at start of epoch and this is used for penalties / rewards.
2) at the beginning of the next epoch, the rewards / penalties for present LPs - including the party that's amending - are evaluated based on balance of bond account at start of epoch.

A decrease in commitment is noted but the transfer out of the bond account is only actioned at the end of the current epoch.

For each party only the most recent amendment should be considered. All the amendments get processed simultaneously, hence the relative arrival of amendments made by different LPs within the previous epoch is irrelevant (as far as commitment reduction is concerned, it still has implications for other aspects of the mechanism).

#### Increasing commitment

_Case:_ `proposed-commitment-variation >= 0`

A liquidity provider can always increase their commitment amount as long as they have sufficient collateral in the settlement asset of the market to meet the new commitment amount.

If they do not have sufficient collateral the transaction is rejected in entirety. This means that any change in fee bid is not applied and that the `old-commitment-amount` is retained.

#### Decreasing commitment

_Case:_ `proposed-commitment-variation < 0`

At the beginning of each epoch, calculate actual commitment variation for each LP wishing to reduce their commitment as:

$$
\text{commitment-variation}_i=\min(-\text{proposed-commitment-variation}_i, \text{bond account balance}_i).
$$

Next, calculate how much the overall commitment within the market can be decreased by without incurring a penalty.
To do this we first evaluate the maximum amount that the `total_stake` can reduce by without penalty given the current liquidity demand in the market.

`maximum-penalty-free-reduction-amount = max(0,total_stake - target_stake)`

where:

- `total_stake` is the sum of all stake of all liquidity providers bonded to this market including the amendments with positive commitment variation submitted in the previous epoch.
- `target_stake` is a measure of the market's current stake requirements, as per the calculation in the [target stake](./0041-TSTK-target_stake.md).

Then, for each $LP_i$ we calculate the pro rata penalty-free reduction amount:

```math
\text{maximum-penalty-free-reduction-amount}_i=\frac{\text{commitment-variation}_i}{\sum_{j}\text{commitment-variation}_j} \cdot \text{maximum-penalty-free-reduction-amount}.
```

If $\text{commitment-variation}_i <= \text{maximum-penalty-free-reduction-amount}_i$ then we're done, the LP reduced commitment, the entire amount by which they decreased their commitment is transferred to their general account, their ELS got updated as per the [ELS calculation](0042-LIQF-setting_fees_and_rewarding_lps.md).

If  $\text{commitment-variation}_i > \text{maximum-penalty-free-reduction-amount}_i$ then first establish

$$
\text{penalty-incurring-reduction-amount}_i = \text{commitment-variation}_i - \text{maximum-penalty-free-reduction-amount}_i
$$

Transfer $\text{maximum-penalty-free-reduction-amount}_i$ to their general account.

Now transfer $(1-\text{market.liquidity.earlyExitPenalty}) \cdot \text{penalty-incurring-reduction-amount}_i$ to their general account and transfer $\text{market.liquidity.earlyExitPenalty} \cdot  \text{penalty-incurring-reduction-amount}_i$ to the market insurance pool.
Note that in the case of spot market or any market that isn't running an insurance pool the transfer should go into the network treasury for the asset.

Finally update the ELS as per the [ELS calculation](0042-LIQF-setting_fees_and_rewarding_lps.md) using the entire $\text{commitment-variation}_i$ as the `delta`.

Note that as a consequence the market may land in a liquidity auction the next time conditions for liquidity auctions are evaluated (but there is no need to tie the event of LP(s) reducing their commitment to an immediate liquidity auction evaluation).

## Fees

### Nominating and amending fee amounts

The network transaction is used by liquidity providers to nominate a fee amount which is used by the network to calculate the [liquidity_fee](./0042-LIQF-setting_fees_and_rewarding_lps.md) of the market. Liquidity providers may amend their nominated fee amount by submitting a liquidity provider transaction to the network with a new fee amount. If the fee amount is valid, this new amount is used. Otherwise, the entire transaction is considered invalid.

### How fee amounts are used

The [liquidity_fee](./0029-FEES-fees.md) of a market on Vega takes as an input, a [`fee factor[liquidity]`](./0029-FEES-fees.md) which is calculated by the network, taking as an input the data submitted by the liquidity providers in their liquidity provision network transactions (see [this spec](./0042-LIQF-setting_fees_and_rewarding_lps.md) for more information on the specific calculation).

### Distributing fees between liquidity providers

When calculating fees for a trade, the size of a liquidity provider’s commitment at the start of the epoch along with when they committed and the market size are inputs that will be used to calculate how the liquidity fee is distributed between liquidity providers. See [setting fees and rewarding lps](./0042-LIQF-setting_fees_and_rewarding_lps.md) for the calculation of the split.


## Liquidity provision and penalties

### Calculating liquidity from commitment

Committed Liquidity Providers are required to provide a multiple of their stake, at the start of the epoch, (supplied in the settlement currency of the market) in notional volume of orders within the range defined below on both sides of the order book.

The multiple is controlled by a network parameter `market.liquidity.stakeToCcyVolume`:

```text
liquidity_required = stake_amount ✖️ market.liquidity.stakeToCcyVolume
```

### Meeting the committed volume of notional

#### During continuous trading

If there is no mid price then no LP is meeting their committed volume of notional.
If there is mid price then we calculate the volume of notional that is in the range

```text
(1.0-market.liquidity.priceRange) x mid <= price levels <= (1+market.liquidity.priceRange)x mid.
```

If this is greater than or equal to `liquidity_required` then the LP is meeting the committed volume of notional.

#### During auctions

We calculate the volume of notional that is in the range

```text
(1.0-market.liquidity.priceRange) x min(last trade price, indicative uncrossing price) <=  price levels <= (1.0+market.liquidity.priceRange) x max(last trade price, indicative uncrossing price).
```

If this is greater than or equal to `liquidity_required` then the LP is meeting the committed volume of notional.


Note: we don't evaluate whether LPs meet the SLA during opening auctions so there will always be a mark price.


### Penalty for not meeting the SLA

See the [Calculating the SLA performance penalty for a single epoch section in 0042-LIQF](./0042-LIQF-setting_fees_and_rewarding_lps.md) for how `fraction_of_time_on_book` is calculated.
This is available at the end of each epoch.
If, at the end of the epoch, `fraction_of_time_on_book >= market.liquidity.commitmentMinTimeFraction` then let $f=0$.
Otherwise we calculate a penalty to be applied to the bond as follows.

Let $t$ be `fraction_of_time_on_book`

Let $s$ be `market.liquidity.commitmentMinTimeFraction`.

Let $p$ be `market.liquidity.sla.nonPerformanceBondPenaltySlope`.

Let $m$ be `market.liquidity.sla.nonPerformanceBondPenaltyMax`.

Let

$$
f = \max\left[0,\min\left(m, p \cdot (1 - \frac{t}{s})\right)\right]\,.
$$

Once you have $f$ transfer $f \times B$ into the insurance pool of the market, where $B$ is the LP bond account balance.
For spot markets, the transfer is to go into the network treasury account for the asset.
Moreover, as this reduced the LP stake, update the ELS as per [Calculating liquidity provider equity-like share section in 0042-LIQF](./0042-LIQF-setting_fees_and_rewarding_lps.md).

In the case of spot markets the transfer goes into the network treasury account for the asset.

### Penalty for not supporting open positions

If at any point in time, a liquidity provider has insufficient capital to make the transfers for their mark to market or other settlement movements, and/or margin requirements arising from their orders and open positions, the network will utilise their liquidity provision commitment, held in the _liquidity provider bond account_ to cover the shortfall.
The protocol will also apply a penalty proportional to the size of the shortfall, which will be transferred to the market's insurance pool.

Calculating the penalty:

`bondPenalty = market.liquidity.bondPenaltyParameter ⨉ shortfall`

The above simple formula defines the amount by which the bond account will be 'slashed', where:

- `market.liquidity.bondPenaltyParameter` is a network parameter
- `shortfall` refers to the absolute value of the funds that the liquidity provider was unable to cover through their margin and general accounts, that are needed for settlement (mark to market or [product](./0051-PROD-product.md) driven) or to meet their margin requirements.

_Auctions:_ if this occurs at the transition from auction mode to continuous trading, the `market.liquidity.bondPenaltyParameter` will not be applied / will always be set to zero.

The network will:

1. _As part of the normal collateral "search" process:_ Access first the liquidity provider's bond account to make up the shortfall. If there is insufficient funds to cover this amount, the full balance of both bond accounts will be used. Note that this means that the transfer request should include the liquidity provider's bond account in the list of accounts to search, and that these accounts would always be emptied before any insurance pool funds are used or loss socialisation occurs.

1. _If there was a shortfall and the bond account was accessed:_ Transfer an amount equal to the `market.liquidity.bondPenaltyParameter` calculated above from the liquidity provider's bond account to the market's insurance pool. If there are insufficient funds in the bond account and the bond account, the full amount will be used and the remainder of the penalty (or as much as possible) should be transferred from the liquidity provider's margin account.

1. Initiate closeout of the LPs order and/or positions as normal if their margin does not meet the minimum maintenance margin level required. (NB: this should involve no change)

1. _The liquidity provider's bond account balance is always their current commitment level:_ This is strictly their "true" bond account.

Note:

- As mentioned above, closeout should happen as per regular trader account (with the addition of cancelling the liquidity provision and the associated LP rewards & fees consequences). So, if after cancelling all open orders the party can afford to keep the open positions sufficiently collateralised they should be left open, otherwise the positions should get liquidated.


## What data do we keep relating to liquidity provision?

1. List of all liquidity providers and their commitment sizes (bond account balance), the commitment at the start of epoch, their “equity-like share” and "liquidity score" for each market [see 0042-setting-fees-and-rewarding-lps](./0042-LIQF-setting_fees_and_rewarding_lps.md)
1. New bond account per LP per market
1. Actual amount of liquidity supplied (can be calculated from order book, [see 0034-prob-weighted-liquidity-measure](./0034-PROB-prob_weighted_liquidity_measure.ipynb))


## APIs

- Transfers to and from the bond account, new or changed commitments, and any penalties applied should all be published on the event stream
- It should be possible to query all details of liquidity providers via an API

## Acceptance Criteria

- Through the `LiquidityProvisions` API, I can list all active liquidity providers for a market (<a name="0044-LIME-001" href="#0044-LIME-001">0044-LIME-001</a>)
- Through the `LiquidityProviders` API, I can list all active liquidity providers fee share information
  - GRPC (<a name="0044-LIME-057" href="#0044-LIME-057">0044-LIME-057</a>)
  - GRAPHQL (<a name="0044-LIME-058" href="#0044-LIME-058">0044-LIME-058</a>)
  - REST (<a name="0044-LIME-059" href="#0044-LIME-059">0044-LIME-059</a>)
- When a LP commits liquidity on market 1 and on market 2 this LP has no liquidity commitment when I request for all LP provisions through `ListLiquidityProvisions` api for this party, then only LP provisions for market 1 is returned.  (<a name="0044-LIME-068" href="#0044-LIME-068">0044-LIME-068</a>)
- The [bond slashing](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/liquidity-provision-bond-account.feature) works as the feature test claims. (<a name="0044-LIME-002" href="#0044-LIME-002">0044-LIME-002</a>).
- Change of network parameter `market.liquidity.bondPenaltyParameter` will immediately change the amount by which the bond account will be 'slashed' when a liquidity provider has insufficient capital for Vega to make the transfers for their mark to market or other settlement movements, and/or margin requirements arising from their orders and open positions. (<a name="0044-LIME-003" href="#0044-LIME-003">0044-LIME-003</a>)
- Change of `market.liquidity.maximumLiquidityFeeFactorLevel` will change the maximum liquidity fee factor. Any LP orders that have already been submitted are unaffected but any new submission or amendments must respect the new maximum (those that don't get rejected). (<a name="0044-LIME-006" href="#0044-LIME-006">0044-LIME-006</a>)
- Check that bond slashing works with non-default asset decimals, market decimals, position decimals. This can be done by following a similar story to [bond slashing feature test](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/liquidity-provision-bond-account.feature). Should test at least three different combinations, each decimal settings different to each other. (<a name="0044-LIME-009" href="#0044-LIME-009">0044-LIME-009</a>)
- Change of `market.liquidity.stakeToCcyVolume` will change the liquidity obligation hence change the size of the LP orders on the order book. (<a name="0044-LIME-010" href="#0044-LIME-010">0044-LIME-010</a>)
- If `market.liquidity.stakeToCcyVolume` is set to `0.0`, there is [target stake](./0041-TSTK-target_stake.md) of `1000` and there are 3 LPs on the market with stake / fee bid submissions of `100, 0.01`, `1000, 0.02` and `200, 0.03` then the liquidity fee is `0.02`. (<a name="0044-LIME-012" href="#0044-LIME-012">0044-LIME-012</a>)

- If a liquidity provider has `fraction_of_time_on_book` >= `market.liquidity.commitmentMinTimeFraction`, no penalty will be taken from their bond account (<a name="0044-LIME-013" href="#0044-LIME-013">0044-LIME-013</a>)
- If a liquidity provider has `fraction_of_time_on_book` = `0.3`, `market.liquidity.commitmentMinTimeFraction = 0.6`, `market.liquidity.sla.nonPerformanceBondPenaltySlope = 0.7`, `market.liquidity.sla.nonPerformanceBondPenaltyMax = 0.6` at the end of an epoch then they will forfeit `35%` of their bond stake, which will be transferred into the market's insurance pool (<a name="0044-LIME-014" href="#0044-LIME-014">0044-LIME-014</a>)
and in the case of spot markets into the network treasury for the asset (<a name="0044-LIME-048" href="#0044-LIME-048">0044-LIME-048</a>)
- If a liquidity provider has `fraction_of_time_on_book` = `0.3`, `market.liquidity.commitmentMinTimeFraction = 0.6`, `market.liquidity.sla.nonPerformanceBondPenaltySlope = 0.7`, `market.liquidity.sla.nonPerformanceBondPenaltyMax = 0.6`and the market parameter change `market.liquidity.commitmentMinTimeFraction = 0.3` is enacted during the epoch then at the end of the current epoch LP will have their bond slashed. If the LP has `fraction_of_time_on_book` = `0.3` at the end of the next epoch, they are meeting their commitment and will not forfeit any of their bond stake. (<a name="0044-LIME-069" href="#0044-LIME-069">0044-LIME-069</a>)
- If a liquidity provider has `fraction_of_time_on_book` = `0.3`, `market.liquidity.commitmentMinTimeFraction = 0.0`, `market.liquidity.sla.nonPerformanceBondPenaltySlope = 0.7`, `market.liquidity.sla.nonPerformanceBondPenaltyMax = 0.6`and the market parameter change `market.liquidity.commitmentMinTimeFraction = 0.6` is enacted during the epoch then at the end of the current epoch LP will not forfeit any of their bond stake. At the end of the next epoch, the LP will have their bond slashed. (<a name="0044-LIME-070" href="#0044-LIME-070">0044-LIME-070</a>)
- If a liquidity provider has `fraction_of_time_on_book` = `0`, `market.liquidity.commitmentMinTimeFraction = 0.6`, `market.liquidity.sla.nonPerformanceBondPenaltySlope = 0.7`, `market.liquidity.sla.nonPerformanceBondPenaltyMax = 0.6` at the end of an epoch then they will forfeit `60%` of their bond stake, which will be transferred into the market's insurance pool (<a name="0044-LIME-015" href="#0044-LIME-015">0044-LIME-015</a>)
and in the case of spot markets into the network treasury for the asset (<a name="0044-LIME-046" href="#0044-LIME-046">0044-LIME-046</a>)
- If a liquidity provider has `fraction_of_time_on_book` = `0`, `market.liquidity.commitmentMinTimeFraction = 0.6`, `market.liquidity.sla.nonPerformanceBondPenaltySlope = 0.2`, `market.liquidity.sla.nonPerformanceBondPenaltyMax = 0.6` at the end of an epoch then they will forfeit `20%` of their bond stake, which will be transferred into the market's insurance pool (<a name="0044-LIME-016" href="#0044-LIME-016">0044-LIME-016</a>)
and in the case of spot markets into the network treasury for the asset (<a name="0044-LIME-047" href="#0044-LIME-047">0044-LIME-047</a>)

- If a liquidity provider with an active liquidity provision at the start of an epoch reduces their liquidity provision staked commitment during the epoch the initial committed level at the start of the epoch will remain in effect until the end of the epoch, at which point the protocol will attempt to reduce the bond to the new level. (<a name="0044-LIME-018" href="#0044-LIME-018">0044-LIME-018</a>)
- If a liquidity provider with an active liquidity provision at the start of an epoch reduces their liquidity provision staked commitment during the epoch the initial committed level at the start of the epoch will remain in effect until the end of the epoch, at which point the protocol will attempt to reduce the bond to the new level. If the reduced level has been changed several times during an epoch, only the latest value will take effect (<a name="0044-LIME-019" href="#0044-LIME-019">0044-LIME-019</a>)
- If a liquidity provider with an active liquidity provision at the start of an epoch reduces their liquidity provision staked commitment during the epoch the initial committed level at the start of the epoch will remain in effect until the end of the epoch, at which point the protocol will attempt to reduce the bond to the new level. If the bond stake has been slashed to a level lower than the amendment, this slashed level will be retained (i.e. the protocol will not attempt to now increase the commitment) (<a name="0044-LIME-020" href="#0044-LIME-020">0044-LIME-020</a>)
- If a liquidity provider with an active liquidity provision at the start of an epoch amends the fee level associated to this commitment during the epoch, this change will only take effect at the end of the epoch. (<a name="0044-LIME-021" href="#0044-LIME-021">0044-LIME-021</a>)
- If a liquidity provider with an active liquidity provision at the start of an epoch increases their liquidity provision staked commitment during the epoch, the amended committed level will take affect immediately and the protocol will attempt to increase the bond to the new level if they do not have sufficient collateral in the settlement asset of the market to meet new commitment amount then the amendment will be rejected and old commitment amount is retained (<a name="0044-LIME-030" href="#0044-LIME-030">0044-LIME-030</a>)
- If a liquidity provider with an active liquidity provision at the start of an epoch increases their liquidity provision staked commitment during the epoch, the amended committed level will take affect immediately and
  - the protocol will increase the bond to the new level if they have sufficient collateral in the settlement asset of the market to meet new commitment amount (<a name="0044-LIME-031" href="#0044-LIME-031">0044-LIME-031</a>)
  - at the end of the current epoch rewards / penalties are evaluated based on the balance of the bond account at start of epoch (<a name="0044-LIME-049" href="#0044-LIME-049">0044-LIME-049</a>)

- A liquidity provider who reduces their liquidity provision such that the total stake on the market is still above the target stake after reduction will have no penalty applied and will receive their full reduction in stake back at the end of the epoch. (<a name="0044-LIME-022" href="#0044-LIME-022">0044-LIME-022</a>)
- For a market with `market.liquidity.earlyExitPenalty = 0.25` and `target stake < total stake` already, a liquidity provider who reduces their commitment by `100` will only receive `75` back into their general account with `25` transferred into the market's insurance account. (<a name="0044-LIME-023" href="#0044-LIME-023">0044-LIME-023</a>)
In the case of spot markets it will be transferred into the network treasury for the asset (<a name="0044-LIME-045" href="#0044-LIME-045">0044-LIME-045</a>)
- For a market with `market.liquidity.earlyExitPenalty = 0.25` and `total stake = target stake + 40` already, a liquidity provider who reduces their commitment by `100` will receive a total of `85` back into their general account with `15` transferred into the market's insurance account (`40` received without penalty, then the remaining `60` receiving a `25%` penalty). (<a name="0044-LIME-024" href="#0044-LIME-024">0044-LIME-024</a>)
- In the case of spot markets it will be transferred into the network treasury for the asset (<a name="0044-LIME-044" href="#0044-LIME-044">0044-LIME-044</a>)

- For a market with `market.liquidity.earlyExitPenalty = 0.25` and `total stake = target stake + 140` already, if one liquidity provider places a transaction to reduce their stake by `100` followed by a second liquidity provider who reduces their commitment by `100`, the first liquidity provider will receive a full `100` stake back whilst the second will receive a total of `85` back into their general account with `15` transferred into the market's insurance account (`40` received without penalty, then the remaining `60` receiving a `25%` penalty). (<a name="0044-LIME-025" href="#0044-LIME-025">0044-LIME-025</a>)

In the case of spot markets it will be transferred into the network treasury for the asset (<a name="0044-LIME-043" href="#0044-LIME-043">0044-LIME-043</a>)


- For a futures market with `market.liquidity.earlyExitPenalty = 0.25` and `total stake = target stake + 140` already, if the following transactions occur:

  - `LP1` places a transaction to reduce their stake by `30`
  - `LP2`  places a transaction to reduce their stake by `100`,
  - `LP1` places a transaction to update their reduction to `100`
  `LP2` will receive a full `100` stake back whilst `LP1` will receive a total of `85` back into their general account with `15` transferred into the market's insurance account  (<a name="0044-LIME-026" href="#0044-LIME-026">0044-LIME-026</a>)
- When LP is committed they are obliged to provide liquidity equal to their commitment size on both sides of the order book (<a name="0044-LIME-027" href="#0044-LIME-027">0044-LIME-027</a>)
- For a market that is in opening auction and LP has committed liquidity:
  - LP can increase their commitment and it will take effect immediately (<a name="0044-LIME-050" href="#0044-LIME-050">0044-LIME-050</a>). For spot (<a name="0044-LIME-054" href="#0044-LIME-054">0044-LIME-054</a>)
  - LP can decrease their commitment and it will take affect immediately without incurring penalties (<a name="0044-LIME-051" href="#0044-LIME-051">0044-LIME-051</a>). For spot (<a name="0044-LIME-055" href="#0044-LIME-055">0044-LIME-055</a>)
  - LP can cancel their commitment without incurring penalties (<a name="0044-LIME-053" href="#0044-LIME-053">0044-LIME-053</a>)
- For a market that is in continuous trading and a single LP has committed liquidity:
  - The LP can cancel their commitment at any time (though this may involve incurring a penalty) (<a name="0044-LIME-060" href="#0044-LIME-060">0044-LIME-060</a>) for spot (<a name="0044-LIME-056" href="#0044-LIME-056">0044-LIME-056</a>)
- For a market that is in continuous trading and LP has committed liquidity
  - when `market.liquidity.providers.fee.calculationTimeStep` is set to `0` any funds that are in `ACCOUNT_TYPE_FEES_LIQUIDITY` account will be distributed to `ACCOUNT_TYPE_LP_LIQUIDITY_FEES` on the next block (<a name="0044-LIME-061" href="#0044-LIME-061">0044-LIME-061</a>)
  - if `market.liquidity.providers.fee.calculationTimeStep` is set to `10s` and `validators.epoch.length` is set to `15s`, during the first `10` seconds of the current epoch parameter change `market.liquidity.providers.fee.calculationTimeStep = 3s` is enacted, at the end of the epoch any funds that are in `ACCOUNT_TYPE_FEES_LIQUIDITY` account will be distributed to `ACCOUNT_TYPE_LP_LIQUIDITY_FEES` on the next block. For the next epoch the distribution will take place at `3` second intervals (<a name="0044-LIME-062" href="#0044-LIME-062">0044-LIME-062</a>)
- For a market that is in continuous trading if a new LP has active buy and sell orders on the market then makes a liquidity commitment to that market, at the start of the next epoch the active orders will count towards the LPs liquidity commitment. (<a name="0044-LIME-071" href="#0044-LIME-071">0044-LIME-071</a>)
- If an LP with a liquidity provision and active orders on a market cancel their provision only (orders remain active), after the cancellation penalty (if it applies at end of epoch) the end of next epoch lp will not accrue any rewards or incur penalty for trades on the market. (<a name="0044-LIME-081" href="#0044-LIME-081">0044-LIME-081</a>)
- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in continuous trading with `mid price` set to `5`, a new LP has committed liquidity with buy order at price `4.74` and sell order at price `5.25`. During the epoch market parameter change `market.liquidity.priceRange = 0.1` (10%) is enacted then at the end of the current epoch the LP is meeting their committed volume of notional and a bond penalty will apply. (<a name="0044-LIME-072" href="#0044-LIME-072">0044-LIME-072</a>)

- For a market with parameter `market.liquidity.priceRange = 0.05` (5%), is in continuous trading with `mid price` set to `5`, a new LP has committed liquidity and orders at buy price `4.74` and sell price `5.25`. During the epoch market parameter change `market.liquidity.priceRange = 0.01` (1%) is enacted then at the end of the current epoch the LP is meeting their volume of notional and penalty will not apply. (<a name="0044-LIME-074" href="#0044-LIME-074">0044-LIME-074</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5`, `indicative uncrossing price` is set to `4` and the LP has committed liquidity and orders at buy price `3.79` and sell price `5.25`, at the end of the epoch the LP is not meeting their committed volume of notional because the buy price `3.79` is less than `5%` of `1-0.05 x min(5, 4) = 3.80` (<a name="0044-LIME-075" href="#0044-LIME-075">0044-LIME-075</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5`, `indicative uncrossing price` is set to `4` and the LP has committed liquidity and orders at buy price `3.8` and a sell price `5.25`, the LP is meeting their committed volume of notional (<a name="0044-LIME-076" href="#0044-LIME-076">0044-LIME-076</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5`, `indicative uncrossing price` is set to `6`, the LP has committed liquidity and orders at buy price `4.75` and sell price `6.31`, the LP is not meeting their committed volume of notional because the sell price `6.31` is more than `5%` of `1+ 0.05 x max (5, 6) = 6.30` (<a name="0044-LIME-077" href="#0044-LIME-077">0044-LIME-077</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5`, `indicative uncrossing price` is set to `6`, the LP has committed liquidity and orders at buy price `4.75` and sell price `6.3`, the LP is not meeting their committed volume of notional (<a name="0044-LIME-078" href="#0044-LIME-078">0044-LIME-078</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5` and we do not have `indicative uncrossing price`, the LP has committed liquidity and orders at buy price `4.74` and sell price `5.25`, the LP is not meeting their committed volume of notional because the buy price `4.74` is less than `5%` of `1-0.05 x min(5, n/a) = 4.75` (<a name="0044-LIME-079" href="#0044-LIME-079">0044-LIME-079</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5` and we do not have `indicative uncrossing price`, the LP has committed liquidity and orders at buy price `4.75` and sell price `5.26` the LP is not meeting their committed volume of notional because the sell price `5.26` is more than `5%` of `1+ 0.05 x max (5, n/a) = 5.25` (<a name="0044-LIME-080" href="#0044-LIME-080">0044-LIME-080</a>)

- For a market with market parameter `market.liquidity.priceRange = 0.05` (5%), is in monitoring auction with `last trade price` set to `5` and we do not have `indicative uncrossing price`, the LP has committed liquidity and orders at buy price `4.75` and sell price `5.25`, the LP is meeting their committed volume of notional (<a name="0044-LIME-073" href="#0044-LIME-073">0044-LIME-073</a>)


### Qualifying Order Types

- Once liquidity is committed LPs can meet their commitment by placing limit orders, pegged limit orders and iceberg orders. For iceberg orders only the visible peak counts towards the commitment. (<a name="0044-LIME-028" href="#0044-LIME-028">0044-LIME-028</a>)
- Parked pegged limit orders and stop-loss orders do not count towards an LPs liquidity commitment. (<a name="0044-LIME-029" href="#0044-LIME-029">0044-LIME-029</a>)

### Snapshot

- A snapshot must include the aggregate LP fee accounts and their balances so that after a node is started using the snapshot it can retain the aggregate LP fee accounts and their balances for each market. (<a name="0044-LIME-032" href="#0044-LIME-032">0044-LIME-032</a>)

### Protocol upgrade

- After a protocol upgrade each market's aggregate LP fee accounts and their balances are retained (<a name="0044-LIME-033" href="#0044-LIME-033">0044-LIME-033</a>)

### Checkpoint

- Each market's aggregate LP fee accounts must be included in the checkpoint and where the network is restored, the aggregate LP fee account balance will be transferred to the LP's general account. (<a name="0044-LIME-034" href="#0044-LIME-034">0044-LIME-034</a>)

#### Network History - Data node restored from network history segments

- A datanode restored from network history will contain each market's aggregate LP fee accounts which were created prior to the restore and these can be retrieved via APIs on the new datanode. (<a name="0044-LIME-036" href="#0044-LIME-036">0044-LIME-036</a>)

#### Network parameters validation

- Boundary values are respected for the network parameters
  - `market.liquidityV2.bondPenaltyParameter` valid values: `>=0`, `<=1000` default value of `0.1` (<a name="0044-LIME-037" href="#0044-LIME-037">0044-LIME-037</a>)
  - `market.liquidityV2.earlyExitPenalty` valid values: `>=0`, `<=1000` default value of `0.1`  (<a name="0044-LIME-038" href="#0044-LIME-038">0044-LIME-038</a>)
  - `market.liquidityV2.maximumLiquidityFeeFactorLevel` valid values: `>=0`, `<=1` default value of `1`  (<a name="0044-LIME-039" href="#0044-LIME-039">0044-LIME-039</a>)
  - `market.liquidityV2.sla.nonPerformanceBondPenaltySlope` valid values: `>=0`, `<=1000` default value of `2`  (<a name="0044-LIME-040" href="#0044-LIME-040">0044-LIME-040</a>)
  - `market.liquidityV2.sla.nonPerformanceBondPenaltyMax` valid values: `>=0`, `<=1` default value of `0.5`  (<a name="0044-LIME-041" href="#0044-LIME-041">0044-LIME-041</a>)
  - `market.liquidityV2.stakeToCcyVolume` valid values: `>=0`, `<=100` default value of `1`   (<a name="0044-LIME-042" href="#0044-LIME-042">0044-LIME-042</a>)
  - `market.liquidity.providers.fee.calculationTimeStep` valid values: `>=0`, `<= validators.epoch.length` default value of `60m` (<a name="0044-LIME-063" href="#0044-LIME-063">0044-LIME-063</a>)

#### Market parameters validation

- Boundary values are respected for the market parameters
  - `market.liquidity.commitmentMinTimeFraction` valid values: `>=0`, `<=1` (<a name="0044-LIME-064" href="#0044-LIME-064">0044-LIME-064</a>)
  - `market.liquidity.priceRange` valid values: `>0`, `<=100` (<a name="0044-LIME-065" href="#0044-LIME-065">0044-LIME-065</a>)
  - `market.liquidity.slaCompetitionFactor` valid values: `>=0`, `<=1` (<a name="0044-LIME-066" href="#0044-LIME-066">0044-LIME-066</a>)
  - `market.liquidity.performanceHysteresisEpochs` valid values: `>=1`, `<=366` (<a name="0044-LIME-067" href="#0044-LIME-067">0044-LIME-067</a>)
