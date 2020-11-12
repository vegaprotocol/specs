# Liquidity provision mechanics

The point of liquidity provision on Vega is to incentivise people to place orders on the market that maintain liquidity on the book. This is done via a financial commitment and reward + penalty mechanics, and through the use of a special batch order type that automatically updates price/size as needed to meet the commitment and automatically refreshes its volume after trading to ensure continuous liquidity provision.

Important note on wording:
* liquidity provision / liqudity COMMITMENTs are the amount of stake a liquidity provider places as a bond on the market to earn rewards.
* the COMMITMENT is converted to a liquidity OBLIGATION, measured in siskas.

This is the actual outcome...
* the amount of bond that a liquidity provider actually has, compared to what they COMMITTED is referred to as ACTUAL STAKE.
* the measure of liquidity that a liquidity provider actually supplies is referred to as the SUPPLIED liquidity (measured in siskas).

## Commit liquidity network transaction

Any Vega participant can apply to market make on a market by submitting a transaction to the network which includes the following

1. Market ID
1. COMMITMENT AMOUNT: liquidity commitment amount (specified as a unitless number that represents the amount of settlement asset of the market)
1. FEES: nominated [liquidity fee factor](./0029-fees.md), which is an input to the calculation of taker fees on the market, as per [seeting fees and rewarding lps](0042-setting-fees-and-rewarding-lps.md)
1. ORDERS: a set of _liquidity buy orders_ and _liquidity sell orders_ to meet the liquidity provision obligation, see [MM orders spec](./0038-liquidity-provision-order-type.md).

Accepted if all of the following are true:
- [ ] The participant has sufficient collateral in their general account to meet the size of their nominated commitment amount, as specified in the transaction.
- [ ] The participant has sufficient collateral in their general account to also meet the margins required to support their orders.
- [ ] The market is not in an expired state. It is in a pending or active state, see the [market lifecycle spec](./0043-market-lifecycle.md). In future we will want it to also include when in a proposed state.
- [ ] The nominated fee amount is greater than or equal to zero and less than a maximum level set by a network parameter
- [ ] There is a set of valid buy/sell liquidity provision orders (see [MM orders spec](./0038-liquidity-provision-order-type.md)).

Invalid if any of the following are true:
- [ ] Commitment amount is less than zero (zero is considered to be nominating to cease liquidity provision)
- [ ] Nominated liquidity fee factor is less than zero
- [ ] Acceptance criteria from ORDERS spec is not met.

Engineering notes:
- check transaction, allocation margin could replace "check order, allocate margin"
- some of these checks can happen pre consensus

### Valid submission combinations:

Assume MarketID is always submitted, then a participant can submit the following combinations:
1. A transaction containing all fields specified can be submitted at any time to either create or change a commitment (if commitment size is zero, the orders and fee bid cannot be supplied - i.e. tx is invalid)
1. Any other combination of a subset of fields can be supplied any time a liquidity provider has a non-zero commitment already.

Example: it's possible to amend fee bid or orders individually or together without changing the commitment level.
Example: amending only a commitment amount but retaining old fee bid and orders.


## COMMITMENT AMOUNT

### Processing the commitment
When a commitment is made the liquidity commitment amount is assumed to be specified in terms of the settlement currency of the market.

If the participant has sufficient collateral to cover their commitment and margins for their proposed orders, the commitment amount is transferred from the participant's general account to their (maybe newly created) [liquidity provision bond account](./0013-accounts.md#liquidity-provider-bond-accounts) (new account type, 1 per liquidity provider per market and asset). For clarity, liquidity providers will have a separate [bond account](./0013-accounts.md#trader-bond-accounts) and [bond account](./0013-accounts.md#liquidity-provider-bond-accounts).

- liquidity provider bond account:
    - [ ] Each active market has one bond account per liquidity provider, per settlement asset for that market.
    - [ ] When a liquidity provider transaction is approved, the size of their staked bond is immediately transferred from their general account to this bond account.
    - [ ] A liquidity provider can only prompt a transfer of funds to or from this account by submitting a valid transaction to create, increase, or decrease their commitment to the market, which must be validated and pass all checks (e.g. including those around minimum liquidity commitment required, when trying to reduce commitment)
    - [ ] Collateral withdrawn from this account may only be transferred to either:
      - [ ] The insurance pool of the market (in event of slashing)
      - [ ] The liquidity provider's margin account (during a margin search and mark to market settlement) in the event that they fall below the maintenance level and have zero balance in their general account.
      - [ ] The liquidity provider's general account (in event of liquidity provider reducing their commitment)

### liquidity provider proposes to amend commitment amount
The commitment transaction is also used to amend any aspect of their liquidity provision obligations.
A participant may apply to amend their commitment amount by submitting a transaction for the market with a revised commitment amount. 

`proposed-commitment-variation = new-proposed-commitment-amount - old-commitment-amount`

**INCREASING COMMITMENT**
***Case:*** `proposed-commitment-variation >= 0`
A liquidity provider can always increase their commitment amount as long as they have sufficient collateral in the settlement asset of the market to meet the new commitment amount and cover the margins required.

If they do not have sufficient collateral the transaction is rejected in entirety. This means that any data from the fees or orders are not applied. This means that the  `old-commitment-amount` is retained.


**DECREASING COMMITMENT**

***Case:*** `proposed-commitment-variation < 0`
We to calculate whether the liquidity provider may lower their commitment amount and if so, by how much. To do this we first evaluate the maximum amount that the market can reduce by given the current liquidity demand in the market.

`maximum-reduction-amount = total_stake - target_stake`

where:

`total_stake` is the sum of all stake of all liquidity providers bonded to this market.

`target_stake` is a measure of the market's current stake requirements, as per the calculation in the [target stake](0041-target-stake.md).

`actual-reduction-amount = min(-proposed-commitment-variation, maximum-reduction-amount)`

`new-actual-commitment-amount =  old-commitment-amount - actual-reduction-amount ` 

i.e. liquidity providers are allowed to decrease the liquidity commitment subject to there being sufficient stake committed to the market so that it stays above the market's required stake threshold. The above formulae result in the fact that if `maximum-reduction-amount = 0`, then `actual-reduction-amount = 0` and therefore the liquidity provider is unable to reduce their commitment amount.

When `actual-reduction-amount > 0`:

- [ ] the difference between their actual staked amount and new commitment is transferred back to their general account, i.e.
`transferred-to-general-account-amount =  actual-stake-amount - new-actual-commitment-amount `

Example: if you have a commitment of 500DAI and your bond account only has 400DAI in it (due to slashing - see below), and you submit a new commitment amount of 300DAI, then we only transfer 100DAI such that your bond account is now square.

- [ ] the revised fee amount and set of orders are processed.

When `actual-reduction-amount = 0` the transaction is still processed for any data and actions resulting from the transaction's new fees or order information.



## FEES

### Nominating and amending fee amounts

The network transaction is used by liquidity providers to nominate a fee amount which is used by the network to calculate the [liqudity_fee](./0042-setting-fees-and-rewarding-lps) of the market. Liquidity providers may amend their nominated fee amount by submitting a liquidity provider transaction to the network with a new fee amount. If the fee amount is valid, this new amount is used. Otherwise, the entire transaction is considered invalid.

### How fee amounts are used
The [liqudity_fee](./0029-fees.md) of a market on Vega takes as an input, a [fee factor[liquidity]](./0029-fees.md) which is calculated by the network, taking as an input the data submitted by the liquidity providers in their liquidity provision network transactions (see [this spec](./0042-setting-fees-and-rewarding-lps.md) for more information on the specific calculation).


### Distributing fees between liquidity providers
When calculating fees for a trade, the size of a liquidity provider’s commitment along with when they committed and the market size are inputs that will be used to calculate how the liquidity fee is distributed between liquidity providers. See [setting fees and rewarding lps]](./0042-setting-fees-and-rewarding-lps.md) for the calculation of the split.


## ORDERS

In a market  maker proposal transaction the participant must submit a valid set of orders, comprised of:

1. A set / batch of valid buy orders
1. A set / batch of valid sell orders

Liquidity provider orders are a special order type described in the [liquidity provision orders spec](./0038-market-making-order-type.md). Validity is also defined in that spec. Note, liquidity provider participants can place regular (non liquidity provider orders) and these are considered to be contributing to them meeting their obligation, but they must also have provided the set of valid buy/sell orders as described in the [liquidity provision orders spec](./0038-market-making-order-type.md).

A liquidity provider can amend their orders by providing a new set of liquidity provision orders in the liquidity provider network transaction. If the amended orders are invalid the transaction is rejected, hence the previous set of orders will be retained.

### Checking margins for orders

As pegged orders are parked during an auction are parked and not placed on the book, margin checks will not occur for these orders. This includes checking the orders margin when checking the validity of the transaction so orders are accepted. Open positions are treated the same as any other open positions and their liquidity provider orders are pegged orders and will be treated the same as any other pegged orders.

Engineering notes:
- check that other pegged orders are treated the same


## liquidity provision OBLIGATIONS AND PENALTIES

### Measuring liquidity obligation from commitment
Each liquidity provider has a _liquidity provision obligation_ specified by the network at a point in time and measured in siskas.

The stake they commit implies liquidity obligations. This is derived using a *single* network parameter `stake_to_ccy_siskas` as follows: 
``` lp_liquidity_obligation_in_ccy_siskas = stake_to_ccy_siskas x stake.```
Note here "ccy" stands for "currency" and that the liquidity measure units are actually a currency e.g. ETH or USD. This is because it's basically `volume x probability of trading x price of the volume` and price of the volume is in the said currency.


### How a liquidity provider fulfils their obligation

**During continuous trading:**
A liquidity provider complies with their liquidity provision obligation by:
1. Submitting valid _liquidity provider orders_ in the liquidity provider network transaction.
1. Holding sufficient collateral to meet the usual margin obligations associated with these orders. 

Since liquidity provider orders automatically refresh, a liquidity provider is only non-compliant when they have insufficient capital to meet the margin requirements of these orders.

**During auction:**
- liquidity provider obligation during auction (including market commencement auction):
    - [ ] liquidity provider pegged orders that are placed during an auction call period are parked and reinstated when the limit order book is reinstated.
	- [ ] At conclusion of auction period call period, liquidity provider's pegged orders are reinstated.

### Non-compliance

If at any point in time during continuous trading, the liquidity provider has insufficient capital to meet their margin requirements arising from their liquidity provision orders and open positions, the network will utilise their liquidity provision commitment, held in the liquidity provider's bond account to cover their commitment, and penalise them at a proportional rate.

Let `market-maker-bond-penalty = bond-penalty-parameter x margin-shortfall` be the amount of commitment that has been slashed, where `bond-penalty-parameter` is a network parameter and the `margin-shortfall` refers to the absolute value of the amount of margin that the liquidity provider was unable to cover through their margin and general account.

NOTE: if this occurs at the transition from auction mode to continuous trading, the `market-maker-bond-penalty` will always be set to zero.

We have two cases to consider

***Case: where *** `margin-shortfall > market-maker-commitment-amount - market-maker-bond-penalty`

The network will:
1. Transfer an amount equal to `margin-shortfall` from the liquidity provider's bond account into the liquidity provider's margin account. If there is insufficient funds to cover this amount, transfer the maximum amount it is able to. Note, this can happen as part of the normal margin search steps - i.e. search the liquidity providers' margin account then general account then liquidity provider's bond account.
2. Transfer an amount equal to `market-maker-bond-penalty` from the market's liquidity provider's bond account and add it to the insurance pool subject to condition that if this occurs at the transition from auction mode to continuous trading, the `market-maker-bond-penalty` will always be set to zero. If there is insufficient funds to cover this penalty, search the margin and general accounts for the penalty for any remaining amounts owed.
3. Adjust the liquidity provider's `actual-stake-amount` to match the amount netted from the penalty: `actual-stake-amount = previous-commitment-amount - market-maker-bond-penalty`
4. Initiate closeout of the LPs positions if the `margin-shortfall` and/or the `market-maker-bond-penalty` can't be fulfilled.
5. Adjust the liquidity provider's `market-maker-commitment-amount` to zero (including removing the fee amount and liquidity provision orders as if amending the commitment to zero is accepted) if the liquidity provider undergoes closeout of any positions.

**Bond account top up by collateral search:**
Important: a trader's general account should be periodically searched to top back up its bond account to the level that meets its current commitment.. i.e. so actual stake = commitment. This should happen every time the network is performing a margin calculation / search.


***Case:*** `margin-shortfall <= market-maker-commitment-amount - market-maker-bond-penalty` 



## Network parameters 
- `bond-penalty-parameter` - used to calculate the penalty to liquidity providers when they fail to meet their obligations. 
Valid values: any decimal number `>= 0` with a default value of `0.1`.  
- ~~`market-size-measurement-period` - used in fee splitting~~
- `maximum-liquidity-fee-factor-level` - used in validating fee amounts that are submitted as part of [lp order type](./0038-liquidity-provision-order-type.md). Note that a value of `0.05 = 5%`. Valid values are: any decimal number `>0` and `<=1`. Default value `1`.
- `stake_to_ccy_siskas` - used to translate a commitment to an obligation (in siskas). Any decimal number `>0` with default value `1`.

## What data do we keep relating to liquidity provision?
1. List of all liquidity providers and their commitment sizes and their “equity-like share” for each market [see 0042-setting-fees-and-rewarding-lps](./0042-setting-fees-and-rewarding-lps.md)
1. Liquidity provision orders (probably need to be indexed somewhere in addition to the order book)
1. New account per market holding all committed liquidity provider bonds
1. Actual amount of liquidity supplied (can be calculated from order book, [see 0034-prob-weighted-liquidity-measure](./0034-prob-weighted-liquidity-measure.ipynb))
1. Each liquidity provider's actual bond amount

## Further Acceptance Criteria

- Becoming a liquidity provider:
    - [ ] A network transaction exists that acts as an application for a participant to become a liquidity provider for a specified market.
    - [ ] The application is accepted by the network if both of following are true:
       - [ ] The participant has sufficient collateral in their general account to meet the size of staked bond, specified in their transaction.
       - [ ] The market is active
    - [ ] Any Vega participant can apply to provide liquidity on any market.
    	- When a user has submitted a [Liquidity Provision order](./0038-liquidity-provision-order-type.md), a Bond account is created for that user and for that market
	- Collateral required to maintain the Liquidity Provision Order will be held in the Bond account.
