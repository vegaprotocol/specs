Purpose:

In case control of the bridge is lost (e.g., too many validators cease operating at the same time), allow for a tokenholder vote to restore the functionality

Properties
- Only unvested tokens are allowed to vote
- We have a decaying voting threshold - the required votes to change the validator set is lowered if the bridge isn't used.
- tokens need to be locked to be allowed to vote, and then cannot be sold unless unlocked (which invalidates the vote)


Variables
   max_threshold: The maximum threshold required for a valid vote
   min_threshold: The minimum threshold required for a valid vote
   decay_rate: how fast the


Bridge contract:

last_update():  Allows another contract to query the last Ethereum block when
                the multisig was used successfully
replace_hash(h) Allows the voting contract (and that contract only) to replace
                the hash value defining the validator set


Voting Contract

Data structures:
- voting table: an array (hash, votes) defining all the votes a hash got
- user_votes: an array (key, hash1, hash2, ...)  defining all the hashes a key voted for
- user_weight an array (key, number_of_tokens) defining how many tokens a user locked.

lock_tokens: Allows an Ethereum key to lock all itstokens into the voting contract, provided it has tokens, and they are not already locked to either the vesting contract or the voting contract. This initialises

  If the key already has tokens locked, abort
  set user_votes (key) to []
  set user_weight(key) to the amount of tokens locked

unlock_tokens: Allows a key to unlock its tokens. This clears all its votes.
  If the key has no tokens locked, abort
  for each hash in user_votes(key), substract user_)weight(key)
        if a hash now has 0 votes, delete that hash
  delete user_votes(key)
  delete user_weight(key)

vote(hash): Allows a key to vote for a specific hash. What this does:
  - Verify that that key hasn't voted for that hash before. If it has, abort.
 - If the hash doesn't exist in the voting table, create
        voting_table (hash, votes), where votes = 0
  - Set voting_table (hash) += user_weight(key)
  - Add hash to user_votes(key).

Evaluate(hash)
  - if votes(hash,votes) > max( min_threshold, max_threshold- (current_block - bridge.last_update())*decay_rate, then
        call bridge.replace_hash(hash)
        set voting_table to []
        set user_votes to []





Comment: Keys cannot lock a part of their tokens; allowing that would cause code complexity, as locking additional tokens would require weight updates, etc. If you want to use partial tokens, move them to a separate ETH key first.

A successfull change deletes all votes in the system. If you don't like it, vote again. This carries a slight risk, but avoids issues if we have two proposals that both have a chance to get the majority.

Option: Allow only one hash; if a new hash is voted for, the old one is deleted.




  - If the hash doesn't exist in the voting table, create
        voting_table (hash, votes), where votes = 0

