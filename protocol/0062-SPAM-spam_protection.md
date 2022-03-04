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


### Sweetwater
For Sweetwater, the policies we enforce are relatively simple:
<num_votes> = 3
<min_voting_tokens>  = 1
<num_proposals> = 3
<min_proposing_tokens> = 100000
(see https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0054-NETP-network_parameters.md for the final word on these values)


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
   <num_proposals>. This parameter is the same for all proposals (also market-creation related ones). 
   There also is a separate parameter to the same end that is enforced in the core. For SW, both these parameters have the same value. 
   In the future, we can set the spam protection value lower, as the amplification effect of a proposal (i.e., a proposal resulting in
   a very large number of votes) would also be covered by the core then.

### Minimum Functionallity for Trading


As for governance, the primary purpose for spam protection is to protect the network from overloading; this also protects
the core from processing unnecessary transactions, though that's the secondary goal.

Spam protection goes in parallel with other functionallities that can reject transactions. The order of these tests is
1. spam protection
2. replay protection
3. signature verification

The reason for this ordering is that spam protection is the cheapest to execute (essentially, looking at the transaction type and the number of transaction the owner was allowed to do; replay protection does require some buffer lookups, while signature verification is the computationally hardest.

 As for governance votes, spam protection defines a set of rules that allow transactions to be processed by
 the blockchain (or not). Due to current mempool limitations, the only input the spam
 protection is allowed to use is any data derived from comitted blocks on the chain. Thus,
 if a party is allowed 3 transactions on an issue but sends 4 in one block, the fourth one is 
 not prevented from entering the blockchain, but only deleted the block has been comitted.
 Furthermore, a party abusing this limitation to fill up the blockchain may be temporarily
 banned from any transactions altogether. Thus, we have
 
 pre-block reject: A transaction is rejected before it enters the validators mempool.
  	For Tendermint-internal reasons, this can only happen based on the global state 
 	coordinated through the previous block; especially, it cannot be based on any 
 	other transactions received by the validator but not yet put into a block (e.g., 
 	only three transactions per party per block). Once a block is scheduled, all validators 
 	also test all transactions in their mempool if they are still passing the test, and 
 	remove them otherwise.
 post-block-reject: A transaction has made it into the block, but is rejected before it is 
 	passed to the application layer. This mechanism allows for more fine-grained policies 
 	than the previous one, but at the price that the offending transaction has already 
 	taken up space in the blockchain. This primarily happens if the spam happens all in one
	block, and thus cannot be discovered by post-block-reject


For trading, the first check is if the user has any ressources in the first place:

- If the ressources available to the account (at this point only ETH) are zero, then all trading transactions are considered spam and rejected.
- If possible given the time, this value should change from zero to a governance parameter defining the threshold in a normalized unit. 

In addition, for all transactions, there is a link between revenue generated, ressources, and amount of transactions a user is allowed to make.

#### Normalised Assets and Revenues.
 For trading related transactions, the number of transactions allowed depend on the assets the corresponding
 account has. Thus, an account with one cent worth of assets in it is not allowed to make 
 10.000 trades in one block, while an account with 100 million dollars may well have a good reason
 to do so. 
To this end, we need a normalisation function that can compute the revenue/ressources of all assets a user
has as well of generated revenue. At this point, the only asset is ETH, so this is comparatively easy, though 
it would be better (if possible) to define a more stable unit. To avoid floating point calculations where possible,
assetds are calculated in 1/10.000 of an ETH, with trailing gwei cut of; this gives sufficient precision for
the purpose of determining the value of an account and avoids both floating point and overly large numbers.

*Minimum: All assets and revenues are in ETH until we have added other bridges*
*End-Goal: There is an internal way to determine relative asset values. Vega provides (similar to what Libra intended)
           a stable standard unit defined through a basket of assets, with a resolution comparable to Euro/Dollar/Pound). 
	   As new bridges should come with an internal spotmarket quickly, an API to get market values of the assets through
	   Vega-trusted oracles should eventually exist anyway **(?)** *


#### Determining the value of a Vega account
The end result are the following functions:
(Note that to uniquely identify an epoch, we need the chain-restart as well as the epoch number, as with every restart we
are again at epoch 0 **(?)**. For the simplicity of presentation, this is omitted from the function arguments, and we assume e
is a unique epoch number over chain restarts.)

revenue_generated_in_epoch(e)
	Normalised fees payed by transactions the trader was involved in epoch e, or in the current epoch up till now (if e corresponds to that epoch).
	For past epochs, the normalisation is done with respect to asset values at the time of the epoch end, not the current assets.
	This means that once we have several assets, the asset values need to be stored/synchronized in the chain on Epoch end (i.e., an update to 		https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0050-EPOC-epochs.md
	
assets_held
	Normalised assets the user holds at the moment the function is called
	
revenue_score (in epoch e) =
	revenue_score_in_epoch(e-1)*.9+revenue_generated_in_epoch(e)
	if e=1, then the score is the score of the last epoch before the last chain restart
	if e=1, and we are in the first chain, then revenue_score_in_epoch(e)=0
	
	This may affect the checkpoints, as past revenue scores from the last epoch need to be preserved.
	
asset_score (in_epoch e) =
	max(asset_score_in_epoch(e-1)*0.9, assets_held_in_epoch(e)
	if e=1, then asset_score_in_epoch(e-1) refers to the last epoch in the last chain restart, or
	0 if that does not exist.

#### Linking Value to allowed transactions

##### Minimum Functionallity
All trade related transactions are regarded equal. We have five network parameters b a1,a2,r1,r2. The number
of transaction a trader is allowed per epoch is b+ (asset_score * a1)^a2 + (revenue_score * r1)^r2.

The values of the variables that make sense need to still be determined based on fairground data; they also may be different between 
trading with training wheels and real rtrading, as the former isn't generating the kind of revenue needed to authorize transactions.

##### End goal:
Spam protection has a table as a network parameter that defines its behaviour for all types of
transactions. The values in the table are generic enough that this also can be used for governance votes, 
though this is not minimal functionality (as thatg part has already been implemented and tested)

For every type of transaction, we have the following entries:

<max_allowed_per_epoch>: A single vega account is allowed to do only this number
 	of transaction of the type during an epoch. If this value is -1, then
	there is no limit.
 <min_tokens_required>  : A vega account needs at least that many tokens to be allowed to
 	perform a transaction of this type. 
 <min_assets_required>  : A vega account needs at least this amount of (normalised) assets to be allowed
 	to perform this transaction
 <min_revenue_score>    : A vega account needs at least this revenue score to be allowed to perform a
 	transaction
<min_assets_plus_revenue>,<asset_multiplier>,<revenue_multiplyer>: asset_score * asset_multiplier+ revenue_score * revenue_multiplier has to be larger than <min_assets_plus_revenue>
 <asset_number_relation>: This is a six value parameter,consisting of
 	float ab_asset_base
 	float ax_asset_linear
 	float ay_asset_squared
	float rb_revenue_base
 	float rx_revenue_linear
 	float ry_revenue_squared

 A vega account with asset_score A and revenue_score R is allowed round(ab+ ax * A +ya * A^2 + rb+ rx * R + ry * R^2) transactions of this type.
 	
 <spam_multiplier>: If the vega network is suubject to overload, all the results from the
 	previous variables are multiplied with this. This can happen repeatedly, until
 <spam_maximum>   :  ... the combined multiplier reaches this value.






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
  
	    
### Acceptance Criteria
	
- A spam attack using votes/governance proposals is detected and the votes transactions are rejected, i.e.,
  a party that issues too many votes/governance proposals gets the follow on transactions rejected. This means
  (given the current parameters)
  - More than 360 delegation changes in one epoch
  - Delegating while having less than one vega (10^18 of our smallest unit)
  - Making a proposal when having less than 100.000 vega
  - Making more than 3 proposals in one epoch
  - Voting with less than 100 vega
  - Voting more than 3 times on one proposal
- If the corresponding governance parameters are changed, the so are above thresholds
- Above thresholds are exceeded in one block, leading to a post-block-reject
- If 50% of a parties votes/transactions are post-block-rejected, it is blocked for 4 Epochs and unblocked afterwards again
- The normalisation function outputs normalised assets/revenues for all traders 
- On all possible transactions and combinations thereof, a spam is detected and transactions are blocked before 
  being put on the blockchain
- Parties that continue spamming are blocked and eventually unblocked again
- The values of asset_score and recenue_score are computed correctly over chain restarts
- On normal trading behaviour, no transaction gets blocked 
	 

