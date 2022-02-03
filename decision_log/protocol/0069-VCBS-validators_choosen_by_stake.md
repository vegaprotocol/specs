
#1. Qualifying for a validator

Options: 
##1.1 Minimum Stake required (i.e., every node representing a certain amount of stake qualifies).
##1.2	Fixed Number (i.e., there are n validators, if someone new comes in another one needs to get out)

Option 1.1 has the advantage that is is more stable for the validartors. Although a Validator does require to gain stake at the expense 
of other validators, a validator joining does not necessarily kick another one out. Likewise, a
Validator leaving does not require immediate action.

The disadvantage is that it’s harder to control the number. As many validators will have more than the minimum stake, there will be far 
fewer validators than total_stake/minimum_stake. This means we may end up with either to few validators, or the potential to get way too many. 
This is enhanced by the distribution of the validators - while the normal distribution would be relatively uneven (i.e., some validators have a 
propotionally high share) the maximum number of possible validators is defined by the even distribution. This means the parameters would need
to be aligned for the expected distribution, and thus the maximum number of validators can get substantially higher than intendet.

Option 1.2 Means that for every joining validator, another one has to leave; thus, a validator
Can be removed without having lost any stake. It has a high stability in the number of 
Validators, though that requires new validators on standby if an old one leaves.

##Decision: Option 1.2 is chosen with the following mitigations:
- Existing validators get a bonus, so we don’t have flipping every epoch if 2 validators are
  Close
- There’s a set of Ersatzvalidators on standby which receive a share of the reward for providing availability. This also eases the pain of a validator that is removed.

2. Payment for the MultiSig

Options
##	1.1 Vega holds a treasury that is pre-funded by us, and then refilled from trading fees
##	1.2 Multisig changes are piggybacked on already paid transactions. This can be done either through a general piggybacking the new weights
        with every transaction, or by offer a generic "transaction combining service" that also updates the weight update; if necessary, this
        can be triggered by anyone.
##	1.3 Validators are to take care of multisig updates, payment gets delayed if they don’t.

Option 1.1 Would create the biggest stability, but is adding new code/complexity, and needs carefully adjustment if there’s several bridges.
Option 1.2 Is probably the best option, but isn’t available in time
Option 1.3 Puts the problem to the validators to figure out and adds motivation.

##Decision 1.3 is chosen as all other options would take too long to implement. 1.2 may replace it eventually.

#Open Questions: Do we need an API for this ? How do the validators communicate/agree  on who pays, for example, for a weight change ? Is this our problem or theirs ?

##3. Multisig Price
Issue: At the current time, the price for a transaction with Ethereum increases linearly with the number of validators. Already with 13 validators, 
this is already to high. If we increase the number of validators, it may become unacceptable.
Options
#	1.1 Threshold/ZKSnark/Hybrid variant
#	1.2 Fix the set of validators interacting with Tendermint to a maximum that may be smaller than the actual set
#	1.3 Accept high prices
# 1.3.1 Accept high prices, and implement piggibacking/combining transactions to manage the price.

Option 1.1 is the preferred one, but will take far too long to implement and audit.
Option 1.2 adds insecurity, but guarantees price stability. At least until full trading starts the security risk is manageable, as there's
   limited benefit from stealing those amounts.
Option 1.3 severely limits the number of validators we can support without loosing customers.
Option 1.3.1 Might be implemented anyway, but won't be available in time 

Option 1.2 is chosen for now, though a bit grudginly. 1.3.1 might come at some point, while the end goal is 1.1.

#Open Question: Does this apply for both withdrawals and validator updates ? Can the latter one have a higher threshold ?


t.d.b.
4. Ersatzelevator performance measurement



Zero Performance Recovery


Multisig Validators
   Strongest validators until we have weights
   2/3 of numberMultiSigners once we do
