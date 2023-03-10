*Purpose:

In case control of the bridge is lost (e.g., too many validators cease operating at the same time), allow for a tokenholder vote to restore the functionality by replacing the hash representing the validator identities in the bridge.


**Properties:
- Only unvested tokens are allowed to vote
- We have a decaying voting threshold - the required votes to change the validator set is lowered if the bridge isn't used.
- Tokens need to be locked to be allowed to vote, and then cannot be sold unless unlocked (which invalidates the vote)


**Variables:
   max_threshold: The maximum threshold required for a valid vote (unit: number of tokens)
   min_threshold: The minimum threshold required for a valid vote (unit: number of tokens)
   decay_rate: how fast the threshoild decays over time while the bridge is not accessed (unit: numbeer of tokens/Ethereum block)


**Bridge contract:

Functions:
last_update():  Allows another contract to query the last Ethereum block when
                the multisig was used successfully
replace_hash(h) Allows the voting contract (and that contract only) to replace
                the hash value defining the validator set


**Voting Contract:

Data structures:
- voting_table: an array (hash, votes) defining all the votes a hash got (keyed by the hash)
- user_vote: an array (key, hash)  defines the hash a key voted for (keyed by the users Ethereum key)
- user_weight an array (key, number_of_tokens) defining how many tokens a user locked (keyed by the users Ethereum key)

Functions:
lock_tokens(): Allows an Ethereum key to lock all itstokens into the voting contract, provided it has tokens, and they are not already locked to either the vesting contract or the voting contract. This initialises the votes to 0.
  Flow:
  if the key already has tokens locked, abort // If you had tokens locked, then transfer new tokens to that
                                              // account, then try to lock them, then you're just strange. 
                                              // We want to keep things simple and not accomondate that.
  set user_vote (key)  to NIL                 // i.e., no votes issued.
  set user_weight(key) to the amount of tokens locked

unlock_tokens: Allows a key to unlock its tokens. This clears all its votes.
  Flow:
  if the key has no tokens locked, abort
  for the hash this user voted for, delete the vote: voting_table(user_votes(key) -= user_weight(key)
        if the hash now has 0 votes, remove that hash from voting_table
  remove user_vote(key)
  remove user_weight(key)

vote(hash): Allows a key to vote for a specific hash. What this does:
  - If the key has voted already, delete that vote: voting_table(user_votes(key) -= user_weight(key)
            if the hash now has 0 votes, remove that hash from voting_table
  - if the hash doesn't exist in the voting table, create
        voting_table (hash, votes), where votes = 0  
  - set voting_table (hash) += user_weight(key)
  - add hash to user_votes(key).

evaluate(hash): Test if there are enough votes for a hash to execute:
  - if hash == NIL, abort  // don't count the empty votes
  - if votes(hash,votes) > max( min_threshold, max_threshold- (current_block - bridge.last_update())*decay_rate, then
        call bridge.replace_hash(hash)
        set voting_table to []
        set user_vote to []





Comment: Keys cannot lock a part of their tokens; allowing that would cause code complexity, as locking additional tokens would require weight updates, etc. If you want to use partial tokens, move them to a separate ETH key first.

A successfull change deletes all votes in the system. If you don't like it, vote again. This carries a slight risk, but avoids issues if we have two proposals that both have a chance to get the majority.





  - If the hash doesn't exist in the voting table, create
        voting_table (hash, votes), where votes = 0

