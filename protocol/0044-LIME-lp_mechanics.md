# Liquidity provision mechanics

The point of liquidity provision on Vega is to incentivise people to place orders on the market that maintain liquidity on the book. 
This is done via a financial commitment and reward + penalty mechanics, and through the use of a special batch order type that announces that a party is entering the liquidity provision (LP) service level agreement (SLA).


Important note on wording:

- liquidity provision / liquidity COMMITMENTs are the amount of stake a liquidity provider places as a bond on the market to earn rewards.
- the COMMITMENT is converted via a multiplicative network parameter `market.liquidity.stakeToCcyVolume` to a liquidity OBLIGATION, measured in price level x volume i.e. settlement currency of the market.

## Network and market parameters

### Network parameters

- `market.liquidity.bondPenaltyParameter` - used to calculate the penalty to liquidity providers when they fail to meet their obligations.
Valid values: any decimal number `>= 0` with a default value of `0.1`.
- `market.liquidity.maximumLiquidityFeeFactorLevel` - used in validating fee amounts that are submitted as part of [lp order type](./0038-OLIQ-liquidity_provision_order_type.md). Note that a value of `0.05 = 5%`. Valid values are: any decimal number `>0` and `<=1`. Default value `1`.
- `market.liquidity.stakeToCcyVolume` - used to translate a commitment to an obligation. Any decimal number `>0` with default value `1.0`.
- `validators.epoch.length` - LP rewards from liquidity fees are paid out once per epoch according to whether they met the "SLA" (implied by `market.liquidity.committmentMinTimeFraction`) and their previous performance (for the last n epochs defined by `market.liqudity.performanceHysteresisEpochs`), see [epoch spec](./0050-EPOC-epochs.md).


### Market parameters

- `market.liquidity.priceRange` (decimal) - this is a percentage price move (e.g. `0.05 = 5%`) from `mid_price` during continuous trading or indicative uncrossing price during auctions. This is set / can be modified as part of [market proposal](0028-GOVE-governance.md) / market change proposal.

- `market.liquidity.committmentMinTimeFraction` (decimal) —  minimum fraction of time LPs must spend "on the book" providing their committed liquidity.

- `market.liquidity.providers.fee.calculationTimeStep` (time period e.g. `12h` or `7d`) controls how often LP the quality of liquidity supplied by the LPs is evaluated and fees arising from that period are earmarked for specific parties. 

- `market.liqudity.performanceHysteresisEpochs` (uint) - number of liquidity epochs over which past performance will continue to affect rewards.

For LP reward calculations based on the SLA see the [0042-LIQF spec](./0042-LIQF-setting_fees_and_rewarding_lps.md).


## Mechanism overview

At a high level, the liqudity mechanism in Vega allows Liquidity Providers (LPs) to commit liquidity to a market and "bid" to set the liqudity fee on the market. LPs that meet this commitment are rewarded from the fee revenue. This is done by:

- Requiring LPs to meet an SLA (i.e. % of time spent providing liquidity within the defined range) in order to be rewarded.

- Rewarding LPs more for better performance against the SLA vs other LPs, ensuring there is an incentive to do more than the bare minimum and more than other LPs, if market conditions allow.

- Penalising LPs that commit and do not meet the SLA, to reduce the attractiveness of opportunistically going after rewards with no intention to meet the SLA in more challenging conditions, and of leeching style attacks on the rewards.

Once committed LPs attempt to meet their comitment by placing and maintaining normal orders on the market. They may use pegged or priced limit orders, along with features like post only and iceberg to control their risk. Non-persistent orders, parked pegged orders, and stop-loss orders do not count towards an LP's supplied liquidity and therefore cannot be used to meet the SLA.


## Commit liquidity network transaction

Any Vega participant can apply to become a liquidity provider (LP) on a market by submitting a transaction to the network which includes the following

1. Market ID
1. COMMITMENT AMOUNT: liquidity commitment amount (specified as a unitless number that represents the amount of settlement asset of the market)
1. FEES: nominated [liquidity fee factor](./0029-FEES-fees.md), which is an input to the calculation of taker fees on the market, as per [setting fees and rewarding lps](./0042-LIQF-setting_fees_and_rewarding_lps.md)

Accepted if all of the following are true:

- The transaction is valid: the submitting party has sufficient collateral in their general account to meet the size of their nominated commitment amount.
- The market is in a state that accepts new liquidity provision [market lifecycle spec](./0043-MKTL-market_lifecycle.md).


## COMMITMENT AMOUNT

### Processing the commitment

When a commitment is made the liquidity commitment amount is assumed to be specified in terms of the settlement currency of the market.
There is an minimum LP stake which is `market.liquidityProvision.minLpStakeQuantumMultiple x quantum` where `quantum` is specified per asset, see [asset framework spec](./0040-ASSF-asset_framework.md).

If the participant has sufficient collateral to cover their commitment, the commitment amount (stake) is transferred from the participant's general account to their (maybe newly created) [liquidity provision bond account](./0013-ACCT-accounts.md#liquidity-provider-bond-accounts) (new account type, 1 per liquidity provider per market and asset where they are committing liquidity, created as needed). 
For clarity, liquidity providers will have a separate [margin account](./0013-ACCT-accounts.md#trader-margin-accounts) and [bond account](./0013-ACCT-accounts.md#liquidity-provider-bond-accounts).

Liquidity provider bond account:

- Each active market has one bond account per liquidity provider, per settlement asset for that market.
- When a liquidity provider transaction is approved, the size of their staked bond is immediately transferred from their general account to this bond account.
- A liquidity provider can only prompt a transfer of funds to or from this account by (re)submitting the LP commitment  transaction: a valid transaction to create, increase, or decrease their commitment to the market. 
  - Transfers to/from this account also occur when it is used for settlement or margin shortfall, when penalties are applied, and if the account is under-collateralised because of these uses and is subsequently topped up to the commitment amount during collateral search (see below)
- Collateral withdrawn from this account may only be transferred to either:
  - The insurance pool of the market (in event of penalties/slashing)
  - The liquidity provider's margin account or the network's settlement account/other participant's margin accounts (during a margin search and mark to market settlement) in the event that they have zero balance in their general account.
  - The liquidity provider's general account (in event of liquidity provider reducing their commitment)

### liquidity provider proposes to amend commitment amount

The commitment transaction is also used to amend any aspect of their liquidity provision obligations.
A participant may apply to amend their commitment amount by submitting a transaction for the market with a revised commitment amount.

`proposed-commitment-variation = new-proposed-commitment-amount - old-commitment-amount`

#### INCREASING COMMITMENT

_Case:_ `proposed-commitment-variation >= 0`
A liquidity provider can always increase their commitment amount as long as they have sufficient collateral in the settlement asset of the market to meet the new commitment amount and cover the margins required.

If they do not have sufficient collateral the transaction is rejected in entirety. This means that any data from the fees or orders are not applied. This means that the  `old-commitment-amount` is retained.

#### DECREASING COMMITMENT

_Case:_ `proposed-commitment-variation < 0`
We to calculate whether the liquidity provider may lower their commitment amount and if so, by how much. To do this we first evaluate the maximum amount that the market can reduce by given the current liquidity demand in the market.

`maximum-reduction-amount = total_stake - target_stake`

where:

- `total_stake` is the sum of all stake of all liquidity providers bonded to this market.
- `target_stake` is a measure of the market's current stake requirements, as per the calculation in the [target stake](./0041-TSTK-target_stake.md).
- `actual-reduction-amount = min(-proposed-commitment-variation, maximum-reduction-amount)`
- `new-actual-commitment-amount =  old-commitment-amount - actual-reduction-amount`
- `market.liquidityProvision.shapes.maxSize` is the maximum entry of the LP order shape on liquidity commitment.

i.e. liquidity providers are allowed to decrease the liquidity commitment subject to there being sufficient stake committed to the market so that it stays above the market's required stake threshold. The above formulae result in the fact that if `maximum-reduction-amount = 0`, then `actual-reduction-amount = 0` and therefore the liquidity provider is unable to reduce their commitment amount.

When `actual-reduction-amount > 0`:

- the difference between their actual staked amount and new commitment is transferred back to their general account, i.e.
`transferred-to-general-account-amount =  actual-stake-amount - new-actual-commitment-amount`
- the revised fee amount and set of orders are processed.

Example: if you have a commitment of 500DAI and your bond account only has 400DAI in it (due to slashing - see below), and you submit a new commitment amount of 300DAI, then we only transfer 100DAI such that your bond account is now square.
When `actual-reduction-amount = 0` the transaction is still processed for any data and actions resulting from the transaction's new fees or order information.

## Fees

### Nominating and amending fee amounts

The network transaction is used by liquidity providers to nominate a fee amount which is used by the network to calculate the [liquidity_fee](./0042-LIQF-setting_fees_and_rewarding_lps.md) of the market. Liquidity providers may amend their nominated fee amount by submitting a liquidity provider transaction to the network with a new fee amount. If the fee amount is valid, this new amount is used. Otherwise, the entire transaction is considered invalid.

### How fee amounts are used

The [liquidity_fee](./0029-FEES-fees.md) of a market on Vega takes as an input, a [`fee factor[liquidity]`](./0029-FEES-fees.md) which is calculated by the network, taking as an input the data submitted by the liquidity providers in their liquidity provision network transactions (see [this spec](./0042-LIQF-setting_fees_and_rewarding_lps.md) for more information on the specific calculation).

### Distributing fees between liquidity providers

When calculating fees for a trade, the size of a liquidity provider’s commitment along with when they committed and the market size are inputs that will be used to calculate how the liquidity fee is distributed between liquidity providers. See [setting fees and rewarding lps](./0042-LIQF-setting_fees_and_rewarding_lps.md) for the calculation of the split.


## Liquidity provision and penalties

### Calculating liquidity from commitment

Committed Liqudity Providers are required to provide a multiple of their stake (supplied in the settlement currency of the market) in notional volume of orders within the range defined by TODO: define.

The multiple is controlled by a network parameter `market.liquidity.stakeToCcyVolume`:

```
liquidity_required = stake_amount ✖️ market.liquidity.stakeToCcyVolume
```

**During auction:**

- Liquidity providers, who wish to meet their SLA, are expected to supply liquidity during auctions. 

### Penalties

If at any point in time, a liquidity provider has insufficient capital to make the transfers for their mark to market or other settlement movements, and/or margin requirements arising from their orders and open positions, the network will utilise their liquidity provision commitment, held in the _liquidity provider bond account_ to cover the shortfall. The protocol will also apply a penalty proportional to the size of the shortfall, which will be transferred to the market's insurance pool.

Calculating the penalty:

`bondPenalty = market.liquidity.bondPenaltyParameter ⨉ shortfall`

The above simple formula defines the amount by which the bond account will be 'slashed', where:

- `market.liquidity.bondPenaltyParameter` is a network parameter
- `shortfall` refers to the absolute value of the funds that the liquidity provider was unable to cover through their margin and general accounts, that are needed for settlement (mark to market or [product](./0051-PROD-product.md) driven) or to meet their margin requirements.

_Auctions:_ if this occurs at the transition from auction mode to continuous trading, the `market.liquidity.bondPenaltyParameter` will not be applied / will always be set to zero.

The network will:

1. _As part of the normal collateral "search" process:_ Access the liquidity provider's bond account to make up the shortfall. If there is insufficient funds to cover this amount, the full balance of the bond account will be used. Note that this means that the transfer request should include the liquidity provider's bond account in the list of accounts to search, and that the bond account would always be emptied before any insurance pool funds are used or loss socialisation occurs.

1. _If there was a shortfall and the bond account was accessed:_ Transfer an amount equal to the `market.liquidity.bondPenaltyParameter` calculated above from the liquidity provider's bond account to the market's insurance pool. If there are insufficient funds in the bond account, the full amount will be used and the remainder of the penalty (or as much as possible) should be transferred from the liquidity provider's margin account.

1. Initiate closeout of the LPs order and/or positions as normal if their margin does not meet the minimum maintenance margin level required. (NB: this should involve no change)

1. _If the liquidity provider's orders or positions were closed out, and they are therefore no longer supplying the liquidity implied by their Commitment:_ In this case the liquidity provider's Commitment size is set to zero and they are no longer a liquidity provider for fee/reward purposes, and their commitment can no longer be counted towards the supplied liquidity in the market. (From a Core perspective, it is as if the liquidity provider has exited their commitment entirely and they no longer need to be tracked as an LP.)

Note:

- As mentioned above, closeout should happen as per regular trader account (with the addition of cancelling the liquidity provision and the associated LP rewards & fees consequences). So, if after cancelling all open orders the party can afford to keep the open positions sufficiently collateralised they should be left open, otherwise the positions should get liquidated.
- Bond account balance should never get directly confiscated. It should only be used to cover margin shortfalls with appropriate penalty applied each time it's done. Once the funds are in margin account they should be treated as per normal rules involving that account.

### Bond account top up by collateral search

In the same way that a collateral search is initiated to attempt to top-up a trader's margin account if it drops below the _collateral search level_, the system must also attempt to top up the bond account if its balance drops below the size of the LP's commitment.

This should happen every time the network is performing a margin calculation and search. The system should prioritise topping up the margin account first, and then the bond account, if there are insufficient funds to do both.


## What data do we keep relating to liquidity provision?

1. List of all liquidity providers and their commitment sizes and their “equity-like share” for each market [see 0042-setting-fees-and-rewarding-lps](./0042-LIQF-setting_fees_and_rewarding_lps.md)
1. Liquidity provision orders (probably need to be indexed somewhere in addition to the order book)
1. New account per market holding all committed liquidity provider bonds
1. Actual amount of liquidity supplied (can be calculated from order book, [see 0034-prob-weighted-liquidity-measure](./0034-PROB-prob_weighted_liquidity_measure.ipynb))
1. Each liquidity provider's actual bond amount (i.e. the balance of their bond account)

## APIs

- Transfers to and from the bond account, new or changed commitments, and any penalties applied should all be published on the event stream
- It should be possible to query all details of liquidity providers via an API

## Acceptance Criteria

- Through the API, I can list all active liquidity providers for a market (<a name="0044-LIME-001" href="#0044-LIME-001">0044-LIME-001</a>)
- The [bond slashing](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/liquidity-provision-bond-account.feature) works as the feature test claims. (<a name="0044-LIME-002" href="#0044-LIME-002">0044-LIME-002</a>).
- Change of network parameter `market.liquidity.bondPenaltyParameter` will immediately change the amount by which the bond account will be 'slashed' when a liquidity provider has insufficient capital for Vega to make the transfers for their mark to market or other settlement movements, and/or margin requirements arising from their orders and open positions. (<a name="0044-LIME-003" href="#0044-LIME-003">0044-LIME-003</a>)
- Change of `market.liquidity.maximumLiquidityFeeFactorLevel` will change the maximum liquidity fee factor. Any LP orders that have already been submitted are unaffected but any new submission or amendments must respect the new maximum (those that don't get rejected). (<a name="0044-LIME-006" href="#0044-LIME-006">0044-LIME-006</a>)
- Check that bond slashing works with non-default asset decimals, market decimals, position decimals. This can be done by following a similar story to [bond slashing feature test](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/liquidity-provision-bond-account.feature). Should test at least three different combinations, each decimal settings different to each other. (<a name="0044-LIME-009" href="#0044-LIME-009">0044-LIME-009</a>)
- Change of `market.liquidity.stakeToCcyVolume` will change the liquidity obligation hence change the size of the LP orders on the order book. (<a name="0044-LIME-010" href="#0044-LIME-010">0044-LIME-010</a>)
- If `market.liquidity.stakeToCcyVolume` is set to `0.0` then the [LP provision order](./0038-OLIQ-liquidity_provision_order_type.md) places `0` volume on the book for the LP regardless of the shape submitted and regardless of the `stake` committed. (<a name="0044-LIME-011" href="#0044-LIME-011">0044-LIME-011</a>)
- If `market.liquidity.stakeToCcyVolume` is set to `0.0`, there is [target stake](./0041-TSTK-target_stake.md) of `1000` and there are 3 LPs on the market with stake / fee bid submissions of `100, 0.01`, `1000, 0.02` and `200, 0.03` then the liquidity fee is `0.02`. (<a name="0044-LIME-012" href="#0044-LIME-012">0044-LIME-012</a>)
