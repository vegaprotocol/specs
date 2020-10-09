# Product - Built in _Cash-Settled-Direct-Future-With-Last-Trade-Margining_

## Overview

In the early versions of Vega, Products will be built in. In future version of Vega, participants will be able to propose new Products as part of creating a new market.

This specification gives details for a particular product. It should match terminology from Section 3.2 of the white paper. 

## Guide-level explanation

Every product requires the following:
- valuation function
- payoff function
- relevant inputs for both functions, including any expiry or interim data sources required for settlement at these future points in time.

The valuation function converges to the payoff function as time progresses to settlement.

## Reference-level explanation

### Valuation function for _Cash-Settled-Direct-Future-With-Last-Trade-Margining_

Every Product on Vega includes in its definition, a _valuation function_ which defines all settlement actions, including MTM, closing out, settlement at expiry and any interim settlements for both long and short positions.

`_Cash-Settled-Direct-Future-With-Last-Trade-Margining-for-size=1xlong_.value(time = t, reference-price) = (price(t) - reference-price ) x size`

where:

- `size` is +1 (long)

- `price` is the relevant settlement price:

For [mark to market settlement](./0003-mark-to-market-settlement.md), this is the _mark price_ (the source of which may differ by market and will be defined by a market parameter).
For [settlement at expiry](./0004-settlement-at-instrument-expiry.md) this is a data source that is an input to the product definition.

- `strike` is the entry/trade price (or volume weighted price if abs(`size`) > 1) of the `size` field
- `size` is amount of the open position for which the valuation is being calculated.

### Inputs for the Valuation function

### Expiry prices 


### Interim settlement prices 
When an instrument is created, one of the important inputs is what the `price` is used in the valuation function at expiry of the instrument, and in some cases, at interim periods leading up to expiry. 

On Vega, a market proposal will contain all the relevant inputs for the 

# Pseudo-code / Examples
Example: ETHUSD December 2019 future. 
Maturity: 21st December 2019.
Oracle: "My first decentralized oracle" providing the number of hundreds of cents USD needed to buy 1 ETH (eg 2300000 hundreds of cents = 230 USD). The settlement "currency" is hundreds of cents USD.

Say `mark price = 2300001` but `trade price = 2299999`. 
- A party that is long one unit of this futures contract receives a mark-to-market cashflow of  `2300001 - 2299999 = 2` hundreds of a cent USD. 
- A party that is short 18 units of this futures contract has their account debited for `18 x (2300001 - 2299999) = 18 x 2` hundreds of a cent USD. 

## Acceptance Criteria
It must be possible to:
- set maturity
- set oracle, this sets the reference asset and its units 
- calculate mark-to-market cashflows
- calculate final settlement cashflow