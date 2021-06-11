# Spam protection
To operate efficiently, Vega should make an effort to drop transactions that are known not to be useful, without risking dropping valid transactions. To solve this problem, there are a number of mechanisms that build on the existing transaction validation in [0049 - Validate Transactions Preconsensus](./0049-validate-transaction-preconsensus.md):

## 1. Reject transactions from accounts with no balance
- 1.1 All of the actions that a [party](./0017-party.md) can take require [an account balance](./0013-accounts.md) in at least one asset. For example:
  - 1.1.1 [Proposing a market](./0028-governance.md) requires collateral for the [Liquidity Commitment](./0044-lp-mechanics.md#orders-buy-shapesell-shape), and [governance asset balance](./0028-governance.md)
  - 1.1.2 [Voting on a proposal](./0028-governance.md) requires a [governance asset balance](./0028-governance.md)
  - 1.1.3 [Placing an order](./0011-check-order-allocate-margin.md#outline) requires collateral
  - 1.1.4 [Cancelling an order](./0033-cancel-orders.md) means the user previously had collateral, and will have a margin account balance
  - 1.1.5 [Amending an order](./0033-cancel-orders.md) also the user have a margin account balance
- 1.2 Therefore we can use the existing of accounts as an indicator that the party has previously participated productively in the network. 
- 1.3 If they have no accounts, they therefore have not, and their transaction can be dropped.

## 2. Vote spam prevention

## 3. Rate limiting on the nodes
- 3.1 A validator node can keep a running total of the transactions for each party, across a number of blocks
- 3.2 Through configuration, a maximum number of transactions for that block-window, for each party, can be set
- 3.3 Any transactions beyond that maximum will be rejected
- 3.4 This should be replaced by [4. client side proof of work](#4.-rate-limiting-through-client-side-proof-of-work) when it is specified

## 4. Rate limiting through client-side Proof Of Work

