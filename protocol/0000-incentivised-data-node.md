# Incentivised Data Node

On Vega we have validator nodes running Vega core that participate in consensus (produce blocks), non-validator nodes running Vega core  which don't participate in consensus but still have whole blockchain provide all core functionality. Transactions can be submitted to non-validator node and they will gossip with validators. 

Either of these can optionally run data-node. These provide "additional" functionality by storing data emitted by the Vega node and making it accessible through APIs. This additional functionality isn't needed for running the protocol *but* is essential for any meaningful use of the Vega network (Console etc.). 

This spec isn't about what functionality data-nodes should have. It is about how to incentivise other parties to run instances of the data node. 

## 

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

- is the node up and is it responding to to all API endpoints?
- is the node carrying the full set of data? 
- is it reasonably responsive? 
- how much is it handling? 
- how much can it handle?

Who does the measuring? Validators as part of their day-to-day job?




### Is the node carrying full set of data?

- Data is divided into sequential event bundles which contain all events the included types related to a defined period, e.g. 1 block
- Only defined event types are included: trades, positions, accounts [TODO: confirm types]
- Validators and data nodes will build a Merkle tree from event bundles. Validators do not store the data, but data nodes must (and this is what we verify with this algorithm).
- Validators can send a datanode a challenge at any time consisting of a random seed value S and a start event bundle number; the datanode then needs to find the first event bundle B in the data set after the start bundle such that HASH(pubkey, S, B) ends with N zeros (e.g. N = 4).
- The validator request is signed to prevent a DoS
- If datanodes consistently get statistical oddities (e.g., searching 50000 blocks to find te hash rather than the expected 5000 as appropriate for the difficulty/number of zeroes search for), they probably didn't store the full chain
- The Merkle tree stored by both valdiators and data nodes (described above) is used by the validator to verify that the data returned in response to the challenge is correct, i.e. the answer is the actual data that existed at block B. This does not verify that the node is storing it, hence the expensive search challenge above.
- This merkle tree is exposed by APIs and also allows any user to verify a response from the data node
- This challenge/response to prove data storage can be done fairly irregularly


### Is the node up and responding
- Additionally validators will randomly query the APIs to confirm that the node is up and serving the data (also the reponse must be verified against the Merkle tree), and the response time.
- These queries should be done regularly to ensure and measure liveness


### Reward score formula









