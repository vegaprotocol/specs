Feature name: Order Submission

# Summary
To allow traders to interact with the market, they must be able to enter an order

# Reference-level explanation
- Orders can be submitted into any market that is active - i.e not in [a protective auction](./0026-auctions.md) or [matured/expired/settled](./0043-market-lifecycle.md).
- Orders will only be accepted if sufficient margin can be allocated (see : [Margin Orchestration](./0010-margin-orchestration.md) and [Margin Calculator](./0019-margin-calculator.md))
- Amendments that change price or increase size will be executed as an atomic cancel/replace (i.e. as if the original order was cancelled and removed from the book and a new order submitted with the modified values - that is, time priority is lost)
- Execution of an order during continuous trading will be stopped and the order cancelled and removed (if on the book) if it is about to match with another order on the book for the same party (that is, execution can proceed up to the point a "wash" trade would be generated but stopped before that and the order cancelled)
- Orders may be fractional in size with the maximum number of decimal places allowable being the `Position Decimal Places` specified in the [Market Framework](0001-market-framework.md), and any order containing more precision that this being rejected. (NB: orders may end up being specified as integers similar to how prices are, in which case this does not apply and 1 == the smallest increment given the configured position d.p.s for the market).



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
- Order 3 is partially filled, then set to status PARTIALLY_FILLED

# Acceptance Criteria
- [ ] An order's size must be valid according to the [./0052-fractional-orders-positions.md](Fractional Order Size spec) 
- [ ] Margin will taken before the order is entered in to the book
  - [ ] If sufficient margin cannot be reserved, the order will have a status of REJECTED
# Future Work
This spec currently covers how we deal with orders that could trade between a single trader. This spec will be expanded in future merge requests to cover more aspects of order submission and updating.
