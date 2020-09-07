Feature name: Built in Cash Settled Future Product
Start date: 2019-11-03


# Acceptance Criteria
It must be possible to:
- set maturity
- set oracle, this sets the reference asset and its units 
- calculate mark-to-market cash-flows
- calculate final settlement cash-flow

# Summary
This specification gives details for the cash-settled futures product. It should match terminology from Section 3.2 of the Whitepaper. 

# Guide-level explanation
A future is a simple derivative contract which, in its classical form pays the difference between strike price and final price of a reference asset at a fixed future time (the maturity). The final price of the reference asset will be provided by the oracle. 

On Vega we will implement mark-to-market for cash-settled futures and moreover the strike price
will always match the trade price for this product. 

# Reference-level explanation
To generate mark-to-market cash flow: 
- We need a current "mark price" (e.g. last trade price,  see 0009-mark-price.md). 
- We need the "trade price" (e.g. previous mark price) from when the last time the mark-to-market settlement was run, or if this is the first mark-to-market then it would be the actual trade price
- The mark-to-market cash flow is `[(mark price) - (trade price)]` credited to someone who is long one unit 

Generating the final settlement cashflow is identical except that the `mark price` is now the price provided by oracle for the underlying asset at the time of maturity. The final settlement cash-flow is then `(mark price) - (trade price)`.

# Pseudo-code / Examples
Example: ETHUSD December 2019 future. 
Maturity: 21st December 2019.
Oracle: "My first decentralized oracle" providing the number of hundreds of cents USD needed to buy 1 ETH (eg 2300000 hundreds of cents = 230 USD). The settlement "currency" is hundreds of cents USD.

Say `mark price = 2300001` but `trade price = 2299999`. 
- A party that is long one unit of this futures contract receives a mark-to-market cashflow of  `2300001 - 2299999 = 2` hundreds of a cent USD. 
- A party that is short 18 units of this futures contract has their account debited for `18 x (2300001 - 2299999) = 18 x 2` hundreds of a cent USD. 

