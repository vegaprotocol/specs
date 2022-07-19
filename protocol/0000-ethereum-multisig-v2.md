
# Multisig Control V2 (MCV2)

As we all know, Ethereum transactions can get quite expensive. 
Our current ERC20 bridge with 13 validators uses ~167k gas for a withdrawal, for comparison an average Uniswap V3 with 1 swap is ~127k. During times of extreme gas prices, say 200 gwei (tho we’ve seen much higher), the cost to run a withdrawal with our 13 validators was $100 while at the same time the Uniswap swap cost $75 and the cost of a standard ERC20 token transfer was about $40

As we expand to have more validators, the costs grow ever so slightly exponentially per every new validator added (see chart). By 25 validators we are already at 292k gas. In our previous example of 200 gwei, this will cost $180 to do a single withdrawal. This problem applies to all multisig transactions.

## Epoch Details
The first part of the solution is to place epoch details into the parameters of MC’d functions and do away with storing of the signers on-chain. This approach reduces the memory access that causes the exponential growth AND gives us access to validator weights.

Each epoch a hash containing the weights and addresses of the next epoch’s signer set is stored on the MCV2 smart contract. Thereafter each MC’d transaction uses that new epoch hash to validate a signature bundle.

Just like in MCV1 the user gathers a bundle of signatures from the validators, but in V2, rather than store a list of validators that need to be individually added and removed, as we do now, MCV2 relies on passing in the addresses of all the validators and their weights for the current epoch. During verification the addresses and weights are hashed and compared to the current epoch hash. 

If the hashes match, then the smart contract loops through the signer set and recovers the address of the signer. This recovered address must match the address in that index of the provided addresses. If this matches the weight at that index are added to the total weight of all the signers of that transaction.

Once complete, the total weight must be higher than the threshold. If this is the case, then the transaction is allowed to go through. 

This solution comes with a higher initial overhead, but the cost of signers is steady. This means that up until 15 signers, MCV1 costs less gas. With each additional signer after 15, the gap between V1 and V2 expands exponentially.


### Epoch Check-In
![Epoch Check-In](https://github.com/vegaprotocol/specs/blob/0000-ethereum-multisig-v2/protocol/MCV2%20Epoch%20-%20Epoch%20Checkin.png)

### Multisig Withdrawal
![Multisig Withdrawal](https://github.com/vegaprotocol/specs/blob/0000-ethereum-multisig-v2/protocol/MCV2%20Epoch%20-%20Multisig%20Withdrawal.png)

## Batch Transactions
The second part of the gas reduction strategy of MCV2 decouples signers from transaction cost completely by using transaction batching and merkle proofs. Like in V1 the verify function lives on the MCV2 contract and is called by functions on other contracts to verify a transaction’s validity. 

First, Vega validators produce a batch of transactions to run on the EVM side. Each transaction in this batch is the keccak256 hash of whatever parameters are used by the consuming function. This array of hashes is then built into a binary merkle tree and the root of that merkle tree is then stored on the smart contract through the standard multisig shown above and/or piggybacked on other valid transactions.

Once stored, a user can retrieve their transaction parameters as well as a merkle proof from the Vega network, much as they do now with signature bundles. This merkle proof proves that the particular hash of the provided parameters is indeed contained as a leaf of the merkle tree. Once the proof is verified, the hash of the address of the calling contract plus and the transaction hash are stored to prove that it has been claimed. At this point the transaction is allowed to continue as normal.

This comes with the ability to invalidate individual transactions as well as entire batches of transactions.

Since this process is decoupled from the number of signers, the gas cost for verification is static. That being the case, the gas cost of a withdrawal that was checked in with a batch is 120k, right in line with a Uniswap V3 single-token swap. 

A point worth noting: at the moment all of this is unoptimized for gas reduction, so the costs stated everywhere in this document are subject to change.


### Batch Withdrawal
![Batch Withdrawal](https://github.com/vegaprotocol/specs/blob/0000-ethereum-multisig-v2/protocol/MCV2%20Epoch%20-%20Batch%20Withdrawal.png)

## ZK Rollups
...

### ZK Withdrawal
![ZK Withdrawal](https://github.com/vegaprotocol/specs/blob/0000-ethereum-multisig-v2/protocol/MCV2%20Epoch%20-%20ZK%20Withdrawal.png)

## Difficulties and Risks
There are a couple difficulties bringing all the features of MCV2 into Vega, primarily integration and incentivisation, though there are a couple others.

* Integration: between the function signatures changing and new demands for features like batching, this will be a substantial amount of work for core.
    
* Incentivisation: given the new need for epoch and batch check-ins, an incentive mechanism must be developed. Maybe we take a fee on the Vega side and reward that to whoever checks in the batch/epoch. We can also potentially attach the check-ins to batch claims or other naturally incentivised transactions.

* New Structure: the entire lifecycle is a bit different and all of the edge cases and security assumptions need to be thought through. Given the similarity to V1 I don’t expect this to be too bad.

* Redeploy and Asset Migration: Since we are swapping out the base thing that everything relies on and ALL the signatures change. MCV2 requires an entire stack redeploy, including the Asset Pool. This necessitates all the assets on V1 asset pool be migrated through MCV1 withdrawals to the new asset pool. This is doable.


