## Algorithm
A generally understood set of rules and calculations for solving a particular problem.

## Authentication
The process of verifying that an actor (person or machine) is who they claim they are.

## Authorization
The process of verifying that an actor (person or machine) is allowed to take an action.

## Availability
...


## Blockchain
...

## Byzantine Fault Tolerance
The ability for a distributed computer program to [continue processing correctly](https://en.wikipedia.org/wiki/Byzantine_fault_tolerance) even if 1/3 of its nodes are attackers. 

## Consensus
The manner in which a distributed system with no central authority agrees upon a specific order of input transactions for distribution to clients.

## Consistency
...

## CQRS 
Command Query Responsibility Segregation is a software [design pattern](https://martinfowler.com/bliki/CQRS.html). It separates data writes ("commands") and reads ("queries") from each other into different data stores. This helps scalability and/or makes queries easier. In industrial systems, write stores are often structured as [high throughput logs](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying). Read stores use whatever technologies make it easiest to query data. A read store can have a very different schema than the corresponding write store. The data in the read store can always be reconstructed from the commands in the write store. CQRS maps very well from the "normal" software world to the blockchain world. In CQRS terms, a blockchain is the write store, but it doesn't allow for easy querying.


## Erasure Coding 
... TODO but see [here](https://github.com/ethereum/research/wiki/A-note-on-data-availability-and-erasure-coding).

## Eventual consistency
...

## Finality
The point in time that a system is able to guarantee that transaction data is safely committed. Blockchain latency, then, is the time during which permanent data availability is not yet certain.

## Fork
...

## Fork choice rule
A rule for determining which fork is correct when faced with multiple possibly-valid forks of a blockchain.

## Fraud Proof
...

## GHOST
The [Greedy Heaviest-Observed Subtree](https://eprint.iacr.org/2013/881.pdf), a fork choice rule. 

## Hashchain
...

## Homomorphic Encryption
[Homomorphic encryption](https://en.wikipedia.org/wiki/Homomorphic_encryption) is a form of [encryption](https://en.wikipedia.org/wiki/Encryption) that allows [computation](https://en.wikipedia.org/wiki/Computation) on [ciphertexts](https://en.wikipedia.org/wiki/Ciphertext), generating an encrypted result which, when decrypted, matches the result of the operations as if they had been performed on the [plaintext](https://en.wikipedia.org/wiki/Plaintext). The purpose of homomorphic encryption is to allow computation on encrypted data.

## Implementation 
Working code for an [algorithm](#algorithm). There are usually many implementations of an algorithm, e.g. at least one for each computer language community.

## Latency
The amount of time before a system can achieve both consensus and finality; it's measured in time (milliseconds, seconds, or minutes usually). Latency interacts with the concepts of "consensus" and "finality". We can for instance say that the consensus latency of Bitcoin is ten minutes, but its finality latency (e.g. after 5 additional blocks are written) is 60 minutes. Because most consensus systems need to communicate multiple times to get to agreement, latency in high-speed blockchain systems will be fundamentally dictated by the speed of light and the geographical distance separating nodes.

## Longest Chain
...

## MainNet
...

## Merkle Tree
...

## Nothing At Stake
A theoretical problem in [Proof of Stake](#proof-of-stake) blockchains: validators can effectively break safety by voting for multiple conflicting blocks at a given block height without incurring cost for doing so. TODO: check with George: *PBFT style blockchains don't suffer from this problem because their finality properties are stronger*.



## Practical Byzantine Fault Tolerance
[PBFT](https://en.wikipedia.org/wiki/Byzantine_fault_tolerance#Practical_Byzantine_fault_tolerance) is an algorithm for doing [Byzantine Fault Tolerance](#byzantine-fault-tolerance) developed in 1999 by Barbara Liskov and Miguel Castro. Their research paper is [here](http://pmg.csail.mit.edu/papers/osdi99.pdf).

## Proof of Importance
...

## Proof of Stake
... TODO but see here.

## Proof of Work
...

## Proof of X
...

## Reliable Broadcast
... see [here](https://arxiv.org/pdf/1510.06882.pdf).

## State Channels
...

## Signed Vector Timestamps
SVTs are an improved way of using signed [Vector clocks](https://en.wikipedia.org/wiki/Vector_clock) to implement byzantine fault tolerant logical clocks. The key innovation is the use of public key signatures and incrementing vectors to detect dishonest nodes. The canonical research paper is [here](http://www.cs.cmu.edu/~smith/papers/signed.pdf).

## Tendermint
A software library, written in Go, which is an [implementation](#implementation) of [Practical Byzantine Fault Tolerance](#practical-byzantine-fault-tolerance). Multiple participating Tendermint validator nodes provide a guaranteed order of transactions to application code. 

## TestNet
...

## Throughput
The amount of data that can be processed by a system in a given unit of time, e.g. 100 transactions per second. From a user point of view, it's one component of perceived blockchain speed. The other is latency. Throughput has no relationship with latency, though: a system may have a throughput of 1 million transactions per second, but at a 6 second latency. It may meet quite different needs than a system that can achieve 300 transactions per second at a 500 millisecond latency.


