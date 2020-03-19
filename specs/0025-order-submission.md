Feature name: order-submission
Start date: 2020-01-13
Specification PR: https://gitlab.com/vega-protocol/product/

# Summary
To allow traders to interact with the market, they must be able to enter 

# Reference-level explanation
- Orders can be submitted into any market that is not suspended or matured/expired/settled
- Orders will only be accepted if sufficient margin can be allocated (see : [Margin Orchestration](./0010-margin-orchestration.md) and [Margin Calculator](./0019-margin-calculator.md))
- Amendments that change price or increase size will be executed as an atomic cancel/replace (i.e. as if the original order was cancelled and removed from the book and a new order submitted with the modified values - that is, time priority is lost)
- Execution of an order will be stopped and the order cancelled and removed (if on the book) if it is about to match with another order on the book for the same party (that is, execution can proceed up to the point a "wash" trade would be generated  but stopped before that and the order cancelled)


# Test cases
## A completely matching order between the same party is rejected
- On an empty market
- Order 1: Trader A enters a limit SELL order for 1 at price 1
- Order 2: Trader A enters a limit BUY order for 1 at price 1
- Order 1 remains on the book
- Order 2 is rejected

## A partially matching order between the same party is rejected
- On an empty market
- Order 1: Trader A enters a limit SELL order for 1 at price 2
- Order 2: Trader B enters a limit SELL order for 1 at price 1
- Order 3: Trader A enters a limit BUY order for 2 at price 100
- Order 1 remains on the book
- Order 2 is filled
- Order 3 is partially filled, then rejected

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.

# Future Work
This spec currently covers how we deal with orders that could trade between a single trader. This spec will be expanded in future merge requests to cover more aspects of order submission and updating.
