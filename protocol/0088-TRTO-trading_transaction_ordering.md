# Trading Transaction Ordering

In order for an exchange to offer competitive prices for parties arriving and wishing to trade immediately, others have to be willing to place limit orders on the book which will remain there and wait for an incoming order to match with it. These are required for a limit order book to exist (as implied by the name) but expose the party placing the initial limit order to a range of risks, as often the reason these orders will eventually trade is because the price has become unfavourable to the party who placed the order, but they either have not realised or have not had a chance to cancel the order yet. This is often referred to as "toxic flow". Whilst another party obviously gains from this transaction, it is generally acknowledged that the higher a given venue's proportion of toxic flow to more balanced flow, the wider market makers will end up quoting to avoid being the victim of this. As such, exchange and transaction designs which allow for the reduction of this without unfairly impacting other parties using the network may allow for the exchange as a whole to provide traders with better prices than otherwise. This specification covers one such proposed methodology, comprising of a specified ordering of order executions on a given market.

## Execution Ordering

Trading transactions (those which create, update or remove orders of any type on any market) should be executed in a specific way once included in a block.

Chiefly, all transactions which would cancel an order should be executed first, alongside any which would create post-only orders. The ordering of the transactions in this way means that, at the time of each block being created, all parties who are contributing to creating an order book have an opportunity to update their prices prior to anyone who would capitalise on temporary stale prices, regardless of which transaction reached the validator's pre-block transaction pool first. This ordering can still be seen to be a "fair" transaction ordering, as parties cannot take actions which would cause a trade, but only take action to avoid trading at a price they no longer desire (or indeed to improve a price prior to trade-creating transactions' arrival).

Furthermore, transactions which can cause a trade by acting aggressively, such as non-post-only orders and amends, will be delayed by one block prior to execution. This results in the pattern where:

 1. Prior to block N, post only order A and market order B arrive to the chain, these are both included in block N.
 1. When block N is executed, order A takes effect.
 1. Prior to block N + 1, post only order C then market order D and finally a cancellation of order A arrive to the chain, these are both included in block N + 1.
 1. When block N + 1 is executed, order C first takes effect, then the cancellation of order A, then finally market order B.
 1. When block N + 2 is executed, market order D takes effect

## Batch Transactions

Batch transactions, as they contain different order types, must be split apart for the execution of their different components at the specified times. All cancellations, and any post-only order creations, should be separated from amendments and non-post-only orders. The first group will be executed all together within the first section of the inclusion block, whilst the second group will be executed all together within the second section of the block after the inclusion block.
