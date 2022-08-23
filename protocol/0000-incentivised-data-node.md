# Incentivised Data Node

On Vega we have validator nodes running Vega core that participate in consensus (produce blocks), non-validator nodes running Vega core  which don't participate in consensus but still have whole blockchain provide all core functionality. Transactions can be submitted to non-validator node and they will gossip with validators. 

Either of these can optionally run data-node. These provide "additional" functionality by storing data emitted by the Vega node and making it accessible through APIs. This additional functionality isn't needed for running the protocol *but* is essential for any meaningful use of the Vega network (Console etc.). 

This spec isn't about what functionality data-nodes should have. It is about how to incentivise other parties to run instances of the data node. 

## 

- Without at least one data node, it is likely that a network will see minimal activity 
- It is beneficial to the network for the community to run data nodes as a service to users of Vega
- Therefore this spec introduces a method to reward operators of data nodes from the Network Treasury and/or infrastructure fees
- There needs to be a way of not rewarding non-perfomant data nodes (where the spec needs to define what non-performing means). 
- Catching up (having full history having started some time after the chain) isn't part of this spec. They will need to replay the chain (snapshotting?) and synchronise with other data nodes to have full history (future requirement for data nodes). At the moment the expectation is for them to replay the full chain to be eligible for rewards.

## Key requirements:

- data node operator can register their node via a transaction
- core APIs available on Vega nodes (not data nodes) should allow clients to find live data node hosts to connect to
- the protocol will need a way to establish an agreed (through consensus) measure of the performance of each registered data node per epoch (which does not necessarily have to be the same length as a proof of stake epoch)
- the protocol will use the Network Treasury and Reward Scheme functionality to pay operators of these nodes based on their performance. As for all on-chain rewards this can come from funds deposited to the network (e.g. VEGA token issuance) and also fees.

## Measuring performance 

There are two kinds of measurements: responsiveness, and completeness of the dataset.

The completeness of the dataset needs to be only measiured spradicaly, e.g., once per epoch. This is done automatically.
To this end, there is a condition based on the hash of the last vega block that triggers the response,  Validators can additionally send out requests to datanodes, though in a limited manner.


For responsiveness, a more active approach must be taken. Here, the validators send a challenge to the datanode and measure the time
it takes for the datanode to answer.
- is the node up and is it responding to to all API endpoints?
- is the node carrying the full set of data? 
- is it reasonably responsive? 
- how much is it handling? 
- how much can it handle?

Who does the measuring? Validators as part of their day-to-day job?

### Limits
The measurements we make can measure responsiveness and completeness; what we do not measure in this spec is:
- the link between either; if someone responds junk to answer fast and only looks up the database for a completeness test, this is currently not caught
- fraudulent falisfication: if someone answers strategic questions wrongly, this is not caught
- updates: the completeness measurement measures at random points, not at the end. Thus, a data-node that is 2 days behind would likely not be caught at this point.


### API for completeness measurements

To measure completeness, we require the following from the database API:

- There is some form of deterministic random access serialisation of the database. This means, the database supports splitting its entire content into blocks/bundles, which are then sequenced sequentially, i.e., there is a mapping from <int> to a bundle so that every integer between 0 and <database_size> points to a unique bundle and every bundle is indexed (in a deterministic way, so all validators end up with the same bundle for the same integer.
- There is some way to verify the correctness of a bundle, i.e., quering another datanode about the content. If ther serialisation is not typed (i.e., uses well defined trading records), this may need a separate API.

Due to the structure of the database, it may not be possible to get a clean serialisation directly; in this case, we need a more sophisticated mapping from a random value to a range of items. THis is doable (e.g., let the first part of the random vaue choose an SQL table and the second part the entry number), but requires some detailed work that takes into account the database structure.

### Data bucketing and Merkle tree (commmon, used by both checks below)
- Data is divided into sequential event bundles which contain all events the included types related to a defined period, e.g. 1 block
- Only defined event types are included: trades, positions, accounts [TODO: confirm types]
- Validators and data nodes will build a Merkle tree from event bundles. Validators do not store the data, but data nodes must (and this is what we verify with this algorithm).
- This merkle tree is exposed by APIs and also allows any user to verify an API response from the data node


### Is the node carrying the full set of data (NOT needed for MVP / Sweetwater++)
- Validators can send a datanode a challenge at any time consisting of a random seed value S and a start event bundle number; the datanode then needs to find the first event bundle B in the data set after the start bundle such that HASH(pubkey, S, B) ends with N zeros (e.g. N = 4).
In addition (to lower the load for validators), datanodes need to answer challenges randomly generated from the
vega blocks. 
    Details: To prevent Datanodes from being overwhelmed by overactive Validators, the answers to the challenge
    (together with the signed challenge itself) is sent to all validators. Furthermore, a validator can only
    send 1 challenge to a datanode, and then must wait for t other validators to challenge it before it can challenge it
    again.
    The validator request is signed to prevent a DoS attack and to prevent datanodes from simply forwarding the 
    challenge to another datanode. The signature uses the Vega identity key of the validator, and signs the message
    {"vega_challenge_datanode", chain_id, epoch, validator_id, data_node_id, challenge}
    
    
    For the randomization, every datanode has a 'suspicion factor' s (initially 1). Ff the hash of the latest block modulo 40000/s equals the datanodes ID (padded with zeros), then
    thet block forms a challenge. Similarly, the start bundle S is calculated pseudorandomly from the hash of that block.
    The challenge frequency can be changed by governance vote (which changes the modulus. The value of 40000 will result in
    roughly one challenge per epoch.
- If datanodes consistently get statistical oddities (e.g., searching 50000 data units (i.e., events) to find the hash rather than the expected 5000 as appropriate for the difficulty/number of zeroes search for), they probably didn't store the full dataset. The expected number of untis is `(1/2) x 10^N`. 
- A small statistical irregularity occurs if a datanode lies above the expected number of dataunits three times in a row, or one measurement exceeds
  105% of the expected value. If a datanode shows a small statiscical irregularity, then its factor s is multiplied by 1.2. Any measurement that
  does not show a small statisticall irregularity multiplies the factor s by 1/1.2, to a minimum of s=0.1.
- A large statistical irregularity occurs if a datanode lies 800% above the expected value, or lies above the expectation 36 times in a row.
  A datanode that shows a large statistical irregularity is automatically unregistered.
- The Merkle tree stored by both valdiators and data nodes (described above) is used by the validator to verify that the data returned in response to the challenge is correct, i.e. the answer is the actual data that existed at block B. This does not verify that the node is storing it, hence the expensive search challenge above.
- This challenge/response to prove data storage can be done fairly irregularly.
- As the tests are done auotmatically through the system, we do not have an automated function that triggers a validator to perform this test;
  rather, the validators get an API call through which they can do a test is they so desire.

The values of 40000 for the testing frequency, 105% for the sensitivite and 3 for the number of allowed failures in a row are network paramaeters (see below). 

### Is the node up and responding (Needed for MVP / Sweetwater++)
- Additionally validators will randomly query the APIs to confirm that the node is up and serving the data
- The reponse must be verified against the Merkle tree
- The response time must be recorded
- These queries should be done regularly to ensure and measure liveness
- Details:
        Validators choose the data_node they test randomly.
        The number of tests per epoch is a governance parameter <data_node_test_frequency> set to 100 initially. The tests are spread out evenly over the
        epoch, i.e., a test is done every <epoch_length>/<data_node_test_frequency>
        Validators keep statistical information of reponses concerning the last 100*<number_of_data_nodes> requests (median, average
        and standard derivation). 
        The response score of a datanode is computed as follows:
### Reward score formula

Inputs: 
- number of times data verification challenge is done per epoch
- distance from start block (or no response from data verification challange)
- expected distance from start block 

- number of times API challenge is per epoch 
- fraction of responses from API challenge, 
- average response time from API challenge 

Calculation:

Each validator is assigned a subset of S/N * M data nodes where S is a number >= 1, N is the number of validators, and M is the number of data nodes. The assignment must pick datanodes at random (uniformly with random seed agreed through consensus e.g. last block hash) from the as yet unpicked nodes, if N > 1 the process repeats once all data nodes are assigned.

For each validator that assesses a given data node:
- If (no response from any data verification challange) or (average distance from start block > K * expected distance from start block): node is considered not to be live and will not be rewarded this epoch, reward score = 0
- Else: reward score = fraction of correct responses to API challenge / average response time

Reward scores assesed by a validator that epoch are submitted in a transaction
A data node's score is the average of all score submitted for that node.

Rewards are paid by multiplying a data node's reward score as a fraction of the sum of all reward scores by the total to be distributed for the epoch.

A data node receiving a zero score for 3 consecutive epochs will be unregistered. 


### MVP version requirements
- only measure API challenge response time
- only build Merkle tree but don't bother with the rest of the challenge 

### Network Parameters
data_node_statistical_sensitivity
	Initial: 1.05
         If a data node requires <value> times the expected number of blocks, this marks an irregularity
data_node_sttistical_sensitivity_this_is_bad
	Initial: 8
data_node_allowed failures
	Initial value 3
	If a data node needs more than the exepcted number of blocks <number> times in a row, then
	this marks an irregularity.
data_node_allowed_failures_this_is_bad
	Initial value 36
	
data_node_measurement frequency
	Initially 40000.

The sensitivite values (1.05 and 3) should be tested for appropriateness before being finalized.
    
### Acceptance criteria (test case stories)
- TODO: QA team
