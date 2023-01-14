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

Vote transactions can be rejected if a if a party has less than `spam.protection.voting.min.tokens`. Any governance proposal transaction can be rejected if a party has less than `spam.protection.proposal.min.tokens`. Setting these reasonably high provides some level of protection. 
Any qualified voter can vote `spam.protection.max.votes` times per epoch per active proposal (e.g., if it's `3` then  one initial vote and twice change their mind).

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

```math
<num_votes> = 3
<min_voting_tokens>  = 1
<num_proposals> = 3
<min_proposing_tokens> = 200000
```

- Any tokenholder with more than `<min_voting_tokens>` tokens has `<num_votes>` voting attempts per epoch
 and proposal, i.e., they can change their mind `<num_votes>-1` times in one epoch. This means, a transaction is
 pre_block rejected, if there are `<num_votes>` or more votes on the same proposal in the blockchain in this epoch, and
 post_block rejected, if there are `<num_votes>` or more on the same proposal in the blockchain plus earlier in the current block.

- Any tokenholder that had more than 50% if its post-rejected is banned for max (30 seconds, 1/48 of an epoch) or until the next epoch starts, and all its governance related transactions ( but no no trading related transactions) are immediately rejected. E.g. if the epoch duration is 1 day, then the ban period is 30 minutes. If however the epoch is 10 seconds, then the ban period is 30 seconds (or until the start of the next epoch). The test for 50% of the governance transactions is repeated once the next governance related transaction is post-rejected, so a it is possible for a violating party to get banned quite quickly again; the test is only done in case of a new post-rejection, so the account does not get banned twice just because the 50% quata is still excveeded when the ban ends.
The voting counters are unaffected by the ban, so voting again on an issue that already had the full number of votes in the epoch will lead to a rejection of the new vote; this is now likely to not trigger a new ban, as this rejection will happen pre-consensus, and thus not affect the 50% rule.

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


### Issues: It is possible for a tokenholder to deliberately spam the network to block poorer parties from voting.

  Due to the banning policy this is not doable from one account, but with a sybil attack it can be done. If this ends up being a
  problem, we can address it by increasing the ban-time.
  
  
  
### Withdrawal Spam

As unclaimed withdrawals do not automatically expire, an attacker could generate a large number of messages as well as an evergrowing datastructure through [withdrawal requests](0030-ETHM-multisig_control_spec.md).

To avoid this, all withdrawal requests need a minimum withdrawal amount controlled by the network parameter `spam.protection.minimumWitdrawalQuantumMultiple`. 
The minimum allowed withdrawal amount is `spam.protection.minimumWitdrawalQuantumMultiple x quantum`, where `quantum` is set per [asset](0040-ASSF-asset_framework.md) and should be thought of as the amount of any vega asset that has roughly value of 1 USD. 
Any withdrawal requests for a smaller amounts are immediately rejected.

### Acceptance Criteria

 - A spam attack using votes/governance proposals is detected and the votes transactions are rejected, i.e.,
   a party that issues too many votes/governance proposals gets the follow on transactions rejected. This means
   (given the original parameters parameters from [0054-NETP-network_parameters.md](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0054-NETP-network_parameters.md)
   )
   - More than 360 delegation changes in one epoch (or, respectively, the value of `spam.protection.max.delegation`). This includes the undelegate transactions. Specifically, verify
      -    More than the allowed quota through delegation change only
      -    More than the allowed quota through undelegation only (this might require lowering the parameter)
      -    More than the allowed quota through a mix, where each individual set of messages is within the quota
     (<a name="0062-SPAM-001" href="#0062-SPAM-001">0062-SPAM-001</a>)
   - Delegating while having less than one vega (`10^18` of our smallest unit) (`spam.protection.delegation.min.tokens`)  (<a name="0062-SPAM-002" href="#0062-SPAM-002">0062-SPAM-002</a>)
   - Making a proposal when having less than 100.000 vega (`spam.protection.proposal.min.tokens`)  (<a name="0062-SPAM-003" href="#0062-SPAM-003">0062-SPAM-003</a>)
   - Changing the value of network parameter `spam.protection.proposal.min.tokens` will immediately change the minimum number of associated tokens needed for any kind of governance proposal. Proposals already active aren't affected.(<a name="0062-SPAM-014" href="#0062-SPAM-014">0062-SPAM-014</a>)
   - Transaction creating more than `spam.protection.max.proposals` proposals in one epoch are rejected.  (<a name="0062-SPAM-004" href="#0062-SPAM-004">0062-SPAM-004</a>)
   - Transaction submitting votes by parties with less than `spam.protection.voting.min.tokens` vega associated are rejected.  (<a name="0062-SPAM-005" href="#0062-SPAM-005">0062-SPAM-005</a>)
   - Transactions submittting a vote more than `spam.protection.max.votes` times on any one proposal are rejected. (<a name="0062-SPAM-006" href="#0062-SPAM-006">0062-SPAM-006</a>)
   
 - Above thresholds are exceeded in one block, leading to a post-block-reject  (<a name="0062-SPAM-007" href="#0062-SPAM-007">0062-SPAM-007</a>)
 - If 50% of a parties votes/transactions are post-block-rejected, it is blocked for 4 Epochs and unblocked afterwards again  (<a name="0062-SPAM-008" href="#0062-SPAM-008">0062-SPAM-008</a>)
 - It is possible for spam transactions to fill a block (<a name="0062-SPAM-010" href="#0062-SPAM-010">0062-SPAM-010</a>)
 - Parties that continue spamming are blocked and eventually unblocked again  (<a name="0062-SPAM-011" href="#0062-SPAM-011">0062-SPAM-011</a>)
 - Any rejection due to spam protection is reported to the user upon transaction submission detailing which criteria the key exceeded / not met  (<a name="0062-SPAM-013" href="#0062-SPAM-013">0062-SPAM-013</a>)  
 - If a party is banned for too many voting-rejections, it still can send trading related transactions which are not banned. (<a name="0062-SPAM-025" href="#0062-SPAM-025">0062-SPAM-025</a>)  
 - If the ban of a party ends because the banning time is up, transactions from that party are no longer rejected (<a name="0062-SPAM-015" href="#0062-SPAM-015">0062-SPAM-015</a>)  
 - If the ban of a party ends because the epoch ends, transactions from that party are no longer rejected (<a name="0062-SPAM-016" href="#0062-SPAM-016">0062-SPAM-016</a>)  
 - If a party gets banned, the ban ends due to the epoch ending, and it gets banned again at the beginning of the new epoch, the ban still lasts the entire time (or until the next epoch end), i.e., the ban-expiration timer is reset. (<a name="0062-SPAM-017" href="#0062-SPAM-017">0062-SPAM-017</a>)  
 - If a party gets banned several times during an epoch, all banns last for the defined time or until the epoch ends (try with at least three banns) (<a name="0062-SPAM-018" href="#0062-SPAM-018">0062-SPAM-018</a>)  
 - During a ban due to too many votes, all governance related transactions are rejected (<a name="0062-SPAM-019" href="#0062-SPAM-019">0062-SPAM-019</a>)  
 - After having been banned for too many votes and unbanned, with the maximum number of votes in that epoch exceeded, any additional votes are rejected without a new ban. (<a name="0062-SPAM-020" href="#0062-SPAM-020">0062-SPAM-020</a>)  
 - Try to create a withdrawal bundle for an amount smaller than defined by `spam.protection.minimumWitdrawalQuantumMultiple x quantum` and verify that it is rejected (<a name="0062-SPAM-021" href="#0062-SPAM-021">0062-SPAM-021</a>)   
 - Try to set `spam.protection.minimumWitdrawalQuantumMultiple` to `0` and verify that the parameter is rejected.(<a name="0062-SPAM-022" href="#0062-SPAM-022">0062-SPAM-022</a>)   
 - Increase `spam.protection.minimumWitdrawalQuantumMultiple` and verify that a withdrawal transaction that would have been valid according to the former parameter value is rejected with the new one. (<a name="0062-SPAM-023" href="#0062-SPAM-023">0062-SPAM-023</a>)   
 - Decrease `spam.protection.minimumWitdrawalQuantumMultiple` and verify that a withdrawal transaction that would have been invalid with the old parameter and is valid with the new value and is accepted.(<a name="0062-SPAM-024" href="#0062-SPAM-024">0062-SPAM-024</a>)   
 - Issue a valid withdrawal bundle. Increase `spam.protection.minimumWitdrawalQuantumMultiple` to a value that that would no longer allow the creation of the bundle. Ask for the bundle to be re-issued and verify that it's not rejected. (<a name="0062-COSMICELEVATOR-001" href="#0062-COSMICELEVATOR-001">0062-COSMICELEVATOR-001</a>)   

> **Note**: If other governance functionality (beyond delegation-changes, votes, and proposals) are added, the spec and its acceptance criteria need to be augmented accordingly. This issue will be fixed on a follow up version.
