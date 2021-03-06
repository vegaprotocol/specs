# Spam protection

At this point, we cannot reject a transaction based on any data that is not the shared state 
of the blockchain. This means, it is unavoidable that one spammer can essentially fill a block.

What we can do is:
- remove the offending transactions after the block is scheduled, i.e., not process them
- update the state once a block is finalized and block transactions based on the new state
- delete transactions from every (honest) validators mempool based on the new state.

Thus, no matter what the anti-spam policy is, there is a scenario where someone creates
a lot of identities and spams one block with each. Therefore, we have to enforce a minimum
investment to be allowed to send anything to the Vega network.

For governance votes, that means that there is a minimum amount of tokens required to be allowed
to issue a proposal/vote (`spam.protection.proposal.min.tokens`/`spam.protection.voting.min.tokens`). If the network detects successful spam in spite of this minimum, then the limit can be increased automatically.

For SW, we only have governance, so the following two policies will do:

Vote proposals can only be done using a lot of tokens (say, 100.0000), or through v1 tokens (the latter is the current proposal)
Any qualified voter can vote three times per epoch per active proposal (i.e., one initial vote and twice change their mind).

Initially, a qualified voter required at least 100 tokens (i.e., a value of $1500 taking the last coinlist sale).
Thus, spamming the network for 1 minute would cost $135.000. 
If 3 blocks in a row for filled with spam i.e., parties sending substantially more than 3 votes, let's say 50 votes), 
then the number of required tokens is doubled, up to a maximum of 1600 (if someone pays 1.5 million to spam us for 60 
seconds so be it).

All parameters are up to discussion/governance vote. A change of parameters is taking effect in the epoch following the acceptance of the 
corresponding proposals. 

## More detailed description:

### Policy Enforcement:

The policy enforcement mechanism rejects messages that do not follow the anti-spam rules. This can happen in
two different ways:
- pre-block reject: A transaction is rejected before it enters the validators mempool. For Tendermint-internal
  reasons, this can only happen based on the global state coordinated through the previous block; especially,
  it cannot be based on any other transactions received by the validator but not yet put into a block
  (e.g., only three transactions per party per block).
  Once a block is scheduled, all validators also test all transactions in their mempool if they are
  still passing the test, and remove them otherwise.
- post-block-reject: A transaction has made it into the block, but is rejected before it is passed to the application layer.
  This mechanism allows for more fine-grained policies than the previous one, but at the price that the
  offending transaction has already taken up space in the blockchain.


For Sweetwater, the policies we enforce are relatively simple:

```
<num_votes> = 3
<min_voting_tokens>  = 1
<num_proposals> = 3
<min_proposing_tokens> = 200000
```

- Any tokenholder with more than `<min_voting_tokens>` tokens has `<num_votes>` voting attempts per epoch
 and proposal, i.e., they can change their mind `<num_votes>-1` times in one epoch. This means, a transaction is
 pre_block rejected, if there are `<num_votes>` or more votes on the same proposal in the blockchain in this epoch, and
 post_block rejected, if there are `<num_votes>` or more on the same proposal in the blockchain plus earlier in the current block.

- Any tokenholder that had more than 50% if its votes post-rejected is banned for 4 epochs, and all its votes are immediately 
  rejected. 
  
- A proposal can only be issued by a tokenholder owning more than `<min_proposing_tokens>` at the start of the epoch. Also
   (like above), only `<num_proposals>` proposals can be made per tokenholder per epoch, i.e., every proposal past `<num_proposals>` in an epoch is
   rejected by post-block-reject (if there sum of proposals in past blocks and the ones in the current block exceed
   `<num_proposals>`) or pre-block reject (if the sum of proposals already in the blockchain for that epoch equals or exceeds 
   `<num_proposals>`. This parameter is the same for all proposals (also market-creation related ones). 
   There also is a separate parameter to the same end that is enforced in the core. For SW, both these parameters have the same value. 
   In the future, we can set the spam protection value lower, as the amplification effect of a proposal (i.e., a proposal resulting in
   a very large number of votes) would also be covered by the core then.
   
### Notes
- What counts is the number of tokens at the beginning of the epoch. While it is unlikely (given gas prices
 and ETH speed) that the same token is moved around to different entities, this explicitly doesn't work.
- This means that every tokenholder with more than `<min_voting_tokens>` can spam exactly one block on SW.
- There is some likelihood that policies will change. It would thus be good to have a clean separation of
 policy definition and enforcement, so a change in the policies can be implemented and tested independently of
 the enforcement code.

### Increasing thresholds:
If on average for the last 10 blocks, more than 30% of all voting and proposal transactions need to be post-rejected, then the network is
under Spam attack. In this case, the `<min_voting_tokens>` value is doubled, until it reaches 1600. The threshold
is then not increased for another 10 blocks. At the beginning of every epoch, the value of `<min_voting_tokens>` is reset to its original.


### Issues: It is possible for a tokenholder to deliberately spam the network to block poorer parties from voting. Due to the
  banning policy this is not doable from one account, but with a sybil attack it can be done. If this ends up being a
  problem, we can address it by increasing the ban-time.
  
### Acceptance Criteria

 - A spam attack using votes/governance proposals is detected and the votes transactions are rejected, i.e.,
   a party that issues too many votes/governance proposals gets the follow on transactions rejected. This means
   (given the original parameters parameters from https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0054-NETP-network_parameters.md
   )
   - More than 360 delegation changes in one epoch (or, respectively, the value of `spam.protection.max.delegation`) (<a name="0062-SPAM-001" href="#0062-SPAM-001">0062-SPAM-001</a>)
   - Delegating while having less than one vega (`10^18` of our smallest unit) (`spam.protection.delegation.min.tokens`)  (<a name="0062-SPAM-002" href="#0062-SPAM-002">0062-SPAM-002</a>)
   - Making a proposal when having less than 100.000 vega (`spam.protection.proposal.min.tokens`)  (<a name="0062-SPAM-003" href="#0062-SPAM-003">0062-SPAM-003</a>)
   - Reducing the value of network parameter `spam.protection.proposal.min.tokens` will reduce the number of parties rejected in the next epoch.(<a name="0062-SPAM-014" href="#0062-SPAM-014">0062-SPAM-014</a>)
   - Making more than 3 proposals in one epoch (`spam.protection.max.proposals`) (<a name="0062-SPAM-004" href="#0062-SPAM-004">0062-SPAM-004</a>)
   - Voting with less than 100 vega (`spam.protection.voting.min.tokens`)  (<a name="0062-SPAM-005" href="#0062-SPAM-005">0062-SPAM-005</a>)
   - Voting more than 3 times on one proposal (`spam.protection.max.votes`) (<a name="0062-SPAM-006" href="#0062-SPAM-006">0062-SPAM-006</a>)
   
 - Above thresholds are exceeded in one block, leading to a post-block-reject  (<a name="0062-SPAM-007" href="#0062-SPAM-007">0062-SPAM-007</a>)
 - If 50% of a parties votes/transactions are post-block-rejected, it is blocked for 4 Epochs and unblocked afterwards again  (<a name="0062-SPAM-008" href="#0062-SPAM-008">0062-SPAM-008</a>)
 - It is possible for spam transactions to fill a block (<a name="0062-SPAM-010" href="#0062-SPAM-010">0062-SPAM-010</a>)
 - Parties that continue spamming are blocked and eventually unblocked again  (<a name="0062-SPAM-011" href="#0062-SPAM-011">0062-SPAM-011</a>)
 - Any rejection due to spam protection is reported to the user upon transaction submission detailing which criteria the key exceeded / not met  (<a name="0062-SPAM-013" href="#0062-SPAM-013">0062-SPAM-013</a>)  

> **Note**: If other governance functionality (beyond delegation-changes, votes, and proposals) are added, the spec and its acceptance criteria need to be augmented accordingly. This issue will be fixed on a follow up version.

