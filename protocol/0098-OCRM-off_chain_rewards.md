# Off-Chain Reward Metrics

## Summary

The Off-Chain Reward Metric feature gives users the ability to configure flexible rewards which pay out based on metric scores calculated off-chain. Scores calculated off-chain must be submitted and agreed upon by a configurable number of specified keys.

To ensure all unique keys calculate and submit identical scores for each party, the recurring transfer will allow metadata to be specified which can be used to store instructions for how metric scores should be calculated. These instructions could for example be a link to public code, a smart-contract address, or text defining simple rules.

## Setting up a recurring transfer

This feature introduces the dispatch metric `DISPATCH_METRIC_OFF_CHAIN_METRIC`. When used, the key proposing/submitting the recurring transfer must specify the following mandatory fields (and optionally specify optional fields):

- `metricSubmissionKeys`: a list of keys which are allowed to submit a transaction containing party metric scores.
- `consensusThreshold`: an integer strictly greater than zero which defines the number of keys which must have submitted identical metrics in order for the values to be considered valid and rewards paid out.
- `metadata` and optional list of Vega MetaData messages.

## Submitting metric scores

At the end of each epoch where rewards would normally be distributed, i.e. when...

```pseudo
(current_epoch - startEpoch) % DispatchStrategy.transferInterval == 0
```

The network should emit an event announcing that it is accepting dispatch metric submission transactions for the relevant transfer for that epochs. Keys included in the transfers `metricSubmissionKeys` will then be able to submit a dispatch metric submission for this transfer and epoch with data including:

- `id`: a string defining the transfer for which we are calculating metrics.
- `epoch`: an integer defining the epoch for which we are calculating metrics.
- `metrics`: a list of `{key, metric}` pairs for all public keys with a metric score (both fields should be strings). Note negative and zero scores are still considered a score and must be submitted as the on-chain distribution mechanics allow for these values.

Once the network receives a dispatch metric submission from a key which is included in the `metricSubmissionKeys` of the relevant transfer, the network will store that data in some structure keyed by submission key, the transfer id, and the calculation epoch. If a party re-submits new data for the same transfer id / epoch, then the network should store the latest submission and discard stale submissions.

## Reaching consensus and distributing rewards

Once the network has received more than `consensusThreshold` identical transactions from valid keys (i.e. `metricSubmissionKeys` specified in the transfer) for a given transfer and epoch pair, then the submitted metrics will be considered valid. At this point the network will no longer accept further transactions for the finalised transfer and epoch pair.

At the end of the epoch in which consensus is reached, the protocol will attempt to distribute rewards, using the accepted metrics, as per the normal distribution mechanics (i.e. reward scaling, reward capping, and distribution strategies must all be adhered too).

Note, rewards for a single recurring transfer **must** be paid out in their scheduled order, rather than the order in which consensus is achieved. For example, if we have a reward that should pay out in epochs 2, 4, and 6, rewards will be paid out in this order regardless of whether consensus was achieved in the order 6, 4, 2. However, for separate recurring transfers funded from the same source account, rewards **must** be paid out in the order in which consensus is achieved.

The above two restrictions ensure where possible participants are always rewarded in order for a single competition, but a single reward not reaching consensus will not block payouts of other rewards.


### Additional considerations

Following section includes a number of considerations for the implementation with respect to existing features:

- when submitting a metric for an AMM, the key of the sub-account should be referenced rather than the key of the primary account.


### Acceptance Criteria

## Creation

- A user creating a reward with the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric must specify at least one `metricSubmissionKeys` for the transaction to be valid.
- A user creating a reward with the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric must specify a `consensusThreshold` strictly greater for the transaction to be valid.
- A user creating a reward with the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric must not specify a `consensusThreshold` greater than the number of specified `metricSubmissionKeys`.
- A user creating a reward with the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric can specify no `metadata` and the transaction will still be considered valid.

## Transactions

- Given a reward with a `start_epoch=1` with no `transfer_interval`. The protocol will emit an event at the end of epoch's `1`, `2` and `3` signifying it is ready to receive  dispatch metric submission transactions for the relevant reward transfer and epoch.
- Given a reward with a `start_epoch=1` with no `transfer_interval`. The protocol will emit an event at the end of epoch's `1`, `3` and `5` signifying it is ready to receive  dispatch metric submission transactions for the relevant reward transfer and epoch.

- A dispatch metric submission specifying a transfer and epoch which the network is not ready to receive will be rejected.
- A dispatch metric submission from a key not listed in the transfers `metricSubmissionKeys` will be rejected as invalid.

- A dispatch metric submission from a key listed in the transfers `metricSubmissionKeys` will be accepted.
- If a valid key has already submitted a dispatch metric submission which has been accepted by the network, if they submit a further transaction whilst the network is still accepting , then the previous submission will be discarded and the latest submission stored against that party.

- A key should be able to submit a transaction with an empty `metrics` field (i.e. no parties to be rewarded).
- A key should be able to submit a transaction with a `metrics` field including values strictly less than zero.
- A key should be able to submit a transaction with a `metrics` field including values equal to zero.
- A key should be able to submit a transaction with a `metrics` field including values strictly greater than zero.

## Consensus

- Given the network is currently ready to receive data for a reward paying out at the end of epoch `1`. If in epoch `2` the network has received less than `consensusThreshold` matching metric transactions, then no rewards will be distributed at the end of epoch `2`.
- Given the network is currently ready to receive data for a reward paying out at the end of epoch `1`. If in epoch `2` the network has received greater than or equal to `consensusThreshold` matching metric transactions, then rewards will be distributed at the end of epoch `2`.

## Distribution

- A reward using the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric and pro-rata distribution strategy will still distribute rewards as per the pro-rata distribution mechanisms (i.e. parties will receive a share of the rewards equal to their submitted metric assuming no other mechanics modifying distributions are active).
- A reward using the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric and rank distribution strategy will still distribute rewards as per the rank distribution mechanisms (i.e. parties will receive a share of the rewards equal to the rank they are placed in by their submitted metric assuming no other mechanics modifying distributions are active).
- A reward using the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric and lottery distribution strategy will still distribute rewards as per the lottery distribution mechanisms (i.e. parties will be randomly assigned a rank and receive rewards based on that rank).

- A reward using the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric will still adhere to reward capping mechanisms if a `cap_reward_fee_multiple` is specified.
- A reward using the `DISPATCH_METRIC_OFF_CHAIN_METRIC` metric will still adhere to reward scaling mechanisms if a `target_notional_volume` is specified.

- Given the network is currently awaiting consensus on metrics for a reward for epochs `1` and `2`. If the network achieves consensus on the metrics for epoch `1` then only the rewards for epoch `1` will be distributed at the next epoch boundary.
- Given the network is currently awaiting consensus on metrics for a reward for epochs `1` and `2`. If the network achieves consensus on the metrics for epoch `2` then no rewards will be distributed will be distributed at the next epoch boundary.
- Given the network is currently awaiting consensus on metrics for a reward for epochs `1` and `2`. If the network achieves consensus on the metrics for epoch `2` and then `1`, rewards will be distributed first for epoch `1` and then `2` at the next epoch boundary.

- Given the network is currently awaiting consensus on metrics for two different rewards funded from the same account (`A` and `B`), `A` waiting for metrics from epoch `1` and `B` awaiting metrics from epoch `2`. If the network achieves consensus on the metrics for reward `B` then they will be distributed at the next epoch boundary.
- Given the network is currently awaiting consensus on metrics for two different rewards funded from the same account (`A` and `B`), `A` waiting for metrics from epoch `1` and `B` awaiting metrics from epoch `2`. If the network achieves consensus on the metrics for reward `B` and then reward `A`, rewards will be distributed first for reward `B` (epoch `2`) and then reward `A` (epoch `1`) at the next epoch boundary.
