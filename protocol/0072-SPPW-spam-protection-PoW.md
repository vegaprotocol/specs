# Spam protection Proof of Work

## Summary

Vega does not charge fees on transactions. Fees are only charged on trades that execute. The main reason for not charging transaction fees on transactions like limit order submissions or governance votes is that this is an activity that should be encouraged (limit orders provide price information and liquidity, governance votes are essential for smooth running of the system). Because of this Vega has a novel client-side-proof-of-work mechanism to prevent transaction spam.

### Parameters and their defaults

```proto
spam.pow.numberOfPastBlocks = 100  (range: 10-500)
spam.pow.difficulty = 15 <should correspond to ca. 1 seconds on a normal PC> (range:0-50)
spam.pow.hashFunction = sha3
spam.pow.numberOfTxPerBlock = 2 (range: 1-1000)
spam.pow.increaseDifficulty = 0 (range: 0/1)
```

If there is a governance vote on parameter changes taking effect at block height h, then the parameter is valid for all PoWs that are tied to a block of height h or later; that is, old pre-computations remain valid, and only new ones need to respect the new parameters. If `spam.pow.numberOfPastBlocks` is changed at height h, the parameter is enforced starting at block `h+spam.pow.numberOfPastBlocks` (being the new value).
There is a (theoretical) possibility that a parameter is changed repeatedly so fast that the new parameter is not enforced before it is changed again. To avoid programming complexity, the intermediate parameter is ignored, i.e., we keep the current parameter until the new one is valid.
Example: Suppose, we have `numberOfPastBlocks` = 100, and difficulty = 15
If we change difficulty to 20 in block height 20 000, then all transactions tied to block 20 000 or later need to solve difficulty 20
However, if we then change the difficulty to 25 at block height 20 005, and the current block height is 19 990, then we keep difficulty 20 for all transactions tied to block 20 004 or earlier, and require 25 for block 20 005 or later.

Note: The latter is done so we don't need to do complex implementations for special cases that will never occur in reality; we need to store the current parameter, and a block height when it switches to a new one, and no intermediates. A way to avoid that would be to make parameter changes valid immediately; this however would cause special cases if users need to throw away transactions and recompute the PoW, which this approach avoids.

To authorise a transaction, it needs to be tied to a past block using a proof of work.
To this end, the hash of the block and a transaction identifier are fed into a hash function together with a padding; the proof of work is to find a padding that results in a hash that starts with `spam.pow.difficulty` zeroes (when represented in bytes).

Thus, the flow is as follows:

- The user generates a unique transaction identifier `tid`
- The user downloads the hash `H(b)` of the latest block it has seen (or uses any other block hash within `spam.pow.numberOfPastBlocks` of the block to-be-produced), and brute forces values of `x` such that `hash("Vega_SPAM_PoW", H(b), tid, x)` as bytes starts with `spam.pow.difficulty` zeros.
- The user must monitor how many transactions they have sent with PoW tied to a given block.
  - If this number is less than or equal to `spam.pow.numberOfTxPerBlock` the hash must start with `spam.pow.difficulty` zeros.
  - If this number is greater than `spam.pow.numberOfTxPerBlock` the hash must start with `spam.pow.difficulty` zeros plus one additional for each `spam.pow.numberOfTxPerBlock` sized batch of transactions beyond the limit (e.g. if `spam.pow.numberOfTxPerBlock` is 10 and `spam.pow.difficulty` is 2 the 1st - 10th transactions will require 2 zeros, the 11th - 20th transactions will require 3 zeros, the 21st-30th 4 zeros, the 31st-40th 5 zeros and so on).
- The user then attaches the PoW to a transaction for a block which will be created within `spam.pow.numberOfPastBlocks` blocks of the one used for PoW hash generation, and sends it off together with `x` and `H(b)`.

The validators verify that:

- `H(b)` is the correct hash of a past block
- That block is no more than `spam.pow.numberOfPastBlocks` in the past.
  - This check is primarily done by the leader (i.e., block creator). On agreeing on a new block, all parties check their mempool for now outdated transactions and purge them.
- The hash is computed correctly and begins with `spam.pow.difficulty` zeros, or `spam.pow.difficulty` + n zeros if the validator has seen `spam.pow.numberOfTxPerBlock` * n blocks transactions from this party within the same block prior to this one.
- Note that `spam.pow.numberOfTxPerBlock` is counted against the block used for PoW, not the present block. This means that a party could submit more than `spam.pow.numberOfTxPerBlock` transactions to a single created block at only `spam.pow.difficulty` by using multiple historic blocks all within `spam.pow.numberOfPastBlocks`.

Furthermore, the validators check that:

- The same identifier has not been used for another transaction from a previously committed block. If the same identifier is used for several transactions in the same block, these transactions need to be removed during post-processing, and the initiator blocked as a spammer.
- The same block has not been used for more than `spam.pow.numberOfTxPerBlock` transactions by the same party per spam difficulty level (i.e., if `spam.pow.increaseDifficulty` is `= 1`, the same block can be used for more transactions if the PoW accordingly increases in difficulty).

Violations of the latter rules cannot lead to a transaction being removed, as different validators have a different view on this; however, they can be verified post-agreement, and the offending vega-key can be banished for the duration of 1/48 of an Epoch with a minimum duration of 30 seconds. E.g. if the epoch duration is 1 day, then the ban period is 30 minutes. If however the epoch is 10 seconds, then the ban period is 30 seconds; this is measured starting at the blocktime in which the violation occurs, and transactions are allowed again in the first block after. Validators should return a meaningful error message to the wallet to let it know that/why a transaction got rejected.
Linking a transaction to a too old block will not lead to a banishment, but only to a rejection of the offending transaction.

Notes:

- We do not require feeding the hash of the actual transaction into the hash function;
this allows users to pre-compute the PoW and thus allows them to perform low
latency transactions.
- As for replay protection, there is a danger that a trader communicates with a slow validator, and thus gets a wrong block number. The safest is to check validators worth > 1/3 of the  weight and take the highest block hash.
- Due to Tendermint constraints, a decision if a transaction is to be rejected or not can only be done based on information that is either synchronised through the chain or contained in the transaction itself, but not based on any other transactions in the mempool. Thus, if a client ties too many transactions to the same block or does not execute the increased difficulty properly, we can not stop this pre-agreement, only detect it post-agreement. This is the reason why some violations are punished with banishment rather than prevented.
- In the [0062 spam protection spec](./0062-SPAM-spam_protection.md), we want to do anti-spam before verifying signatures; this order, however, cannot be done if the consequence of spam is banishment.

Thus, here the order is:

1. check if the account is banished and (if so) ignore the transaction
2. check if the basic PoW with lowest difficulty is done properly
3. verify the signatures
4. put the transaction on the blockchain
5. if the signed transactions violate the conditions, issue the banishment
6. if the signed transactions in a block violate the conditions, remove the offending ones from the block before calling vega [May need discussion]

Depending on how things pan out, we may have an issue with the timing; to make sure traders have sufficient time to get the block height needs us to have a large parameter of `spam.pow.numberOfPastBlocks`, which may allow too many transactions. There are ways to fix this (e.g., the block height needs to end with the same bit as the validator ID), but for now we assume this doesn't cause an issue.

- The PoW is currently valid for all transactions; a consideration is to use it only for trading related transactions, so even if something goes wrong here delegators can still vote.

## Hash function

The initial hash-function used is SHA3. To allow for a more fine-grained control over the difficulty of the PoW (the number of zeros only allows halving/doubling), the parameter `spam.pow.hashFunction` allows increasing the number of rounds of the hash function (currently 24), e.g., `spam.pow.hashFunction` = `sha3_36_rounds`. The parameter can in the future also be used to replace the SHA-3 through a governance vote (assuming other functions have been made available by then) should this prove necessary.

## Mempool pruning

Vega nodes will periodically inspect the mempool. Any transaction sitting in the mempool with PoW tied to a historical block with number `N_old` which satisfies that `N_old + spam.pow.numberOfPastBlocks < N_current` will be removed from the mempool. Here `N_current` is the current block the vega node is processing (has just processed).

Clients can use this simulate "time-to-live" for transactions. If the PoW is tied to a very recent block then the transaction will remain valid for (almost) the full `spam.pow.numberOfPastBlocks`. If, on the other hand, the PoW is tied to very old block then the transaction will remain valid only for a few blocks; it will be included in a block soon or not at all.

All Vega clients that submitted transactions can verify that their transaction has succeeded by waiting that it's been included in a block; if they submitted a transaction with PoW tied to `N_old` and `N_old + spam.pow.numberOfPastBlocks < N_current` then they know the transaction was pruned and will never be included on chain.


## Acceptance Criteria

- A message with a missing/wrong PoW is rejected (<a name="0072-SPPW-001" href="#0072-SPPW-001">0072-SPPW-001</a>)
- Reusing the same PoW for several messages is detected and the messages are rejected (<a name="0072-SPPW-002" href="#0072-SPPW-002">0072-SPPW-002</a>)
- Linking too many transactions to the same block is detected and leads to a blocking of that account (if the increasing difficulty is turned off) (<a name="0072-SPPW-003" href="#0072-SPPW-003">0072-SPPW-003</a>)
- Linking too many transactions with a low difficulty level to a block is detected and leads to blocking of the account (if increasing difficulty is turned on) (<a name="0072-SPPW-004" href="#0072-SPPW-004">0072-SPPW-004</a>)(<a name="0072-SP-SP-SPPW-004" href="#0072-SP-SPPW-004">0072-SPPW-004</a>)
- Reusing a transaction identifier in a way that several transactions with the same ID end up in the same block is detected and the transactions are rejected (<a name="0072-SPPW-005" href="#0072-SPPW-005">0072-SPPW-005</a>)(<a name="0072-SP-SP-SPPW-005" href="#0072-SP-SPPW-005">0072-SPPW-005</a>)
- A blocked account is unblocked after the maximum of 1/48 of an Epoch or 30 seconds. For transactions sent in the meantime, a meaningful error message is returned. (<a name="0072-SPPW-006" href="#0072-SPPW-006">0072-SPPW-006</a>)
- PoW attached to a valid transaction will be accepted provided it's using correct chain ID and, at time of submission, the block hash is one of the last `spam.pow.numberOfPastBlocks` blocks.  (<a name="0072-COSMICELEVATOR-007" href="#0072-COSMICELEVATOR-007">0072-COSMICELEVATOR-007</a>)
- For each transaction less than or equal to `spam.pow.numberOfTxPerBlock` in a block `spam.pow.difficulty` zeros are needed in the proof-of-work (<a name="0072-SPPW-008" href="#0072-SPPW-008">0072-SPPW-008</a>)
- For each `spam.pow.numberOfTxPerBlock` sized block of transactions greater than `spam.pow.numberOfTxPerBlock` an additional 0 is required in the proof-of-work (1 additional zero for the first batch, two additional for the second batch etc) (<a name="0072-SPPW-009" href="#0072-SPPW-009">0072-SPPW-009</a>)
- For a given block, a user is able to submit more than `spam.pow.numberOfTxPerBlock` transactions with only `spam.pow.difficulty` zeros by tying them to one or more historic blocks all of which are within `spam.pow.numberOfPastBlocks` blocks (<a name="0072-SPPW-010" href="#0072-SPPW-010">0072-SPPW-010</a>)
- Using a block older than `spam.pow.numberOfPastBlocks` blocks prior to the current block is detected the transaction is rejected (<a name="0072-SPPW-011" href="#0072-SPPW-011">0072-SPPW-011</a>)

- The parameter `spam.pow.difficulty` is increased.  Verify that
  - Transactions tied to such a block using the original difficulty are rejected with an error message.
  - The effect of `pow.increaseDifficulty` is still applied, i.e., a wallet key that had the increased difficulty still has the increased difficulty w.r.t. the new baseline. (<a name="0072-COSMICELEVATOR-008" href="#0072-COSMICELEVATOR-008">0072-COSMICELEVATOR-008</a>)

- The parameter `spam.pow.difficulty` is decreased. Verify that
  - Transactions tied to such a block using the new difficulty are not rejected.
  - The effect of `pow.increaseDifficulty` is still applied, i.e., a wallet key that had the increased difficulty still has the increased difficulty w.r.t. the new baseline. (<a name="0072-COSMICELEVATOR-009" href="#0072-COSMICELEVATOR-009">0072-COSMICELEVATOR-009</a>)

- The parameter `spam.pow.increaseDifficulty` is changed from 0 to 1.  Verify that
  - Transactions tied to such a block using insufficient difficulty due to the new parameter are rejected with an error message. (<a name="0072-COSMICELEVATOR-010" href="#0072-COSMICELEVATOR-010">0072-COSMICELEVATOR-010</a>)

- The parameter `spam.pow.increaseDifficulty` is changed from 1 to 0. Verify that
  - Transactions tied to such a block using the base difficulty are not rejected. (<a name="0072-COSMICELEVATOR-011" href="#0072-COSMICELEVATOR-011">0072-COSMICELEVATOR-011</a>)

- The parameter `spam.pow.numberofTxPerBlock` is decreased.  Verify that
  - The new parameter is used for all blocks with a block height higher than the current one, i.e., a number of transactions that was allowed before and is no longer due to the new parameter is rejected (leaving the spam difficulty level constant) (<a name="0072-COSMICELEVATOR-012" href="#0072-COSMICELEVATOR-012">0072-COSMICELEVATOR-012</a>)

- The parameter `spam.pow.numberofTxPerBlock` is increased. Verify that
  - If a number of transactions is submitted with the lower lever PoW that would have exceeded the `spam.pow.numberOfTXPerBlock` before the change and not after, no transaction is rejected. (<a name="0072-COSMICELEVATOR-013" href="#0072-COSMICELEVATOR-011">0072-COSMICELEVATOR-013</a>)

- Repeat tests 008-013,  where in the same block,
  - `Spam.pow.difficulty` is increased and `spam.pow.increaseDifficulty` is increased (0 to 1), and `spam.pow.numberOfTXPerBlock` is increased.
  - `Spam.pow.difficulty` is decreased and `spam.pow.increaseDifficulty` is increased (0 to 1), and `spam.pow.numberOfTXPerBlock` is increased.
  - `Spam.pow.difficulty` is increased and `spam.pow.increaseDifficulty` is increased (0 to 1), and `spam.pow.numberOfTXPerBlock` is decreased.
  - `Spam.pow.difficulty` is decreased and `spam.pow.increaseDifficulty` is increased (0 to 1), and `spam.pow.numberOfTXPerBlock` is decreased. (<a name="0072-COSMICELEVATOR-014" href="#0072-COSMICELEVATOR-011">0072-COSMICELEVATOR-014</a>)


- *Mempool pruning* Cause congestion in the mempool by submitting many transactions (perhaps from several parties). Submit a transaction `T` tied to block number `N_old`. Make sure the transactions causing congestion create sufficiently large `N_current`. At some point we'll have `N_old + spam.pow.numberOfPastBlocks < N_current` and the transaction `T` is removed from the mempool and never scheduled. (<a name="0072-SPPW-012" href="#0072-SPPW-012">0072-SPPW-012</a>)

