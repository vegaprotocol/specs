*Multisig Token Recovery:

In case control of the bridge is lost (e.g., too many validators cease operating at the same time), this allows for a tokenholder vote to restore the functionality by replacing the signer set hash, comprised of validator addresses and vote weights, on the Multisig Control smart contract.


**Properties:
- Only unvested tokens are allowed to vote
- We have a decaying voting threshold - the required votes to change the validator set is lowered if the bridge isn't used.
- Tokens need to be deposited into the vote smart contract in order to be counted. VEGA tokens that are voting on a recovery proposal cannot be sold unless withdrawn from the vote contract, decrementing the vote count of a supported proposal by the amount removed.
- Outstanding proposals are invalidated once a proposal is successful
- Votes for valid proposals can be counted at any time and immediately update the multisig control signer set hash
- All-or-nothing all of a user's deposited VEGA tokens count towards only 1 proposal at a time, and the entire amount is counted
- Proposers must have VEGA deposited into voting smart contract
- Any proposal whose vote count drops to zero is deleted


**Variables:
   max_threshold: The maximum threshold required for a valid vote (unit: number of tokens)
   min_threshold: The minimum threshold required for a valid vote (unit: number of tokens)
   decay_rate: how fast the threshold decays over time while the bridge is not accessed (unit: number of tokens/Ethereum block)
   

**Multisig Control smart contract:

Functions:
last_transaction():  Allows another contract to query the last Ethereum timestamp when
                the multisig was used successfully
emergency_recovery(h): Allows the voting contract (and that contract only) to replace
                the hash value defining the validator set and weights

**Token Recovery smart contract:

Data structures:
- Proposal: Struct containing creation time, IPFS hash of the proposal document, the current vote count, and the new signer set hash should the proposal be successful
- User: Struct containing values for deposited VEGA token amount, and the ID of the proposal that the user currently supports, all keyed on user's Ethereum address

Functions:
current_threshold(): 
- The current calculated threshold based on the amount of time since the last successful multisig control transaction.

propose_recovery(string memory ipfs_hash, bytes32 new_signer_set_hash):
- Creates a new proposal
- User must have previously deposited VEGA
- Emits Proposal_Created event containing assigned proposal_id

deposit(uint256 amount):
- Deposits amount of tokens
- Updates user's vote count
- Updates vote count of user's selected proposal

withdraw(uint256 amount):
- Removes amount of tokens from contract and transfers them to user
- Updates user's vote count
- Updates vote count of user's selected proposal
- Deletes proposal if vote count goes to zero

set_vote(uint256 proposal_id):
- Puts user's entire vote count towards the selected proposal
- Updates user's selected proposal
- Updates votes of user's previously selected proposal
- Deletes previously selected proposal if votes drop to zero
- Updates votes of users newly selected proposal

execute_proposal(uint256 vote_id):
- Counts current votes on proposal
- Updates singer set hash via `emergency_recovery(hash)` on Multisig_Control smart contract
- Invalidates all other outstanding proposals

Events:
Proposal_Created(uint256 indexed proposal_id, uint256 timestamp, string ipfs_hash, bytes32 new_signer_set_hash)