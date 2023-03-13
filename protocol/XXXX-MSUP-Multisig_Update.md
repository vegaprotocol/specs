# Multisig Token Recovery:

In case control of the bridge is lost (e.g., too many validators cease operating at the same time), this allows for a tokenholder vote to restore the functionality by replacing the signer set hash, comprised of validator addresses and vote weights, on the Multisig Control smart contract.


## Properties:
- Only VEGA tokens held in a user's Ethereum wallet can be deposited for a vote.
- We have a decaying voting threshold - the required votes to change the validator set is lowered if the bridge isn't used.
- Tokens need to be deposited into the vote smart contract in order to be counted. VEGA tokens that are voting on a recovery proposal cannot be sold unless withdrawn from the vote contract, decrementing the vote count of a supported proposal by the amount removed.
- Outstanding proposals are invalidated once a proposal is successful
- Votes for valid proposals can be counted at any time and immediately update the multisig control signer set hash
- All-or-nothing all of a user's deposited VEGA tokens count towards only 1 proposal at a time, and the entire amount is counted
- Proposers must have VEGA deposited into voting smart contract
- Any proposal whose vote count drops to zero is deleted
- Once proposal goes through, the Token Recovery smart contract becomes the new Staking Bridge to ensure continuation of Vega network without more ETH transactions

## Parameters:
These parameters are set at contract deployment and cannot be changed. If there needs to be an update, it needs to be redeployed and Vega needs to recognize the new contract and update it on the multisig contract with a multisig transaction.

- `max_threshold`: The maximum threshold required for a valid vote (unit: number of tokens)
- `min_threshold`: The minimum threshold required for a valid vote (unit: number of tokens)
- `decay_rate`: how fast the threshold decays over time while the bridge is not accessed (unit: number of tokens/Ethereum block)
- `multisig_address`: address of the Multisig Control smart contract
- `voting_token_address`: the address of VEGA token
   
## Recovery as Staking Bridge
The Recovery/Vote contract will implement all of the IStake interface in order to allow tokens used for a vote to also be used to stake/delegate VEGA and ensure the continuation of Vega network.

## Recovery Process
* Proposer deposits VEGA into the recovery contract
* Proposer makes a proposal and uploads it to IPFS
* Proposer coordinates with Validators and creates a signer set hash that will update the bridge's signer set
* Proposer calls `create_proposal` which emits the `Proposal_Created` event
* Proposer coordinates the community to vote on their proposal
* Users pull their VEGA off staking bridges and out of vesting (where possible) and deposit them into the Token Recover contract
* Users run `set_vote` with the `proposal_id` emitted from the `Proposal_Created` event
* Once the threshold is reached (either through numbers or threshold decay), a user runs `execute_proposal` which automatically updates the signer set hash
* Vega sees the signer set updated and network is resumed
* Since votes are also credited as stake, users can begin to delegate.

## Multisig Control smart contract:
To enable this token recovery, any multisig smart contract will need to implement the following functions:

### Functions:
- `last_transaction()`:  Allows another contract to query the last Ethereum timestamp when
                the multisig was used successfully
- `emergency_recovery(h)`: Allows the voting contract (and that contract only) to replace
                the hash value defining the validator set and weights

## Token Recovery smart contract:
### Data structures:
- `Proposal`: Struct containing creation time, IPFS hash of the proposal document, the current vote count, and the new signer set hash should the proposal be successful
- `User`: Struct containing values for deposited VEGA token amount, and the ID of the proposal that the user currently supports, all keyed on user's Ethereum address

### Functions:

- `current_threshold()`: 
  - The current calculated threshold based on the amount of time since the last successful multisig control transaction.

- `propose_recovery(string memory ipfs_hash, bytes32 new_signer_set_hash)`:
  - Creates a new proposal
  - User must have previously deposited VEGA
  - Emits Proposal_Created event containing assigned proposal_id

- `deposit(uint256 amount)`:
  - Deposits amount of tokens
  - Updates user's vote count
  - Updates vote count of user's selected proposal

- `withdraw(uint256 amount)`:
  - Removes amount of tokens from contract and transfers them to user
  - Updates user's vote count
  - Updates vote count of user's selected proposal
  - Deletes proposal if vote count goes to zero

- `set_vote(uint256 proposal_id)`:
  - Puts user's entire vote count towards the selected proposal
  - Updates user's selected proposal
  - Updates votes of user's previously selected proposal
  - Deletes previously selected proposal if votes drop to zero
  - Updates votes of users newly selected proposal

- `execute_proposal(uint256 vote_id)`:
  - Counts current votes on proposal
  - Updates singer set hash via `emergency_recovery(hash)` on Multisig_Control smart contract
  - Invalidates all other outstanding proposals

### Events:
- `Proposal_Created(uint256 indexed proposal_id, uint256 timestamp, string ipfs_hash, bytes32 new_signer_set_hash)`

