# Market maker mechanics

The point of market making on Vega is to incentivise people to place orders on the market that maintain liquidity on the book. This is done via a financial commitment and reward + penalty mechanics, and through the use of a special batch order type that automatically updates price/size as needed to meet the commitment and automatically refreshes its volume after trading to ensure continuous liquidity provision.

Important note on wording:
* market making / liqudity COMMITMENTs are the amount of stake a market maker places as a bond on the market to earn rewards.
* the COMMITMENT is converted to a liquidity OBLIGATION, measured in siskas.

This is the actual outcome...
* the amount of bond that a market maker actually has, compared to what they COMMITTED is referred to as ACTUAL STAKE.
* the measure of liquidity that a market maker actually supplies is referred to as the SUPPLIED liquidity (measured in siskas).

## Commit liquidity network transaction

Any Vega participant can apply to market make on a market by submitting a transaction to the network which includes the following

1. Market ID
1. COMMITMENT AMOUNT: liquidity commitment amount (specified as a unitless number that represents the amount of settlement asset of the market)
1. FEES: nominated [liquidity fee factor](./0029-fees.md).
1. ORDERS: a set of _liquidity buy orders_ and _liquidity sell orders_ to meet the market making obligation (see spec []())

Accepted if all of the following are true:
- [ ] The participant has sufficient collateral in their general account to meet the size of their nominated commitment amount, as specified in the transaction.
- [ ] The participant has sufficient collateral in their general account to also meet the margins required to support their orders.
- [ ] The market is not in a closed or expired state. It is in a proposed, pending or active state (TODO: link to market lifecycle spec)
- [ ] The nominated fee amount is greater than or equal to zero and less than a maximum level set by a network parameter
- [ ] There are a set of valid buy/sell liquidity provision orders (see MM orders spec)       

Invalid if any of the following are true:
- [ ] Liquidity commitment amount is less than or equal to zero
- [ ] Nominated liquidity fee factor is less than zero
- [ ] Acceptance criteria from ORDERS spec is not met.

Engineering notes:
- check transaction, allocation margin could replace "check order, allocate margin"
- some of these checks can happen pre consensus

### Valid submission combinations:

Assume MarketID is always submitted, then a participant can submit the following combinations:
1. A transaction containing all fields specified can be submitted at any time to either create or change a commitment (if commitment size is zero, the orders and fee bid cannot be supplied - i.e. tx is invalid)
1. Any other combination of a subset of fields can be supplied any time a market maker has a non-zero commitment already. If commitment is set to zero, it must be the only field supplied (otherwise tx is invalid).

Example: it's possible to amend fee bid or orders individually or together without changing the commitment level.


## COMMITMENT AMOUNT

### Processing the commitment
When a commitment is made the liquidity commitment amount is assumed to be specified in terms of the settlement currency of the market.

If the participant has sufficient collateral to cover their commitment and margins for their proposed orders, this amount is transferred from the participant's general account to their market making bond account (new account type, 1 per market maker per market).

- Market maker bond account:
	- [ ] Each active market has one bond account per settlement asset for that market.
    - [ ] When a market maker is approved, the size of their staked bond is immediately transferred from their general account to this bond account.
    - [ ] Only the network may withdraw collateral from this account.
    - [ ] Collateral withdrawn from this account may only  be transferred to either:
      - [ ] The insurance pool of the market (in event of slashing)
      - [ ] The market maker's margin account (during a margin search)
      - [ ] The market maker's general account (in event of market maker reducing their commitment)

### Market maker proposes to amend commitment amount
The commitment transaction is also used to amend any aspect of their market making obligations.
A participant may apply to amend their commitment amount by submitting a transaction for the market with a revised commitment amount. 

`proposed-commitment-variation = new-proposed-commitment-amount - old-commitment-amount`

**INCREASING COMMITMENT**
***Case:*** `proposed-commitment-variation >= 0`
A market maker can always increase their commitment amount as long as they have sufficient collateral in the settlement asset of the market to meet the new commitment amount and cover the margins required.

If they do not have sufficient collateral:
    - [ ] the previous market making commitment is retained
    - [ ] any other details contained within the new transaction is ignored by the network, i.e.
        - [ ] the new fee bid is ignored
        - [ ] the new market maker orders are ignored


**DECREASING COMMITMENT**
***Case:*** `proposed-commitment-variation < 0`
We to calculate whether the market maker may lower their commitment amount and if so, by how much. To do this we first evaluate the maximum amount that the market can reduce by given the current liquidity demand in the market.

`maximum-reduction-amount-market = max(1/siskas_to_bond_in_asset_X x (total-market-making-liquidity - (c_2 x liquidity-demand-estimate)), 0)`

where:

`total-market-making-liquidity` is the sum of all market making obligations [TODO: LINK TO BELOW] that the market has, measured in siskas and using the previous-commitment-amount for the proposing market maker.

`liquidity-demand-estimate` is a measure of the market's current liquidity requirements, as per the calculation in the [liquidity monitoring spec](0035-liquidity-monitoring.md).

`actual-reduction-amount = min (abs(proposed-reduction-amount), maximum-reduction-amount-market`

`new-actual-commitment-amount =  old-commitment-amount - actual-reduction-amount ` 

i.e. market makers are allowed to decrease the liquidity commitment subject to there being sufficient liquidity committed to the market so that it stays above the market's minimum liquidity threshold. The above formulae result in the fact that if `maximum-reduction-amount = 0`, then `actual-reduction-amount = 0` and therefore the market maker is unable to reduce their commitment amount.

When `actual-reduction-amount > 0`:

- [ ] the difference between their actual staked amount and new commitment is transferred back to their general account, i.e.
`transferred-to-general-account-amount =  actual-stake-amount - new-actual-commitment-amount `

Example: if you have a commitment of 500DAI and your bond account only has 400DAI in it (due to slashing - see below), and you submit a new commitment amount of 300DAI, then we only transfer 100DAI such that your bond account is now square.

- [ ] the revised fee amount and set of orders are processed.

When `actual-reduction-amount = 0`:
    - [ ] the previous market making commitment is retained
    - [ ] any other details contained within the new transaction is ignored by the network, i.e.
        - [ ] the new fee bid is ignored
        - [ ] the new market maker orders are ignored


## FEES

### Nominating and amending fee amounts

The network transaction is used by market makers to nominate a fee amount which is used by the network to calculate the [liqudity_fee](./0029-fees.md) of the market.
- [ ] A nominated fee amount must be greater than or equal to zero. The units of the fee amount are a percentage. A number greater than 1 is permitted.
- [ ] If nominated fee amount is malformed or less than zero, the network should assign a default amount of zero.

Market makers may amend their nominated fee amount by submitting a market maker transaction to the network with a new fee amount. If the fee amount is valid, this new amount is used. Otherwise, the nominated fee amount is set to zero, as per above criteria.

### How fee amounts are used
The [liqudity_fee](./0029-fees.md) of a market on Vega takes as an input, a [fee factor[liquidity]](./0029-fees.md) which is calculated by the network, taking as an input the data submitted by the market makers in their market making network transactions (see [this spec]() for more information on the specific calculation).


### Distributing fees between market makers
When calculating fees for a trade, the size of a market maker’s commitment along with when they committed and the market size are inputs that will be used to calculate how the liquidity fee is distributed between market makers. See [this spec]() for the calculation of the split.


## ORDERS

In a market  maker proposal transaction the participant must submit a valid set of orders, comprised of:

1. A set of valid buy orders
1. A set of valid sell orders

Market maker orders are a special order type described in the [market maker order spec](). Validity is also defined in that spec.


A market maker can amend their orders by providing a new set of orders in the market maker network transaction. If the amended orders are invalid, the previous set of orders will be retained.

### Checking margins for orders

As pegged orders are parked during an auction are parked and not placed on the book, margin checks will not occur. This includes checking the orders margin when checking the validity of the transaction.

Engineering notes:
- check that other pegged orders are treated the same


## MARKET MAKING OBLIGATIONS AND PENALTIES

### Measuring liquidity obligation from commitment
Each market maker has a _market making obligation_ specified by the network at a point in time and measured in siskas.

The liquidity obligations they make (in siskas) is converted from the commitment amount using, a per-asset network parameter `siskas_to_bond_in_asset_X` as follows: 
``` mm_liquidity_obligation = liquidity_commitment x siskas_to_bond_in_asset_X.```


### How a market maker fulfils their obligation

**During continuous trading:**
A market maker complies with their market making obligation by:
1. Submitting valid _market maker orders_ in the market maker network transaction.
1. Holding sufficient collateral to meet the usual margin obligations associated with these orders. 

Since market maker orders automatically refresh, a market maker is only non-compliant when they have insufficient capital to meet the margin requirements of these orders.

**During auction:**
- Market maker obligation during auction (including market commencement auction):
	- [ ] Market makers are not required to place orders during an auction period.
    - [ ] Market maker orders that are placed during an auction call period are parked and reinstated when the limit order book is reinstated.
	- [ ] At conclusion of auction period call period, market makers obligations are reinstated.

### Non-compliance

If at any point in time during continuous trading, the market maker has insufficient capital to meet their margin requirements arising from their market making orders and open positions, the network will utilise their market making commitment, held in the market maker's bond account to cover their commitment, and penalise them at a proportional rate.

Let `market-maker-bond-penalty = bond-fine-parameter * margin-shortfall` be the amount of commitment that has been slashed, where `bond-fine-parameter` is a network parameter and the `margin-shortfall` refers to the absolute value of the amount of margin that the market maker was unable to cover through their margin and general account.

NOTE: if this occurs and the transition from auction mode to continuous trading, the `market-maker-bond-penalty` will always be set to zero.

Note: in future versions, the degree to which a market maker has met their obligation may be measured over a rolling time period (specified by a network parameter, initially set to 24 hours) and calculated as an average of their (attained outcome - obligation). The penalty would then be proportional to the amount of failure and the amount of time in breach.

In the following cases, we assume that the `market-maker-bond-penalty` is not available collateral able to be utilised to cover the shortfalls of the market maker.

***Case:*** `margin-shortfall > market-maker-commitment-amount - market-maker-bond-penalty` 

In this case when the margin is evaluated the market maker will be distressed and placed into position resolution.

***Case:*** `margin-shortfall <= market-maker-commitment-amount - market-maker-bond-penalty` 

The network will:
1. Transfer an amount equal to `margin-shortfall` from the market maker's bond account into the market maker's margin account. If there is insufficient funds to cover this amount, transfer the maximum amount it is able to. Note, this can happen as part of the normal margin search steps - i.e. search the market makers' margin account then general account then market maker's bond account.
1. Transfer an amount equal to `market-maker-bond-penalty` from the market's market maker's bond account and add it to the insurance pool. If there is insufficient funds to cover this penalty, search the margin account for the penalty for any remaining amounts owed.
1. Adjust the market maker's `actual-stake-amount` to match the amount netted from the penalty: `actual-stake-amount = previous-commitment-amount - market-maker-bond-penalty`
1. Adjust the market maker's `market-maker-commitment-amount` to zero (including removing the fee amount and market making orders as if amending the commitment to zero is accepted) if the market maker undergoes position resolution.

**Bond account top up by collateral search:**
Important: a trader's general account should be periodically searched to top back up its bond account to the level that meets its current commitment.. i.e. so actual stake = commitment. This should happen every time the network is performing a margin calculation / search.

## Network parameters 
`bond-fine-parameter` - used to calculate the penalty to market makers when they fail to meet their obligations.
`market-size-measurement-period` - used in fee splitting
`maximum-liquidity-fee-factor-level` - used in validating fee amounts

## What data do we keep relating to market making?
1. List of all market makers and their commitment sizes and their “equity-like share” for each market (https://github.com/vegaprotocol/product/pull/323/files)
1. Liquidity provision orders (probably need to be indexed somewhere in addition to the order book)
1. New account per market holding all committed market maker bonds
1. Actual amount of liquidity supplied (can be calculated from order book “0034-prob-weighted-liquidity-measure.ipynb”)
1. The market size (this will be something like the average trading volume (trade value for fee purposes - see fees spec, for futures this is notional) per 24 hours during a period defined as a network parameter)
1. Each market maker's actual bond amount


## Further Acceptance Criteria

- Becoming a market maker:
    - [ ] A network transaction exists that acts as an application for a participant to become a market maker for a specified market.
    - [ ] The application is accepted by the network if both of following are true:
       - [ ] The participant has sufficient collateral in their general account to meet the size of staked bond, specified in their transaction.
       - [ ] The market is active
    - [ ] Any Vega participant can apply to market make on a market.