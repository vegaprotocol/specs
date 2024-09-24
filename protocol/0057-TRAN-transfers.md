# Transfers

This spec introduces a mechanism to transfer funds from one account to another, initiated explicitly by a user of the Vega network.
These transfers are not to be confused with the internal concept of transfers which results from event happening inside the protocol, which are covered in spec [0005-COLL](./0005-COLL-collateral.md).

Allowing users to initiate transfers allows for the following capabilities:

- A user can transfer funds from a public key A to a public key B.
- A user can transfer governance tokens from general account to another key's general account.
- A user can transfer governance tokens from and to a locked account used for staking [LOCKED_FOR_STAKING](./0059-STKG-simple_staking_and_delegating.md).


- A user can set up a recurring transfer.
- A user can set up a recurring transfer to one or more [reward accounts](0056-REWA-rewards_overview.md#reward-accounts).

## Limits

Transfer can only be initiated by a party using their own funds from [accounts](./0013-ACCT-accounts.md) that they are in control of:

Here's the list of accounts types from which a user send funds from:

- [GENERAL](0013-ACCT-accounts.md)
- [LOCKED_FOR_STAKING](./0059-STKG-simple_staking_and_delegating.md)

Here's the list of accounts types into which funds can be sent:

- [GENERAL](0013-ACCT-accounts.md)
- [LOCKED_FOR_STAKING](0059-STKG-simple_staking_and_delegating.md)
- [REWARD_POOL](0056-REWA-rewards_overview.md#rewards-accounts) (only by the special recurring transfer to reward accounts transfer type)
- [ON_CHAIN_TREASURY](0055-TREA-on_chain_treasury.md#network-treasury)

## Delayed transfer

The system should be able to delay transfer. Such feature would be useful in the context of distributing token related to incentives for example.
In order to do this the request for transfer should contain a field indicating when the destination account should be credited. The funds should be taken straight away from the origin account, but distributed to the destination only once the time is reached.

## Spam protection

In order to prevent the abuse of user-initiated transfers as spam attack there will be:

- `spam.protection.maxUserTransfersPerEpoch` that will limit the number of transfers that a user can initiate within an epoch, see [network parameter](#network-parameters).

## Minimum transfer amount

This is controlled by the `transfer.minTransferQuantumMultiple` and quantum specified for the [asset](0040-ASSF-asset_framework.md).
The minimum transfer amount is `transfer.minTransferQuantumMultiple x quantum`.

If a user is transferring funds from a vested account, if their balance (expressed in quantum) is less than the minimum amount, they should be able to transfer the full balance (note, transferring less than the full balance is not permitted).

## Recurring transfers

A party can also setup recurring transfers which will happen at the end of every epoch, before the next epoch begins.
These transfers happen at the end of the epoch, but before processing any rewards.
Trading or staking rewards to be received for that epoch will not be available to be used by a recurring transfer.
Recurring transfers to reward accounts will happen before rewards are paid out.

Recurring transfers (including to reward accounts) are processed in order they were created.
This means that in order for recurring transfer B to make use of funds that would received from recurring transfer A, A must have been created before B.

It's possible to cancel a recurring transfer.
It's not possible to amend a transfer, a party will need to cancel the transfer and submit a new one in this case.

A party is limited to a maximum of 1 running recurring transfer to any given account.
E.g: say we have accounts A1, A2, A3 and party1 which controls A1.
Party1 can have a recurring transfer rt1 from A1 to A2 and another one (call it rt2) from A1 to A3. However it is not allowed to set up a recurring transfer rt3 from A1 to A2 with different amounts.

A recurring transfers needs to contain this specific information:

- start amount uint specifying the amount (interpreted according to the number of decimals specified by the [asset](0040-ASSF-asset_framework.md)).
- start epoch: at the end of this epoch the first recurring transfer will be made between
- end epoch (optional): at the end of this epoch the last recurring transfer will be made between, optional. If not specified the transfer run until cancelled (by its creator or by the network as described below).
- factor, decimal > 0.0 (a factor used with the amount specified for the transfer).

The amount paid at the end of each epoch is calculated using the following formula:

$$
\text{amount} = \text{start amount} \cdot \text{factor}^{(\text{current epoch} - \text{start epoch})}
$$

If insufficient funds are present in the source account at the time a transfer is initiated by the network, the whole recurring transfer is cancelled.
If the `amount` is less than `transfer.minTransferQuantumMultiple x quantum` then the recurring transfer is cancelled.

## Recurring transfers to reward accounts

Read this section alongside the [rewards](./0056-REWA-rewards_overview.md) specification.

When funding a reward account with a recurring transfer, the reward account funded is the hash of the fields in the recurring transfer specific to funding reward accounts (listed below).

When transferring to a reward account, the transaction must include the following:

- `reward metric` — the type of reward (see [rewards](./0056-REWA-rewards_overview.md))
- `reward metric asset` — (the settlement asset of all markets that will be in scope for the transfer)
- `market scope` — a subset of markets in which parties are eligible to be rewarded from this transfer.
  - If the market scope is not defined / an empty list, it is taken as all the markets that settle in the reward metric asset.

A party can further control their recurring transfer funding the reward pool by defining the entities which are within scope. Entities within scope can be either individual parties or [teams](./0083-RFPR-on_chain_referral_program.md#glossary). When scoping individuals, a subset of keys can be detailed, and when scoping teams a specific set of team ids can be detailed.

To support entity scoping, the transaction include the following fields:

- `entity scope` - mandatory enum which defines the entities within scope.
  - `ENTITY_SCOPE_INDIVIDUALS` - the rewards must be distributed directly amongst eligible parties
  - `ENTITY_SCOPE_TEAMS` - the rewards must be distributed amongst directly eligible teams (and then amongst team members)
- `individual scope` - optional enum if the entity scope is `ENTITY_SCOPE_INDIVIDUALS` which defines the subset of individuals which are eligible to be rewarded.
  - `INDIVIDUAL_SCOPE_ALL` - all parties on the network are within the scope of this reward
  - `INDIVIDUAL_SCOPE_IN_TEAM` - all parties which are part of a team are within the scope of this reward
  - `INDIVIDUAL_SCOPE_NOT_IN_TEAM` - all parties which are not part of a team are within the scope of this reward
  - `INDIVIDUAL_SCOPE_AMM` - all keys representing AMM parties (i.e. excluding those directly controlled by parties) are within the scope of this reward
- `team scope` - optional list if the reward type is `ENTITY_SCOPE_TEAMS`, field allows the funder to define a list of team ids which are eligible to be rewarded from this transfer
- `staking_requirement` - the required minimum number of governance (e.g. VEGA) tokens staked for a party to be considered eligible. Defaults to `0`.
- `notional_time_weighted_average_position_requirement` - the required minimum notional time-weighted averaged position required for a party to be considered eligible. Defaults to `0`.
- `eligible keys` - optional list of keys who are eligible to participate in the game. If no list is specified, all parties are eligible, if a list is specified, only parties included in the list will have a score. If specified the list must have more than one key.

A party should be able to configure the distribution of rewards by specifying the following fields:

- `window_length` - the number of epochs over which to evaluate the reward metric. The value should be limited to 100 epochs.
- `transfer_interval` - number of epochs between transfers, i.e. when 4, funds will be transferred every 4 epochs with the first transfer occurring 4 epochs after the transaction is processed. Must be an integer strictly greater than `0` and less than `100` (this ceiling is for performance reasons and matches the limit on the `window_length` field).
- `lock_period` - the number of epochs after distribution to delay [vesting of rewards](./0085-RVST-rewards_vesting.md#vesting-mechanics) by.
- `cap_reward_fee_multiple` [optional] - if set, the actual amount of reward transferred to each public key during distribution for this transfer will be `min(calculated_reward_in_quantum, cap_reward_fee_multiple × feed_paid_since_last_payout)` (fees paid since last payout is akin to checking the total fees paid over the last `transfer_interval` epochs). When calculating how much of the reward each one is getting, if some is left from the applied cap, we recalculate on the remaining balance only for parties that have not reached their cap until the leftover is less than 1 reward asset unit or the maximum rounds of recalculation is 10. If all keys are capped (i.e. the total amount of the transfer cannot be be sent to eligible keys without breaching the cap) then the remaining balance must be left in the reward pool and included in the distribution in future epochs. If this occurs, and the total transferred in a given epoch, this does not affect the size of the next iteration, which proceeds as normal (including decay factors etc.) as if the full transfer has been made.
Here, `feed_paid_since_last_payout` are the total trading fees paid by a party (arising from `infrastructure_fee` paid, `maker_fee` paid plus `liquidity_fee` paid, since the last payout and expressed in quantum units).
- `sla_parameters` - to support the [Liquidity SLA Metric](./0056-REWA-rewards_overview.md#liquidity-sla-metric), if the distribution metric is `DISPATCH_METRIC_LIQUIDITY_SLA`, SLA parameters must be provided for the network to evaluate each LPs liquidity performance. These parameters are the same as defined in the [liquidity mechanisms specification](./0095-LIQM-liquidity_mechanisms.md#volume-of-notional).
- `target_notional_volume` - an optional integer greater than zero which defines the volume required for the full amount of funds to be distributed as rewards (see [reward scaling](./0056-REWA-rewards_overview.md#reward-scaling)). It is represented in the decimals of the dispatch asset.
- `distribution_strategy` - enum defining which [distribution strategy](./0056-REWA-rewards_overview.md#distributing-rewards-between-entities) to use.
  - `DISTRIBUTION_STRATEGY_PRO_RATA` - rewards should be distributed among entities [pro-rata](./0056-REWA-rewards_overview.md#distributing-pro-rata) by reward-metric.
  - `DISTRIBUTION_STRATEGY_RANK` - rewards should be distributed among entities [based on their rank](./0056-REWA-rewards_overview.md#distributing-based-on-rank) when ordered by reward-metric.
  - `DISTRIBUTION_STRATEGY_RANK_LOTTERY` - rewards should be distributed among entities [based on randomly assigned rank](./0056-REWA-rewards_overview.md#distributing-based-on-lottery).
- `rank_table` - if the distribution strategy is `DISTRIBUTION_STRATEGY_RANK` or `DISTRIBUTION_STRATEGY_RANK_LOTTERY`, an ordered list dictionary defining the rank bands and share ratio for each band should be specified. Note, the `start_rank` values must be integers in an ascending order and the table can have strictly no more than 500 rows.

    ```pseudo
        rank_table = [
            {"start_rank": 1, "share_ratio": 10},
            {"start_rank": 2, "share_ratio": 5},
            {"start_rank": 4, "share_ratio": 2},
            {"start_rank": 10, "share_ratio": 1},
            {"start_rank": 20, "share_ratio": 0},
        ]
    ```

- At the end of the epoch when the transfer is about to be distributed, it first calculates the contribution of each market to the sum total reward metric for all markets in the `market scope` and then distributes the transfer amount to the corresponding accounts of the markets pro-rata by their contribution to the total.

Where the reward metric type is "market creation rewards", it is important that no market creator will receive more than one market creation reward paid in the same asset from the same source account (reward funder).
Therefore:

- For each market (for which the proposed may be paid rewards), a list of [market scope, source account, reward asset] combinations that have already rewarded the proposer of that market for its creation is maintained.
- Any markets in the market scope list for a recurring transfer that are also in the above list as having been rewarded with funds paid in the same reward asset, transferred to the reward account from the same source account, and for the same market scope, will **have their total metric set to zero** (so they will not be rewarded).

For example, a recurring transfer is defined as follows:

```proto
Reward asset: $VEGA
Reward metric: taker paid fees
Reward metric asset: USDT
Reward markets: [market1, market2, market3]

In market1 200 USDT taker fees were paid
In market2 600 USDT taker fees were paid
In market3 1200 USDT taker fees were paid
In market4 5000 USDT taker fees were paid (note that this market is not defined in the scope of the transfer)

If the transfer amount is 1000 $VEGA, then
100 $VEGA would be transferred to the reward account of market1 for $VEGA
300 $VEGA would be transferred to the reward account of market2 for $VEGA,
600 $VEGA would be transferred to the reward account of market3 for $VEGA
```

Note: if there is no market with contribution to the reward metric - no transfer is made.

## Fees

A fee is taken from all transfers (except transfers from a vested account to a general account held by the same key), and paid out to validators in a similar manner to the existing [infrastructure fees](0061-REWP-pos_rewards.md). For recurring transfers, the fee is charged each time the transfer occurs.

The fee is determined by the `transfer.fee.factor` and is subject to a cap defined by the multiplier `transfer.fee.maxQuantumAmount` as specified in the network parameters, which governs the proportion of each transfer taken as a fee.

As such, the transfer fee value used will be: `min(transfer amount x transfer.fee.factor, transfer.fee.maxQuantumAmount x quantum)`, `quantum` is for asset
The fee is taken from the transfer initiator's account immediately on execution, and is taken either:

1. on top of the total amount transferred,
2. subtracted from the amount being transferred (so that the target account gets `amount-fees` amount).

This should be governed by an optional parameter with the default option being that fees are added on top of the total amount transferred.

It is [paid in to the infrastructure fee pool](./0029-FEES-fees.md#collecting-and-distributing-fees).
Fees are charged in the asset that is being transferred.

Fee are primarily a spam-protection mechanism, so for accounts generating "useful activity" discounts apply.

### Transfer fee discounts

Let `D` stand for `transfer.feeDiscountDecayFraction`. This is a network parameter that specifies the how cumulated trading fees decay for the purpose of being used to do transfer-fee-free transfers. Minimum value is `0`, maximum value is any decimal strictly less than `1` and default it `0.5`.
Let `M` stand for network parameter `transfer.feeDiscountMinimumTrackedAmount`. Minimum value is `0`, there is no maximum beyond that dictated by the data type used and the default is `0.001`.

For each party and for each asset store the an amount which tracks all trading fees paid and received by the party with transfer fees subtracted and the amount decayed as specified below.

For each key for each asset assume you store a value denoted `c`.
During the epoch `k`:

- if the party makes a transfer and `f` would be the theoretical fee the party should pay then the fee on the transfer that is actually charged is `f_actual = -min(f-c,0)`. The system subsequently updates `c <- max(0,c-f)`.

At the end of epoch `k`:

1. update `c <- c x D`, i.e. apply the decay factor `D`

1. update `c <- c + all_trading_fees_for_trades_involved_in`, where `all_trading_fees_for_trades_involved_in` are the cumulated trading fees paid by the aggressive party (taker fees) but also cumulated (with a +sign) the trading fees result from any trade in which the party was involved as the passive party (i.e. their limit order got lifted).

1. if `c` is less than `M x quantum` (where quantum is the asset quantum) then set `c <- 0`.

We need appropriate APIs to enable the frontend to display the amount eligible for fee-free transfers / correctly display the fee on any transfer a party is proposing.
If `c=0` then such amount is `0`. Is `c>=transfer.fee.maxQuantumAmount x quantum` then such amount is infinity. Otherwise the amount is `c/transfer.fee.factor`. In the case of recurring transfers this is only applied to the first transfer.

## Proposed command

This new functionality requires the introduction of a new command in the transaction API. The payload is as follows:

```proto
message Transfer {
  // The account type from which the funds of the party
  // should be taken
  vega.AccountType from_account_type = 1;
  // The public key of the destination account
  string to = 2;
  // The type of the destination account
  vega.AccountType to_account_type = 3;
  // The asset
  string asset = 4;
  // The amount to be taken from the source account
  string amount = 5;
  // The reference to be attached to the transfer; max lenght 100 characters
  string reference = 6;

  // Specific details of the transfer
  oneof kind {
    OneOffTransfer one_off = 101;
    RecurringTransfer recurring = 102;
  }

  // Fees added on top or subtracted
  oneof fees {
    OnTop on_top = 201; (default)
    Subtracted subtracted = 202;
  }
}

// Specific details for a one off transfer
message OneOffTransfer {
  // A unix timestamp in second. Time at which the
  // transfer should be delivered in the to account
  int64 deliver_on = 1;
}

// Specific details for a recurring transfer
message RecurringTransfer {
  // The first epoch from which this transfer shall be paid
  uint64 start_epoch = 1;
  // The last epoch at which this transfer shall be paid
  vega.Uint64Value end_epoch = 2;
  // factor needs to be > 0
  string factor = 3;
}

message CancelTransfer {
  // The ID of the transfer to cancel
  string transfer_id = 1;
}
```

## Network Parameters

| Property                                   | Type             | Validation                  |  Example value | Description                                      |
| ------------------------------------------ | ---------------- | --------------------------- | -------------- | ------------------------------------------------ |
| `spam.protection.maxUserTransfersPerEpoch` | String (integer) | strictly greater than `0`   | `"20"`         | The most transfers a use can initiate per epoch |
| `transfer.minTransferQuantumMultiple`      | String (decimal) | greater than or equal to `0`| `"0.1"`        | This, when multiplied by `quantum` (which is specified per asset) determines the minimum transfer amount |
| `transfer.fee.factor`                      | String (decimal) | in `[0.0,1.0]`              | `"0.001"`      | The proportion of the transfer charged as a fee  |
| `transfer.fee.maxQuantumAmount`            | String (decimal) | greater than or equal to `0`  | `"100"`      | The cap of the transfer fee  |
| `transfer.feeDiscountMinimumTrackedAmount` | String (decimal) | greater than or equal to `0`  | `"0.001"`      | The lower bound of transfer fee tracked |
| `transfer.feeDiscountDecayFraction` | String (decimal) | greater than or equal to `0` and strictly less than `1` | `"0.5"`      | The speed of cumulated trading fees decay for the purpose of being used to do transfer-fee-free transfers |

## Acceptance criteria

- When specifying a transfer of any kind the default behaviour is for the fees to be added on top of the amount being transferred. (<a name="0057-TRAN-081" href="#0057-TRAN-081">0057-TRAN-081</a>)
- When specifying a transfer of any kind it's possible to provide an optional parameter such that the fees are taken from amount being transferred so that the target account gets `transfer_amount - fees`. (<a name="0057-TRAN-082" href="#0057-TRAN-082">0057-TRAN-082</a>)

### One off transfer tests

- As a user I can transfer funds from a general account I control to an other party's general account. Such transfer can be immediate or delayed. (<a name="0057-TRAN-001" href="#0057-TRAN-001">0057-TRAN-001</a>)
- As a user I **cannot** transfer funds from a general account I control to reward account with a one-off transfer. (<a name="0057-TRAN-002" href="#0057-TRAN-002">0057-TRAN-002</a>)
- As a user I can transfer the governance token from a general account I control to a LOCKED_FOR_STAKING account. Such transfer must be immediate. (<a name="0057-TRAN-003" href="#0057-TRAN-003">0057-TRAN-003</a>).
- As a user I can transfer the governance token from a LOCKED_FOR_STAKING account under my control to any party's general account. Such transfer must be immediate.  (<a name="0057-TRAN-004" href="#0057-TRAN-004">0057-TRAN-004</a>)
- As a user I cannot transfer funds from accounts that I do not control. (<a name="0057-TRAN-005" href="#0057-TRAN-005">0057-TRAN-005</a>)
- As a user I cannot transfer funds from accounts I own but from the type is not supported:
  - for accounts created in a futures market, bond and margin (<a name="0057-TRAN-006" href="#0057-TRAN-006">0057-TRAN-006</a>)
  - for accounts created in a spot market, bond and holding (<a name="0057-TRAN-063" href="#0057-TRAN-063">0057-TRAN-063</a>)
- As a user I can do a transfer from any of the valid accounts (I control them and they're a valid source), and fees are taken from the source account when the transfer is executed (when `transfer amount x transfer.fee.factor <= transfer.fee.maxQuantumAmount x quantum`). (<a name="0057-TRAN-007" href="#0057-TRAN-007">0057-TRAN-007</a>)
  - The fee cost is correctly calculated using the network parameters listed above.
  - If I have enough funds to pay transfer and fees, the transfer happens.
  - If I do not have enough funds to pay transfer and fees, the transfer is cancelled.
  - The fees are being paid into the infrastructure pool.
  - The transfer fee discount is correctly applied with network parameter`transfer.feeDiscountDecayFraction`(<a name="0057-TRAN-014" href="#0057-TRAN-014">0057-TRAN-014</a>)
  - The fee-free transfer amount is accessible through the API (<a name="0057-TRAN-017" href="#0057-TRAN-017">0057-TRAN-017</a>)
- As a user I can do a transfer from any of the valid accounts (I control them and they're a valid source), and fees are taken from the source account when the transfer is executed (when `transfer amount x transfer.fee.factor > transfer.fee.maxQuantumAmount x quantum`). (<a name="0057-TRAN-011" href="#0057-TRAN-011">0057-TRAN-011</a>)
  - The fee cost is correctly calculated using the network parameters listed above.
  - If I have enough funds to pay transfer and fees, the transfer happens.
  - If I do not have enough funds to pay transfer and fees, the transfer is cancelled.
  - The fees are being paid into the infrastructure pool.
  - The transfer fee discount is correctly applied with network parameter `transfer.feeDiscountDecayFraction` (<a name="0057-TRAN-015" href="#0057-TRAN-015">0057-TRAN-015</a>)
  - The fee-free transfer amount is accessible through the API (<a name="0057-TRAN-018" href="#0057-TRAN-018">0057-TRAN-018</a>)
- when a party makes a transfer and fee-free discount is `c = 0`, then the full transfer fee amount is paid (<a name="0057-TRAN-016" href="#0057-TRAN-016">0057-TRAN-016</a>)
  - The fee cost is correctly calculated using the network parameter `transfer.fee.factor`.
  - If I have enough funds to pay transfer and fees, the transfer happens.
  - If I do not have enough funds to pay transfer and fees, the transfer is cancelled.
  - The fees are being paid into the infrastructure pool.
- when a party paid taker fee `g` in previous epoch, and `transfer.feeDiscountDecayFraction = 0.9`, then in the next epoch when a party (did not generate any fees) makes a transfer and the theoretical fee the party should pay is `f`, fee-free amount is then `c = 0.9 x g`. If `c > f`, then no transfer fee is paid (<a name="0057-TRAN-019" href="#0057-TRAN-019">0057-TRAN-019</a>)
- when a party made maker fee `g` in previous epoch, and `transfer.feeDiscountDecayFraction = 0.9`, then in the next epoch when a party (did not generate any fees) makes a transfer and the theoretical fee the party should pay is `f`, fee-free amount is then `c = 0.9 x g`. If `c > f`, then no transfer fee is paid (<a name="0057-TRAN-020" href="#0057-TRAN-020">0057-TRAN-020</a>)
- when a party paid taker fee `g` in previous epoch, and `transfer.feeDiscountDecayFraction = 0.9`, then in the next epoch when a party (did not generate any fees) makes a transfer and the theoretical fee the party should pay is `f`, fee-free amount is then `c = 0.9 x g`. If `c > f`, then no transfer fee is paid. And a party makes another transfer, and the theoretical fee the party should pay is `f`, then the party is not getting any fee-free discount(<a name="0057-TRAN-021" href="#0057-TRAN-021">0057-TRAN-021</a>)
- when a party made maker fee `g` in previous epoch, and `transfer.feeDiscountDecayFraction = 0.9`, then in the next epoch when a party (did not generate any fees) makes a transfer and the theoretical fee the party should pay is `f`, fee-free amount is then `c = 0.9 x g`. If `c > f`, then no transfer fee is paid. And a party makes another transfer, and the theoretical fee the party should pay is `f`, then the party is not getting any fee-free discount(<a name="0057-TRAN-022" href="#0057-TRAN-022">0057-TRAN-022</a>)
- when a party paid taker fee `f` in previous epoch, and `transfer.feeDiscountDecayFraction = 0.9`, then in 3 epochs the fee-free discount amount would be `c = 0.9^3 x f`, when a party makes a transfer and the theoretical fee the party should pay is `f1`, and `f1 <= 0.729 x f`, then no amount is paid for transfer (<a name="0057-TRAN-023" href="#0057-TRAN-023">0057-TRAN-023</a>)
- when a party received maker fee `f` in previous epoch, and `transfer.feeDiscountDecayFraction = 0.9`, then in 3 epochs the fee-free discount amount would be `c = 0.9^3 x f`, when a party makes a transfer and the theoretical fee the party should pay is `f1`, and `f1 <= 0.729 x f`, then no amount is paid for transfer (<a name="0057-TRAN-024" href="#0057-TRAN-024">0057-TRAN-024</a>)
- when a party makes a transfer and `f` would be the theoretical fee the party should pay then the fee on the transfer that is actually charged is `-min(f-c,0)`. The system subsequently updates `c <- max(0,c-f)`. At the end of epoch, update `c <- c x D` and `c <- c + all_trading_fees_for_trades_involved_in`, if `c < M x quantum`(M is `transfer.feeDiscountMinimumTrackedAmount`), then set `c <- 0` (<a name="0057-TRAN-027" href="#0057-TRAN-027">0057-TRAN-027</a>)
- As a user I can do a transfer from a vested account to a general account held by the same key without incurring any fees (<a name="0057-TRAN-066" href="#0057-TRAN-066">0057-TRAN-066</a>).
- If a user transfers funds from their vested account to any valid account other than their general account for that asset, they will incur fees. This includes accounts not owned by the user. (<a name="0057-TRAN-069" href="#0057-TRAN-069">0057-TRAN-069</a>).
- As a user, I **can not** transfer a quantum amount less than `transfer.minTransferQuantumAmount` from any of the valid accounts excluding a vested account (<a name="0057-TRAN-067" href="#0057-TRAN-067">0057-TRAN-067</a>).
- As a user, I **can** transfer a quantum amount less than `transfer.minTransferQuantumAmount` from a vested account if and only if I transfer the full balance (<a name="0057-TRAN-068" href="#0057-TRAN-068">0057-TRAN-068</a>).
- As a user, when I initiate a delayed transfer, the funds are taken from my account immediately (<a name="0057-TRAN-008" href="#0057-TRAN-008">0057-TRAN-008</a>)
  - The funds arrive in the target account when the transaction is processed (i.e. with the correct delay), which is not before the timestamp occurs
  - A delayed transfer that is invalid (to an invalid account type) is rejected when it is received, and the funds are not taken from the origin account.
- The spam protection mechanics prevent me to do more than `spam.protection.maxUserTransfersPerEpoch` transfers per epoch. (<a name="0057-TRAN-009" href="#0057-TRAN-009">0057-TRAN-009</a>)
- A delayed one-off transfer cannot be cancelled once set-up. (<a name="0057-TRAN-010" href="#0057-TRAN-010">0057-TRAN-010</a>)
- A one-off transfer `to` a non-`000000000...0`, and an account type that a party cannot have, must be rejected (<a name="0057-TRAN-059" href="#0057-TRAN-059">0057-TRAN-059</a>)
- As a user, I can accumulate the fees I collect over an epoch. When I initiate a transfer that incurs a transfer fee, I have the ability to view the amount that is exempt from transfer fees through the API. (<a name="0057-TRAN-012" href="#0057-TRAN-012">0057-TRAN-012</a>)

### Recurring transfer tests

As a user I can create a recurring transfer _which expires after a specified epoch_ (<a name="0057-TRAN-050" href="#0057-TRAN-050">0057-TRAN-050</a>)

- I specify a start and end epoch, and a factor of `1`, start epoch in the future, until the start epoch is reached no transfers are executed.
- Once I reach the start epoch, the first transfer happens.
- The same amount is transferred every epoch.
- In the epoch after the `end epoch`, no transfers are executed.

As a user I can create a recurring transfer _that decreases over time_ (<a name="0057-TRAN-051" href="#0057-TRAN-051">0057-TRAN-051</a>) when `start amount x transfer.fee.factor <= transfer.fee.maxQuantumAmount x quantum`

- I specify a start and end epoch, and a factor of `0.7`
- Until the start epoch is reached not transfers are executed
- Once I reach the start epoch transfers happen and the first transfer is for the `start amount`. The fee amount taken from the source account is `min(start amount x transfer.fee.factor, transfer.fee.maxQuantumAmount x quantum)` and transferred to the infrastructure fee account for the asset.
- The transfer at end of  `start epoch + 1` is `0.7 x start amount` and the fee amount is `0.7 x start amount x transfer.fee.factor`.
- The amount transferred every epoch decreases.
- After I reach the epoch `?`, no transfers are executed anymore

As a user I can create a recurring transfer _that decreases over time_ (<a name="0057-TRAN-065" href="#0057-TRAN-065">0057-TRAN-065</a>) when `start amount x transfer.fee.factor > transfer.fee.maxQuantumAmount x quantum`

- I specify a start and end epoch, and a factor of `0.7`
- Until the start epoch is reached not transfers are executed
- Once I reach the start epoch transfers happen and the first transfer is for the `start amount`. The fee amount taken from the source account is `min(start amount x transfer.fee.factor, transfer.fee.maxQuantumAmount x quantum)` and transferred to the infrastructure fee account for the asset.
- The transfer at end of  `start epoch + 1` is `0.7 x start amount` and the fee amount is `0.7 x transfer.fee.maxQuantumAmount x quantum`.
- The amount transferred every epoch decreases.
- After I reach the epoch `?`, no transfers are executed anymore

As a user I can create a recurring transfer that recurs forever, with the same balance transferred each time (<a name="0057-TRAN-052" href="#0057-TRAN-052">0057-TRAN-052</a>)

- I specify a start and no end epoch, and a factor of `1`
- Until the start epoch is reached not transfers are executed
- Once I reach the start epoch transfers happens.
- The amount transferred every epoch is the same
- The transfers happen forever

As a user I can create a recurring transfer that recurs as long as the amount is `transfer.minTransferQuantumMultiple x quantum`, with the amount transfer decreasing. (<a name="0057-TRAN-053" href="#0057-TRAN-053">0057-TRAN-053</a>)

- I specify a start and no end epoch, and a factor of `0.1`
- Until the start epoch is reached not transfers are executed
- In subsequent epochs the amount transferred every epoch `n` is `0.1` times the amount transferred in epoch `n-1`.
- Once I reach the end of start epoch transfers happens.
- The transfers happen as long as the amount transferred is >  `transfer.minTransferQuantumMultiple x quantum`.
- After a sufficiently large number of epochs the transfers stops and the recurring transfer is deleted.

As a user I can cancel a recurring transfer (<a name="0057-TRAN-054" href="#0057-TRAN-054">0057-TRAN-054</a>)

- I specify a start and no end epoch, and a factor of 1
- Once I reach the start epoch transfers happens.
- I cancel the recurring transfer after the start epoch, before the end epoch
- No transfer are executed anymore

As a user I can cancel a recurring transfer before any transfers have executed (<a name="0057-TRAN-055" href="#0057-TRAN-055">0057-TRAN-055</a>)

- I specify a start and no end epoch, and a factor of 1
- I cancel the transfer after the start epoch, before the end epoch
- No transfer are executed at all

A user's recurring transfer is cancelled if any transfer fails due to insufficient funds (<a name="0057-TRAN-056" href="#0057-TRAN-056">0057-TRAN-056</a>)

- I specify a start and no end epoch, and a factor of 1
- Until the epoch is reached not transfers are executed
- Once I reach the start epoch transfers happens.
- The account runs out of funds
- The transfer is cancelled
- No more transfers are executed.

A recurring transfer `to` a non-`000000000...0`, and an account type that a party cannot have, must be rejected (<a name="0057-TRAN-058" href="#0057-TRAN-058">0057-TRAN-058</a>)

A user's recurring transfer to a reward account does not occur if there are no parties eligible for a reward in the current epoch (<a name="0057-TRAN-057" href="#0057-TRAN-057">0057-TRAN-057</a>)

- I set up a market `ETHUSDT` settling in USDT.
- The value of `marketCreationQuantumMultiple` is `10^6` and `quantum` for `USDT` is `1`.
- I specify a start and no end epoch, and a factor of 1 to a reward account `ETHUSDT | market creation | $VEGA`
- In the first epoch no trading occurs and nothing is transferred to the reward account at the end of the epoch
- In the second epoch, 2 x 10^6 trading occurs, and at the end of the epoch the transfer to the reward account occurs
- At the end of the third epoch, no transfer occurs

If the network parameter `transfer.fee.factor` is modified, this modification is applied
immediately, i.e., transfers are accepted/rejected according to the new parameter. This holds for both increase and decrease. (<a name="0057-TRAN-062" href="#0057-TRAN-062">0057-TRAN-062</a>)

If the network parameter `transfer.fee.maxQuantumAmount` is modified, this modification is applied
immediately, i.e., transfers are accepted/rejected according to the new parameter. This holds for both increase and decrease. (<a name="0057-TRAN-064" href="#0057-TRAN-064">0057-TRAN-064</a>)

If the network parameter `spam.protection.maxUserTransfersPerEpoch` is modified, this modification is applied immediately, i.e., transfers are accepted/rejected according to the new parameter. This holds for both increase and decrease. In the case of a decrease, existing recurring transfers are not cancelled. (<a name="0057-TRAN-060" href="#0057-TRAN-060">0057-TRAN-060</a>)

If the network parameter `transfer.minTransferQuantumMultiple` is modified, this modification is applied
immediately on, i.e., transfers are accepted/rejected according to the new parameter. This holds for both increase and decrease. (<a name="0057-TRAN-061" href="#0057-TRAN-061">0057-TRAN-061</a>)

Given a recurring transfer which is distributed every epoch (i.e. `transfer_interval=1`), if the parameter of each transfer `cap_reward_fee_multiple` is set, and if `calculated_reward_in_quantum < cap_reward_fee_multiple × fees_paid_this_epoch_in_quantum` then the actual amount of reward transferred to each public key during distribution for this transfer will be `calculated_reward_in_quantum`(<a name="0057-TRAN-070" href="#0057-TRAN-070">0057-TRAN-070</a>)

Given a recurring transfer which is distributed every epoch (i.e. `transfer_interval=1`), if the parameter of each transfer `cap_reward_fee_multiple` is set, and if `calculated_reward_in_quantum > cap_reward_fee_multiple × fees_paid_this_epoch_in_quantum` then the actual amount of reward transferred to each public key during distribution for this transfer will be `cap_reward_fee_multiple × fees_paid_this_epoch_in_quantum`(<a name="0057-TRAN-071" href="#0057-TRAN-071">0057-TRAN-071</a>)

Given a recurring transfer which is distributed every epoch (i.e. `transfer_interval=1`), if the parameter of each transfer `cap_reward_fee_multiple` is set, and if some reward is left from the applied cap, the remaining balance should be recalculated only for parties that have not reached their cap until the leftover is less than 1 reward asset unit or the maximum rounds of recalculation is 10
(<a name="0057-TRAN-072" href="#0057-TRAN-072">0057-TRAN-072</a>)

Given a recurring transfer which is distributed every epoch (i.e. `transfer_interval=1`), if the parameter of each transfer `cap_reward_fee_multiple` is set, and if all keys are capped, then the remaining balance must be left in the reward pool and included in the distribution in the future epochs. (<a name="0057-TRAN-073" href="#0057-TRAN-073">0057-TRAN-073</a>)

Given a recurring transfer which is distributed every epoch (i.e. `transfer_interval=1`), if the parameter of each transfer `cap_reward_fee_multiple` is set, and the total reward transferred in a given epoch is not spent due to the cap, this does not affect the size of the next iteration, which proceeds as normal (including decay factors etc.) as if the full transfer has been made (<a name="0057-TRAN-074" href="#0057-TRAN-074">0057-TRAN-074</a>)

Given a recurring transfer which is distributed every epoch (i.e. `transfer_interval=1`), if the parameter of each transfer `cap_reward_fee_multiple` is set to be `<=0`, then it should be rejected. (<a name="0057-TRAN-075" href="#0057-TRAN-075">0057-TRAN-075</a>)

If a party sets up a recurring transfer with a `transfer_interval` field strictly greater than `1`, if they do not have enough funds to cover the next payout, the transaction will be rejected. (<a name="0057-TRAN-076" href="#0057-TRAN-076">0057-TRAN-076</a>)

If a party sets up a recurring transfer with a `transfer_interval` field strictly greater than `1`, if they have enough funds to cover the next payout, the network will lock these funds and they will be unavailable for other purposes. (<a name="0057-TRAN-077" href="#0057-TRAN-077">0057-TRAN-077</a>)

If a party sets up a recurring transfer with a `transfer_interval` field strictly greater than `1`, if they cancel the recurring transfer the locked funds will not be released and the next payout event will happen regardless. (<a name="0057-TRAN-078" href="#0057-TRAN-078">0057-TRAN-078</a>)

If a party sets up a recurring transfer with a transfer interval strictly greater than `1` and specifies a `cap_reward_fee_multiple`. If `calculated_reward_in_quantum > cap_reward_fee_multiple × fees_paid_since_last_payout_in_quantum` then the actual amount of reward transferred to each public key during distribution for this transfer will be `cap_reward_fee_multiple × fees_paid_since_last_payout_in_quantum`(<a name="0057-TRAN-079" href="#0057-TRAN-079">0057-TRAN-079</a>)

A recurring transfer to a reward account with entity scope set to individuals and individual scope set to `INDIVIDUAL_SCOPE_AMM` will only be divided amongst AMM parties based on their score in the relevant metric (<a name="0057-TRAN-080" href="#0057-TRAN-080">0057-TRAN-080</a>)
s
