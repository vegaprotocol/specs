# Spam protection Proof of Work
Vega does not charge fees on transactions. Fees are only charged on trades that execute. The main reason for not charging transaction fees on transactions like limit order submissions or governance votes is that this is an activity that should be encouraged (limit orders provide price information and liquidity, governance votes are essential for smooth running of the system). Because of this Vega has a novel client-side-proof-of-work mechanism to prevent transaction spam. 

### Parameters and their defaults:

```
spam.pow.numberOfPastBlocks = 100  (range: 10-500)
spam.pow.difficulty = 15 <should correspond to ca. 1 seconds on a normal PC> (range:0-50)
spam.pow.hashFunction = sha3                               
spam.pow.numberOfTxPerBlock = 2 (range: 1-1000)
spam.pow.increaseDifficulty = 0 (range: 0/1)
```

If there is a governance vote on parameter changes taking effect at blockheight h, then the parameter is valid for all PoWs that are tied to a block of height h or later; that is, old pre-computations remain valid, and only new ones need to respect the new parameters. If spam.pow.numberOfPastBlocks is changed at height h, the parameter is enforced starting at block h+spam.pow.numberOfPastBlocks (being the new value). 
There is a (theoretical) possibility that a parameter is changed repeatedly so fast that the new parameter is not enforced before it is changed again. To avoid programming complexity, the intermediate parameter is ignored, i.e., we keep the current parameter until the new onw is valid.
Example: Suppose, we have numberOfPastBlocks = 100, and difficulty =15
 If we change difficulty to 20 in blockheight 20 000, then all transactions tied to block 20 000 or later need to solve difficulty 20
 However, if we then change the difficulty to 25 at blockheight 20 005, and the current blockheight is 19 990, then we keep difficulty
 20 for all transactions tied to block 20 004 or earlier, and require 25 for block 20 005 or later. 
 
 Note: The later is done to se don't need to do complex implementations for special cases that will never occur in reality; we need to store the current parameter, and a blockheight when it switches to a new one, and no intermediates. A way to avoid that would be to make parameter changes valid immediatelly; this however would cause special cases if users need to throw away transactions and recompute the PoW, which this approach avoids.

To authorize a transaction, it needs to be tied to a past block using a proof of work.
To this end, the hash of the block, a transaction identifier, are fed into a hash  function together with a padding; the proof of work is to find a padding that results in a hash that ends on `spam.pow.difficulty` zeroes.

Thus, the flow is as follows:
1. The user generates a unique transaction identifier `tid`
2. The user downloads the hash `H(b)` of the latest block it has seen, and computes brute forces values of `x` so that `hash("Vega_SPAM_PoW", H(b),tid, x)` starts with `spam.pow.difficulty` zeros.
3. The user then attaches the PoW to a transaction, and sends it of together with `x` and `H(b)`.
 
The validators verify that
- `H(b)` is the correct hash of a past block
- That block is no more than `spam.pow.numberOfPastBlocks` in the past.
  - This check is primarily done by the leader (i.e., block creator). On agreeing on a new block, all parties check their mempool for now outdated transactions and purge them.
- The hash is computed correctly and begins with `spam.pow.difficulty` zeroes
   
Furthermore, the validators check that:
- The same identifier has not been used for another transaction from a previously committed block. If the same identifier is used for 
  several transactions in the same block, these transactions need to be removed during post-processing, and the initiator blocked as a 
  spammer.
- The same block has not been used for more than `spam.pow.numberOfTxPerBlock` transactions per spam difficulty level 
  (i.e., if `spam.pow.increaseDifficulty` is `> 1`, the same block can be used for more transactions if the PoW accordingly increases in difficulty).
 
 Violations of the latter rules cannot lead to a transaction being removed, as different validators have a different view on 
 this; however, they can be verified post-agreement, and the offending vega-key can be banished for 4 epochs.


Notes: 
- We do not require to feed the hash of the actual transaction into to hash function;
this allows users to pre-compute the PoW and thus allows them to perform low
latency transactions.
- As for replay protection, there is a danger that a trader communicates with a slow validator, and thus gets a wrong block number. The safest is to check validators worth > 1/3 of the  weight and take the highest block hash.
- Due to Tendermint constraints, a decision if a transaction is to be rejected or not can only be done based on information that is either synchronized through the chain or contained in the transaction itself, but not based on any other transactions in the mempool. Thus, if a client ties too many transactions to the same block or does not execute the increased difficulty properly, we can not stop this pre-agreement, only detect it post-agreement. This is the reason why some violations are punished with banishment rather than prevented.
- As some violations could come through missconfigurations, we may consider a less strict way of banishment, e.g., only to a long term banishment for repeat/high volume offenders.
- In the [0062 spam protection spec](./0062-SPAM-spam_protection.md), we want to do anti-spam before verifying signatures; this order, however, cannot be done if the consequence of spam is banishment. Thus, here the order is:
  1. check if the account is banished and (if so) ignore the transaction
  2. check if the basic PoW with lowest difficulty is done properly
  3. verify the signatures
  4. put the transaction on the blockchain
  5. if the signed transactions violate the conditions, issue the banishment 
  6. if the signed transactions in a block violate the conditions, remove the offending ones from the block before calling vega [May need discussion]
- Depending on how things pan out, we may have an issue with the timing; to make sure traders have sufficient time to get the block height needs us to have a large parameter of `spam.pow.numberOfPastBlocks`, which may allow too many transactions. There are ways to fix this (e.g., the block height needs to end with the same bit as the validator ID), but for now we assume this doesn't cause an issue.
- The PoW is currently valid for all trransactions; a consideration is to use it only for trading related transactions, so even if something goes wrong here delegators can still vote.
  
If increasing difficulty is set to 1 (seen as a boolean flag), then more transactions can be tired to one block by increasing the difficulty. This happens in batches of `spam.pow.numberOfTxPerBlock`,  e.g., if `spam.pow.numberOfTxPerBlock` is `5` and `spam.pow.difficulty` is `7`, then the 6th to 10th transaction can be tied to the same block with difficulty `8`, the 11th would have difficulty `9`, etc.


## Hash function:
The initial hash-function used is SHA3 . To allow for a more fine-grained control over the difficulty of the PoW (the number of zeros only allows halving/doubling), the parameter `spam.pow.hashFunction` allows to increase the number of rounds of the hash function (currently 24), e.g., `spam.pow.hashFunction` = `sha3_36_rounds`. The parameter can in the future also be used to replace the SHA-3 through a governance vote (assuming other functions have been made available by then) should this prove necessary.

# Acceptance Criteria
- A message with a missing/wrong PoW is rejected (<a name="0072-SPPW-001" href="#0072-SPPW-001">0072-SPPW-001</a>)
- Reusing the same PoW for several messages is detected and leads to a blocking of the account (<a name="0072-SPPW-002" href="#0072-SPPW-002">0072-SPPW-002</a>)
- Linking too many transactions to the same block is detected and leads to a blocking of that account (if the increasing difficulty is turned of) (<a name="0072-SPPW-003" href="#0072-SPPW-003">0072-SPPW-003</a>)
- Linking too many transactions with a low difficulty level to a block is detected and leads to blocking of the account (if increasing difficulty is turned on) (<a name="0072-SPPW-004" href="#0072-SPPW-004">0072-SPPW-004</a>)
- Reusing a transaction identifier in a way that several transactions with the same ID end up in the same block is detected and leads to a blocking of the account (<a name="0072-SPPW-005" href="#0072-SPPW-005">0072-SPPW-005</a>)
- A blocked account is unblocked after 4 epochs. (<a name="0072-SPPW-006" href="#0072-SPPW-006">0072-SPPW-006</a>)
- A PoW proof can be pre-computed by the submitting party using chain ID and block hash and attached to any valid transaction, provided that at time of submission the block hash is one of the last `spam.pow.numberOfPastBlocks` blocks.  (<a name="0072-COSMICELEVATOR-007" href="#0072-COSMICELEVATOR-007">0072-COSMICELEVATOR-007</a>)
