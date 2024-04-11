# Trading Transaction Ordering

In order for an exchange to offer competitive prices for parties arriving and wishing to trade immediately, others have to be willing to place limit orders on the book which will remain there and wait for an incoming order to match with it. These are required for a limit order book to exist (as implied by the name) but expose the party placing the initial limit order to a range of risks, as often the reason these orders will eventually trade is because the price has become unfavourable to the party who placed the order, but they either have not realised or have not had a chance to cancel the order yet. This is often referred to as "toxic flow". Whilst another party obviously gains from this transaction, it is generally acknowledged that the higher a given venue's proportion of toxic flow to more balanced flow, the wider market makers will end up quoting to avoid being the victim of this. As such, exchange and transaction designs which allow for the reduction of this without unfairly impacting other parties using the network may allow for the exchange as a whole to provide traders with better prices than otherwise. This specification covers one such proposed methodology, comprising of a specified ordering of order executions on a given market.

## Execution Ordering

Trading transactions (those which create, update or remove orders of any type on any market) should be executed in a specific way once included in a block. This ordering is per-market (inter-market ordering is unspecified) and should be enableable at a market configuration level (i.e. it can be enabled for some markets and not for others). For a market where this is not enabled, all transactions on the market enact in the order specified in the block itself.

Chiefly, when enabled all transactions which would cancel an order or create post-only orders should be executed first before transactions which could create trades. The ordering of the transactions in this way means that, at the time of each block being created, all parties who are contributing to creating an order book have an opportunity to update their prices prior to anyone who would capitalise on temporary stale prices, regardless of which transaction reached the validator's pre-block transaction pool first. This ordering can still be seen to be a "fair" transaction ordering, as parties cannot take actions which would cause a trade, but only take action to avoid trading at a price they no longer desire (or indeed to improve a price prior to trade-creating transactions' arrival).

Furthermore, transactions which can cause a trade by acting aggressively, such as non-post-only orders and amends, will be delayed by one block prior to execution. This results in the pattern where:

 1. Prior to block N, post only order A and market order B arrive to the chain, these are both included in block N.
 1. When block N is executed, order A takes effect.
 1. Prior to block N + 1, post only order C then market order D and finally a cancellation of order A arrive to the chain, these are both included in block N + 1.
 1. When block N + 1 is executed, order C first takes effect, then the cancellation of order A, then finally market order B.
 1. When block N + 2 is executed, market order D takes effect

## Batch Transactions

Batch transactions, as they contain different order types, must be split apart for the execution of their different components at the specified times. All cancellations, and any post-only order creations, should be separated from amendments and non-post-only orders. The first group will be executed all together within the first section of the inclusion block, whilst the second group will be executed all together within the second section of the block after the inclusion block.

## Acceptance criteria

- Each market has a boolean flag, which can be amended through the normal market update procedure, to enable/disable the trading transaction ordering rules.  (<a name="0088-TRTO-001" href="#0088-TRTO-001">0088-TRTO-001</a>)
- When disabled, all orders for a market are enacted in the block where the transaction is included and in the order they are included in the block (<a name="0088-TRTO-002" href="#0088-TRTO-002">0088-TRTO-002</a>)
- When enabled:
  - Cancellation transactions always occur before:
    - Market orders (<a name="0088-TRTO-003" href="#0088-TRTO-003">0088-TRTO-003</a>)
    - Non post-only limit orders (<a name="0088-TRTO-004" href="#0088-TRTO-004">0088-TRTO-004</a>)
    - Order Amends (<a name="0088-TRTO-005" href="#0088-TRTO-005">0088-TRTO-005</a>)
  - Post-only transactions always occur before:
    - Market orders (<a name="0088-TRTO-006" href="#0088-TRTO-006">0088-TRTO-006</a>)
    - Non post-only limit orders (<a name="0088-TRTO-007" href="#0088-TRTO-007">0088-TRTO-007</a>)
    - Order Amends (<a name="0088-TRTO-008" href="#0088-TRTO-008">0088-TRTO-008</a>)
  - Potentially aggressive orders take effect on the market exactly one block after they are included in a block (i.e for an order which is included in block N it hits the market in block N+1). This is true for:
    - Market orders (<a name="0088-TRTO-009" href="#0088-TRTO-009">0088-TRTO-009</a>)
    - Non post-only limit orders (<a name="0088-TRTO-010" href="#0088-TRTO-010">0088-TRTO-010</a>)
    - Order Amends (<a name="0088-TRTO-011" href="#0088-TRTO-011">0088-TRTO-011</a>)
- When a market is updated to move this setting from disabled to enabled, the transaction ordering changes take place immediately. (<a name="0088-TRTO-012" href="#0088-TRTO-012">0088-TRTO-012</a>)
- When a market is updated to move this setting from enabled to disabled, transactions move back to being purely block-ordered immediately. (<a name="0088-TRTO-013" href="#0088-TRTO-013">0088-TRTO-013</a>)
