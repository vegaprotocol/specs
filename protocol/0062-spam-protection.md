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
to issue a proposal/vote. If the network detects successful spam in spite of this minimum,
then the limit can be increased automatically.

For SW, we only have governance, so the following two policies will do:

Vote proposals can only be done using a lot of tokens (say, 100.0000), or through v1 tokens (the latter is the current proposal)
Any qualified voter can vote three times per epoch per active proposal (i.e., one initial vote and twice change their mind).

Initially, a qualified voter required at least 100 tokens (i.e., a value of $1500 taking the last coinlist sale).
Thus, spamming the network for 1 minute would cost $135.000. 
If 3 blocks in a row for filled with spam i.e., parties sending substantially more than 3 votes, let's say 50 votes), 
then the number of required tokens is doubled, up to a maximum of 1600 (if someone pays 1.5 million to spam us for 60 
seconds so be it).

All parameters are up to discussion/governance vote.

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
<num_votes> = 3
<min_voting_tokens>  = 100
<num_proposals> = 3
<min_proposing_tokens> = 100000


- Any tokenholder with more than <min_voting_tokens> tokens has <num_votes> voting attempts per epoch
 and proposal, i.e., they can change their mind <num_votes>-1 times in one epoch. This means, a transaction is
 pre_block rejected, if there are <num_votes> or more votes on the same proposal in the blockchain in this epoch, and
 post_block rejected, if there are <num_votes> or more on the same proposal in the blockchain plus earlier in the current block.

- Any tokenholder that had more than 50% if its votes post-rejected is banned for 4 epochs, and all its votes are immediately 
  rejected. 
  
- A proposal can only be issued by a tokenholder owning more than <min_proposing_tokens> at the start of the epoch. Also
   (like above), only <num_proposals> proposals can be made per tokenholder per epoch, i.e., every proposal past <num_proposals> in an epoch is
   rejected by post-block-reject (if there sum of proposals in past blocks and the ones in the current block exceed
   <num_proposals>) or pre-block reject (if the sum of proposals already in the blockchain for that epoch equals or exceeds 
   <num_proposals>.
   
### Notes
- What counts is the number of tokens at the beginning of the epoch. While it is unlikely (given gas prices
 and ETH speed) that the same token is moved around to different entities, this explicitly doesn't work.
- This means that every tokenholder with more than <min_voting_tokens> can spam exactly one block on SW.
- There is some likelihood that policies will change. It would thus be good to have a clean separation of
 policy definition and enforcement, so a change in the policies can be implemented and tested independently of
 the enforcement code.

### Increasing thresholds:
If on average for the last 10 blocks, more than 30% of all voting and proposal transactions need to be post-rejected, then the network is
under Spam attack. In this case, the <min_voting_tokens> value is doubled, until it reaches 1600. The threshold
is then not increased for another 10 blocks. At the beginning of every epoch, the value of <min_voting_tokens> is reset to its original.


### Issues: It is possible for a tokenholder to deliberately spam the network to block poorer parties from voting. Due to the
  banning policy this is not doable from one account, but with a sybil attack it can be done. If this ends up being a
  problem, we can address it by increasing the ban-time.
  
