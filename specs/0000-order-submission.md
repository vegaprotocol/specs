Feature name: order-submission
Start date: 2020-01-13
Specification PR: https://gitlab.com/vega-protocol/product/

# Summary
To allow traders to interact with the market, they must be able to enter 

# Reference-level explanation
- Orders can be submitted into any market that is not suspended or matured/expired/settled
- Orders will only be accepted if sufficient margin can be allocated (see XXX)
- Amendments that change price or increase size will be executed as an atomic cancel/replace (i.e. as if the original order was cancelled and removed from the book and a new order submitted with the modified values - that is, time priority is lost)
ONE OF:
- Orders will be rejected if they could match with any other orders on the book for the same party (that is, even if they would actually match with another order first, they are rejected)
OR: 
- Execution of an orders will be stopped and the order cancelled and removed (if on the book) if it is about to match with another order on the book for the same party (that is, execution can proceed up to the point a "wash" trade would be generated  but stopped before that and the order cancelled)


# Test cases
## A completely matching order between the same party is rejected
- On an empty market
- Trade 1: Trader A enters a limit SELL order for 1 at price 1
- Trade 2: Trader A enters a limit BUY order for 1 at price 1
- Trade 1 remains on the book
- Trade 2 is rejected

## A partially matching order between the same party is rejected
- On an empty market
- Trade 1: Trader A enters a limit SELL order for 1 at price 1
- Trade 2: Trader B enters a limit SELL order for 1 at price 1
- Trade 3: Trader A enters a limit BUY order for 2
- Trade 1 remains on the book
EITHER
- Trade 2 is filled
- Trade 3 is partially filled, then rejected
OR
- Trade 2 is unfilled
- Trade 3 is rejected

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.
