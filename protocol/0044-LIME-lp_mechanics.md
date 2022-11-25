# Liquidity provision mechanics

The point of liquidity provision on Vega is to incentivise people to place orders on the market that maintain liquidity on the book. This is done via a financial commitment and reward + penalty mechanics, and through the use of a special batch order type that automatically updates price/size as needed to meet the commitment and automatically refreshes its volume after trading to ensure continuous liquidity provision.

Each market on Vega must have at least one committed liquidity provider (LP).
This is enforced when a [governance proposal to create a market is submitted](./0028-GOVE-governance.md#1-create-market).
In particular the proposal has to include [liquidity provision commitment](./0038-OLIQ-liquidity_provision_order_type.md),
see also below. 

Important note on wording:
* liquidity provision / liquidity COMMITMENTs are the amount of stake a liquidity provider places as a bond on the market to earn rewards.
* the COMMITMENT is converted to a liquidity OBLIGATION, measured in siskas.


## Commit liquidity network transaction

Any Vega participant can apply to become a liquidity provider (LP) on a market by submitting a transaction to the network which includes the following

1. Market ID
1. COMMITMENT AMOUNT: liquidity commitment amount (specified as a unitless number that represents the amount of settlement asset of the market)
1. FEES: nominated [liquidity fee factor](./0029-FEES-fees.md), which is an input to the calculation of taker fees on the market, as per [setting fees and rewarding lps](./0042-LIQF-setting_fees_and_rewarding_lps.md)
1. ORDERS: a set of _liquidity buy orders_ and _liquidity sell orders_ ("buy shape" and "sell shape") to meet the liquidity provision obligation, see [MM orders spec](./0038-OLIQ-liquidity_provision_order_type.md).

Accepted if all of the following are true:
- The order is valid - see [0038-OLIQ-Liquidity provision order type spec](./0038-OLIQ-liquidity_provision_order_type.md) for full details
- The participant has sufficient collateral in their general account to meet the size of their nominated commitment amount as well as the margin requirements 
- The market is in a state that accepts new liquidity provision [market lifecycle spec](./0043-MKTL-market_lifecycle.md).

General notes:
- If market is in auction mode it won't be possible to check the margin requirements for orders generated from LP commitment. If on transition from auction the funds in margin and general accounts are insufficient to cover the margin requirements associated with those orders funds in bond account should be used to cover the shortfall (with no penalty applied as outlined in the [Penalties](#penalties) section). If even the entire bond account balance is insufficient to cover those margin requirement the liquidity commitment transaction should get cancelled.


### Valid submission combinations:

Assume MarketID is always submitted, then a participant can submit the following combinations:
1. A transaction containing all fields specified can be submitted at any time to either create or change a commitment (if commitment size is zero, the orders and fee bid cannot be supplied - i.e. tx is invalid)
1. Any other combination of a subset of fields can be supplied any time a liquidity provider has a non-zero commitment already, to request to amend part of their commitment.

Example: it's possible to amend fee bid or orders individually or together without changing the commitment level.
Example: amending only a commitment amount but retaining old fee bid and orders is also allowed.


## COMMITMENT AMOUNT

### Processing the commitment
When a commitment is made the liquidity commitment amount is assumed to be specified in terms of the settlement currency of the market. 
There is an minimum LP stake which is `market.liquidityProvision.minLpStakeQuantumMultiple x quantum` where `quantum` is specified per asset, see [asset framework spec](./0040-ASSF-asset_framework.md).

If the participant has sufficient collateral to cover their commitment and margins for the orders generated from their proposed commitment, the commitment amount (stake) is transferred from the participant's general account to their (maybe newly created) [liquidity provision bond account](./0013-ACCT-accounts.md#liquidity-provider-bond-accounts) (new account type, 1 per liquidity provider per market and asset where they are commitment liquidity, created as needed). For clarity, liquidity providers will have a separate [margin account](./0013-ACCT-accounts.md#trader-margin-accounts) and [bond account](./0013-ACCT-accounts.md#liquidity-provider-bond-accounts).

- Liquidity provider bond account:
    - [ ] Each active market has one bond account per liquidity provider, per settlement asset for that market.
    - [ ] When a liquidity provider transaction is approved, the size of their staked bond is immediately transferred from their general account to this bond account.
    - [ ] A liquidity provider can only prompt a transfer of funds to or from this account by submitting a valid transaction to create, increase, or decrease their commitment to the market, which must be validated and pass all checks (e.g. including those around minimum liquidity commitment required, when trying to reduce commitment). 
    Transfers to/from this account also occur when it is used for settlement or margin shortfall, when penalties are applied, and if the account is under-collateralised because of these uses and is subsequently topped up to the commitment amount during collateral search (see below)
    - [ ] Collateral withdrawn from this account may only be transferred to either:
      - [ ] The insurance pool of the market (in event of penalties/slashing)
      - [ ] The liquidity provider's margin account or the network's settlement account/other participant's margin acounts (during a margin search and mark to market settlement) in the event that they have zero balance in their general account.
      - [ ] The liquidity provider's general account (in event of liquidity provider reducing their commitment)


### liquidity provider proposes to amend commitment amount

The commitment transaction is also used to amend any aspect of their liquidity provision obligations.
A participant may apply to amend their commitment amount by submitting a transaction for the market with a revised commitment amount. 

```
proposed-commitment-variation = new-proposed-commitment-amount - old-commitment-amount`
```

**INCREASING COMMITMENT**
***Case:*** `proposed-commitment-variation >= 0`
A liquidity provider can always increase their commitment amount as long as they have sufficient collateral in the settlement asset of the market to meet the new commitment amount and cover the margins required.

If they do not have sufficient collateral the transaction is rejected in entirety. This means that any data from the fees or orders are not applied. This means that the  `old-commitment-amount` is retained.


**DECREASING COMMITMENT**

***Case:*** `proposed-commitment-variation < 0`
We to calculate whether the liquidity provider may lower their commitment amount and if so, by how much. To do this we first evaluate the maximum amount that the market can reduce by given the current liquidity demand in the market.

```
maximum-reduction-amount = total_stake - target_stake
```

where:

- `total_stake` is the sum of all stake of all liquidity providers bonded to this market.
- `target_stake` is a measure of the market's current stake requirements, as per the calculation in the [target stake](./0041-TSTK-target_stake.md).
- `actual-reduction-amount = min(-proposed-commitment-variation, maximum-reduction-amount)`
- `new-actual-commitment-amount =  old-commitment-amount - actual-reduction-amount`
- `market.liquidityProvision.shapes.maxSize` is the maximum entry of the LP order shape on liquidity commitment. 


i.e. liquidity providers are allowed to decrease the liquidity commitment subject to there being sufficient stake committed to the market so that it stays above the market's required stake threshold. The above formulae result in the fact that if `maximum-reduction-amount = 0`, then `actual-reduction-amount = 0` and therefore the liquidity provider is unable to reduce their commitment amount.

When `actual-reduction-amount > 0`:

- [ ] the difference between their actual staked amount and new commitment is transferred back to their general account, i.e.
`transferred-to-general-account-amount =  actual-stake-amount - new-actual-commitment-amount `

- [ ] the revised fee amount and set of orders are processed.

Example: if you have a commitment of 500DAI and your bond account only has 400DAI in it (due to slashing - see below), and you submit a new commitment amount of 300DAI, then we only transfer 100DAI such that your bond account is now square.
When `actual-reduction-amount = 0` the transaction is still processed for any data and actions resulting from the transaction's new fees or order information.


## Fees

### Nominating and amending fee amounts

The network transaction is used by liquidity providers to nominate a fee amount which is used by the network to calculate the [liquidity_fee](./0042-LIQF-setting_fees_and_rewarding_lps.md) of the market. Liquidity providers may amend their nominated fee amount by submitting a liquidity provider transaction to the network with a new fee amount. If the fee amount is valid, this new amount is used. Otherwise, the entire transaction is considered invalid.


### How fee amounts are used

The [liquidity_fee](./0029-FEES-fees.md) of a market on Vega takes as an input, a [`fee factor[liquidity]`](./0029-FEES-fees.md) which is calculated by the network, taking as an input the data submitted by the liquidity providers in their liquidity provision network transactions (see [this spec](./0042-LIQF-setting_fees_and_rewarding_lps.md) for more information on the specific calculation).


### Distributing fees between liquidity providers

When calculating fees for a trade, the size of a liquidity provider’s commitment along with when they committed and the market size are inputs that will be used to calculate how the liquidity fee is distributed between liquidity providers. See [setting fees and rewarding lps](./0042-LIQF-setting_fees_and_rewarding_lps.md) for the calculation of the split.


## Orders (buy shape/sell shape)

In a market maker proposal transaction the participant must submit a valid set of liquidity provider orders (buy shape and sell shape). Liquidity provider orders are a special order type described in the [liquidity provision orders spec](./0038-OLIQ-liquidity_provision_order_type.md). Validity is also defined in that spec. Note, liquidity provider participants can place regular (non liquidity provider orders) and these are considered to be contributing to them meeting their obligation, but they must also have provided the set of valid buy/sell orders as described in the [liquidity provision orders spec](./0038-OLIQ-liquidity_provision_order_type.md).

A liquidity provider can amend their orders by providing a new set of liquidity provision orders in the liquidity provider network transaction. If the amended orders are invalid the transaction is rejected, and the previous set of orders will be retained.


### Checking margins for orders

As pegged orders are parked during an auction and not placed on the book, margin checks will not occur for these orders. This includes checking the orders margin when checking the validity of the transaction so orders are accepted. Open positions are treated the same as any other open positions and their liquidity provider orders are pegged orders and will be treated the same as any other pegged orders.


## Liquidity provision and penalties

### Calculating liquidity from commitment

Each liquidity provider supplies an amount of liquidity which is calculated from their commitment (stake) and measured in 'currency siskas' (i.e. USD siskas, ETH siskas, etc.).This is calculated by multiplying the stake by the network parameter `market.liquidity.stakeToCcySiskas` as follows:

```
lp_liquidity_obligation_in_ccy_volume = market.liquidity.stakeToCcyVolume ⨉ stake.
```

Note here "ccy" stands for "currency". Liquidity measure units are 'currency x volume'. This is because the calculation is basically `volume ⨉  ⨉ price of the volume` and the price of the volume is in the said currency.


### How liquidity is supplied

When a liquidity provider commits to a market, the LP Commitment transaction includes a _buy shape_ and _sell shape_ which allow the LP to spread their liquidity provision over a number of pegged orders at varying distances from the best prices on each side of the book. These 'shapes' are used to generate pegged orders (see the [liquidity provision order type spec](./0038-OLIQ-liquidity_provision_order_type.md)).

Since liquidity provider orders automatically refresh, the protocol ensures that a liquidity provider always supplies their committed liquidity as long as they have sufficient capital to meet the margin requirements of these orders.

**During auction:**

- Pegged orders generated from liquidity provider Commitments are parked like all pegged orders during auctions. Limit orders placed by liquidity providers obey the normal rules for their specific order type in an auction.
- Liquidity providers are not required to supply any orders that offer liquidity or trade during an auction uncrossing. They must maintain their stake however and their liquidity will be placed back on the book when normal trading resumes.


### Penalties

If at any point in time, a liquidity provider has insufficient capital to make the transfers for their mark to market or other settlement movements, and/or margin requirements arising from their orders and open positions, the network will utilise their liquidity provision commitment, held in the _liquidity provider bond account_ to cover the shortfall. The protocol will also apply a penalty proportional to the size of the shortfall, which will be transferred to the market's insurance pool.

Calculating the penalty:

```
bondPenalty = market.liquidity.bondPenaltyParameter ⨉ shortfall
```

The above simple formula defines the amount by which the bond account will be 'slashed', where:

-  `market.liquidity.bondPenaltyParameter` is a network parameter
-  `shortfall` refers to the absolute value of the funds that the liquidity provider was unable to cover through their margin and general accounts, that are needed for settlement (mark to market or [product](./0051-PROD-product.md) driven) or to meet their margin requirements.

**Auctions:** if this occurs at the transition from auction mode to continuous trading, the `market.liquidity.bondPenaltyParameter` will not be applied / will always be set to zero.

The network will:

1. **As part of the normal collateral "search" process:** Access the liquidity provider's bond account to make up the shortfall. If there is insufficient funds to cover this amount, the full balance of the bond account will be used. Note that this means that the transfer request should include the liquidity provider's bond account in the list of accounts to search, and that the bond account would always be emptied before any insurance pool funds are used or loss socialisation occurs.

1. **If there was a shortfall and the bond account was accessed:** Transfer an amount equal to the `market.liquidity.bondPenaltyParameter` calculated above from the liquidity provider's bond account to the market's insurance pool. If there are insufficient funds in the bond account, the full amount will be used and the remainder of the penalty (or as much as possible) should be transferred from the liquidity provider's margin account.

1. Initiate closeout of the LPs order and/or positions as normal if their margin does not meet the minimum maintenance margin level required. (NB: this should involve no change)

1. **If the liquidity provider's orders or positions were closed out, and they are therefore no longer supplying the liquidity implied by their Commitment:** In this case the liquidity provider's Commitment size is set to zero and they are no longer a liquidity provider for fee/reward purposes, and their commitment can no longer be counted towards the supplied liquidity in the market. (From a Core perspective, it is as if the liquidity provider has exited their commitment entirely and they no longer need to be tracked as an LP.)

Note:

* As mentioned above, closeout should happen as per regular trader account (with the addition of cancelling the liquidity provision and the associated LP rewards & fees consequences). So, if after cancelling all open orders (both manually maintained and the ones created automatically as part of liqudity provision commitment) the party can afford to keep the open positions sufficiently collateralised they should be left open, otherwise the positions should get liquidated.

* Bond account balance should never get directly confiscated. It should only be used to cover margin shortfalls with appropriate penalty applied each time it's done. Once the funds are in margin account they should be treated as per normal rules involving that account.

### Bond account top up by collateral search

In the same way that a collateral search is initiated to attempt to top-up a trader's margin account if it drops below the _collateral search level_, the system must also attempt to top up the bond account if its balance drops below the size of the LP's commitment. 

This should happen every time the network is performing a margin calculation and search. The system should prioritise topping up the margin account first, and then the bond account, if there are insufficient funds to do both.


## Network parameters

- `market.liquidity.bondPenaltyParameter` - used to calculate the penalty to liquidity providers when they fail to meet their obligations. 
Valid values: any decimal number `>= 0` with a default value of `0.1`.  
- `market.liquidity.maximumLiquidityFeeFactorLevel` - used in validating fee amounts that are submitted as part of [lp order type](./0038-OLIQ-liquidity_provision_order_type.md). Note that a value of `0.05 = 5%`. Valid values are: any decimal number `>0` and `<=1`. Default value `1`.
- `market.liquidity.stakeToCcySiskas` - used to translate a commitment to an obligation (in siskas). Any decimal number `>0` with default value `1`.


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
- Change of `market.liquidity.stakeToCcySiskas` will change the liquidity obligation hence change the size of the LP orders on the order book. (<a name="0044-LIME-004" href="#0044-LIME-004">0044-LIME-004</a>)
- Change of `market.liquidityProvision.shapes.maxSize` will change the maximum number of entries in the order shape of the LP commitment. If `market.liquidityProvision.shapes.maxSize` is decreased all the LP orders that have already been submitted are unaffected. However any new submissions or amendments must respect the new (lower) maximum. (<a name="0044-LIME-005" href="#0044-LIME-005">0044-LIME-005</a>) 
- Change of `market.liquidity.maximumLiquidityFeeFactorLevel` will change the maximum liquidity fee factor. Any LP orders that have already been submitted are unaffected but any new submission or amendments must respect the new maximum (those that don't get rejected). (<a name="0044-LIME-006" href="#0044-LIME-006">0044-LIME-006</a>)
- If `market.liquidity.stakeToCcySiskas` is set to `0.0` then the [LP provision order](./0038-OLIQ-liquidity_provision_order_type.md) places `0` volume on the book for the LP regardless of the shape submitted and regardless of the `stake` committed. (<a name="0044-LIME-007" href="#0044-LIME-007">0044-LIME-007</a>)
- If `market.liquidity.stakeToCcySiskas` is set to `0.0`, there is [target stake](./0041-TSTK-target_stake.md) of `1000` and there are 3 LPs on the market with stake / fee bid submissions of `100, 0.01`, `1000, 0.02` and `200, 0.03` then the liquidity fee is `0.02`. (<a name="0044-LIME-008" href="#0044-LIME-008">0044-LIME-008</a>)
- Check that bond slashing works with non-default asset decimals, market decimals, position decimals. This can be done by following a similar story to [bond slashing feature test](https://github.com/vegaprotocol/vega/blob/develop/core/integration/features/verified/liquidity-provision-bond-account.feature). Should test at least three different combinations, each decimal settings different to each other. (<a name="0044-LIME-009" href="#0044-LIME-009">0044-LIME-009</a>) 



