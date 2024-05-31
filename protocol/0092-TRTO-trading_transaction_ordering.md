# Trading Transaction Ordering

In order for an exchange to offer competitive prices for parties arriving and wishing to trade immediately, others have to be willing to place limit orders on the book which will remain there and wait for an incoming order to match with it. These are required for a limit order book to exist (as implied by the name) but expose the party placing the initial limit order to a range of risks, as often the reason these orders will eventually trade is because the price has become unfavourable to the party who placed the order, but they either have not realised or have not had a chance to cancel the order yet. This is often referred to as "toxic flow". Whilst another party obviously gains from this transaction, it is generally acknowledged that the higher a given venue's proportion of toxic flow to more balanced flow, the wider market makers will end up quoting to avoid being the victim of this. This issue is particularly present when considering a decentralised exchange with a publicly available mempool and higher latency than a centralised exchange, both giving potential toxic flow a significant edge. As such, exchange and transaction designs which allow for the reduction of this without unfairly impacting other parties using the network may allow for the exchange as a whole to provide traders with better prices than otherwise. This specification covers one such proposed methodology, comprising of a specified ordering of order executions on a given market.

## Execution Ordering

Trading transactions (those which create, update or remove orders of any type on any market) should be executed in a specific way once included in a block. This ordering is per-market (inter-market ordering is unspecified). The functionality can be enabled/disabled at a per-market level through market governance. When disabled for a given market, all transactions are sorted as normal with no delays applied.

Chiefly, when enabled all transactions which would cancel an order or create post-only orders should be executed first before transactions which could create trades, within which all cancellations should be executed prior to post-only orders. The ordering of the transactions in this way means that, at the time of each block being created, all parties who are contributing to creating an order book have an opportunity to update their prices prior to anyone who would capitalise on temporary stale prices, regardless of which transaction reached the validator's pre-block transaction pool first. This ordering can still be seen to be a "fair" transaction ordering, as parties cannot take actions which would cause a trade, but only take action to avoid trading at a price they no longer desire (or indeed to improve a price prior to trade-creating transactions' arrival).

Furthermore, transactions which can cause a trade by acting aggressively, such as non-post-only orders and amends, will be delayed by one block prior to execution. This results in the pattern where:

 1. Prior to block N, post only order A and market order B arrive to the chain, these are both included in block N.
 1. When block N is executed, order A takes effect.
 1. Prior to block N + 1, post only order C then market order D and finally a cancellation of order A arrive to the chain, these are both included in block N + 1.
 1. When block N + 1 is executed, the cancellation of order A first takes effect, then the post-only order C, then finally market order B.
 1. When block N + 2 is executed, market order D takes effect

## Batch Transactions

Batch transactions, as they contain different order types, must be handled slightly differently. In the initial version, they will remain to be executed as one unit. When determining execution position, the protocol will inspect the components of the batch transaction. If the transaction contains any order creation messages which are not post-only, or any order amends at all, the entire batch will be delayed as if it were a transaction which could create trades (as some component of it could). If the batch contains exclusively cancellations and/or post-only limit orders then it will be executed in the expedited head-of-block mode specified above. Batches will still be executed all at once as specified, in the order cancellations -> amendments -> creations. The total ordering of executions when including batches should be:

 1. Standalone Cancellations
 1. Batches (containing both cancellations and order creations)
 1. Standalone Creations

## Acceptance criteria

- A batch transaction including only cancellations and/or post-only limit orders is executed at the top of the block alongside standalone post-only limit orders and cancellations. (<a name="0092-TRTO-001" href="#0092-TRTO-001">0092-TRTO-001</a>)
- A batch transaction including either a non-post-only order or an amendment is delayed by one block and then executed after the expedited transactions in that later block. (<a name="0092-TRTO-002" href="#0092-TRTO-002">0092-TRTO-002</a>)
- Cancellation transactions always occur before:
  - Market orders (<a name="0092-TRTO-003" href="#0092-TRTO-003">0092-TRTO-003</a>)
  - Non post-only limit orders (<a name="0092-TRTO-004" href="#0092-TRTO-004">0092-TRTO-004</a>)
  - Order Amends (<a name="0092-TRTO-005" href="#0092-TRTO-005">0092-TRTO-005</a>)
  - post-only limit orders (<a name="0092-TRTO-013" href="#0092-TRTO-013">0092-TRTO-013</a>)
- Post-only transactions always occur before:
  - Market orders (<a name="0092-TRTO-006" href="#0092-TRTO-006">0092-TRTO-006</a>)
  - Non post-only limit orders (<a name="0092-TRTO-007" href="#0092-TRTO-007">0092-TRTO-007</a>)
  - Order Amends (<a name="0092-TRTO-008" href="#0092-TRTO-008">0092-TRTO-008</a>)
- Potentially aggressive orders take effect on the market exactly one block after they are included in a block (i.e for an order which is included in block N it hits the market in block N+1). This is true for:
  - Market orders (<a name="0092-TRTO-009" href="#0092-TRTO-009">0092-TRTO-009</a>)
  - Non post-only limit orders (<a name="0092-TRTO-010" href="#0092-TRTO-010">0092-TRTO-010</a>)
  - Order Amends (<a name="0092-TRTO-011" href="#0092-TRTO-011">0092-TRTO-011</a>)
- An expedited batch transaction is executed after cancellations but before standalone post-only creations (<a name="0092-TRTO-012" href="#0092-TRTO-012">0092-TRTO-012</a>)
- The transaction ordering functionality can be enabled/disabled on a per-market level (<a name="0092-TRTO-015" href="#0092-TRTO-015">0092-TRTO-015</a>)
- With two active markets, with one having transaction ordering enabled and one disabled, transactions are correctly sorted/delayed on the market with it enabled whilst the other has transactions executed in arrival order. (<a name="0092-TRTO-014" href="#0092-TRTO-014">0092-TRTO-014</a>)
