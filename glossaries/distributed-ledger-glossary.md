# Distributed ledger glossary

## ABI

Application Binary Interface - A JSON representation list of a smart contract's functions and arguments. It is used by wallets or clients to produce a transaction that interacts with a contract that exists on the the Ethereum chain - mapping function calls and parameters in to a bytecode form that the [EVM](#evm) will execute.

## Algorithm

A generally understood set of rules and calculations for solving a particular problem. An algorithm that runs on several different nodes is called a protocol.

## Authentication

The process of verifying that an actor (person or machine) is who they claim they are.

## Authorisation

The process of verifying that an actor (person or machine) is allowed to take an action.

## Availability

...

## Blockchain

...

## Byzantine Fault Tolerance

The ability for a distributed computer program to [continue processing correctly](https://en.wikipedia.org/wiki/Byzantine_fault_tolerance) as long as less than  if 1/3 of its nodes (or, is a proof-of-stake system, less than 1/3 of the stake) are attackers.

## Consensus

The manner in which a distributed system with no central authority agrees upon a specific order of input transactions for distribution to clients.

## Consistency

...

## CQRS

Command Query Responsibility Segregation is a software [design pattern](https://martinfowler.com/bliki/CQRS.html). It separates data writes ("commands") and reads ("queries") from each other into different data stores. This helps scalability and/or makes queries easier. In industrial systems, write stores are often structured as [high throughput logs](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying). Read stores use whatever technologies make it easiest to query data. A read store can have a very different schema than the corresponding write store. The data in the read store can always be reconstructed from the commands in the write store. CQRS maps very well from the "normal" software world to the blockchain world. In CQRS terms, a blockchain is the write store, but it doesn't allow for easy querying.

## DLT

Short for [Distributed Ledger Technology](https://en.wikipedia.org/wiki/Distributed_ledger)
...

## Erasure Coding

... `TODO` but see [here](https://github.com/ethereum/research/wiki/A-note-on-data-availability-and-erasure-coding).

## Eventual consistency

...

## EVM

The Ethereum Virtual Machine. Here's a [good overview blog post](https://medium.com/mycrypto/the-ethereum-virtual-machine-how-does-it-work-9abac2b7c9e). This is the environment in which Smart Contracts are executed on-chain.

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

## Hash chain

...

## Homomorphic Encryption

[Homomorphic encryption](https://en.wikipedia.org/wiki/Homomorphic_encryption) is a form of [encryption](https://en.wikipedia.org/wiki/Encryption) that allows [computation](https://en.wikipedia.org/wiki/Computation) on [ciphertexts](https://en.wikipedia.org/wiki/Ciphertext), generating an encrypted result which, when decrypted, matches the result of the operations as if they had been performed on the [plaintext](https://en.wikipedia.org/wiki/Plaintext). The purpose of homomorphic encryption is to allow computation on encrypted data.

## Implementation

Working code for an [algorithm](#algorithm). There are usually many implementations of an algorithm, e.g. at least one for each computer language community.

## Latency

The amount of time before a system can achieve both consensus and finality; it's measured in time (milliseconds, seconds, or minutes usually). Latency interacts with the concepts of "consensus" and "finality". We can for instance say that the consensus latency of Bitcoin is ten minutes, but its finality latency (e.g. after 5 additional blocks are written) is 60 minutes. Because most consensus systems need to communicate multiple times to get to agreement, latency in high-speed blockchain systems will be fundamentally dictated by the speed of light and the geographical distance separating nodes.

## Longest Chain

The longest chain approach is one way to solve consensus. It consists of a mechanism that (not necessarily uniquely) determines a leader that can propose the next block in the blockchain. If a node sees a longer chain than the one it knows, it uses that one as its new chain. Longest chain protocols do not offer finality, i.e., every block can (theoretically) be undone.

## MainNet

...

## Merkle Tree

...

## Nothing At Stake

A theoretical problem in [Proof of Stake](#proof-of-stake) blockchains using a longest chain protocol: validators can effectively break safety by voting for multiple conflicting blocks at a given block height without incurring cost for doing so.

## Oracles

An oracle is a system that allows external data to be represented on a blockchain. If a market on Vega were to be based on the amount of rainfall in Gibraltar on a specific day, the Oracle would be the system through which the volume of rain that fell on that day was logged to Vega in a way that could be used to settle the market. This would require a trusted source of rainfall data in Gibraltar to publish the data.

There are entire protocols ([Band](https://bandprotocol.com/), [Chainlink](https://chain.link/)) and data standards ([Open Oracle](https://github.com/compound-finance/open-oracle)) that define how this data can be sourced, signed and verified. In Vega, oracles are handled as one type of external data sources [data sourcing specs](https://github.com/vegaprotocol/product/pull/450).

## Practical Byzantine Fault Tolerance

[PBFT](https://en.wikipedia.org/wiki/Byzantine_fault_tolerance#Practical_Byzantine_fault_tolerance) is an algorithm for doing [Byzantine Fault Tolerance](#byzantine-fault-tolerance) developed in 1999 by Barbara Liskov and Miguel Castro. Their research paper is [here](http://pmg.csail.mit.edu/papers/osdi99.pdf).

## Proof of Importance

...

## Proof of Stake

...

## Proof of Work

...

## Proof of X

...

## Reliable Broadcast

A reliable broadcast assures that all receiving of a broadcast nodes receive the same set of messages, and that a message sent by an honest sender is received. ... see [here](https://www.semanticscholar.org/paper/Asynchronous-consensus-and-broadcast-protocols-Bracha-Toueg/130ce1bcd496a7b9192f5f53dd8d7ef626e40675),
[here](https://www.shoup.net/papers/ckps.pdf) or [here](https://arxiv.org/pdf/1510.06882.pdf).

## State Channels

...

## Signed Vector Timestamps

SVTs are an improved way of using signed [Vector clocks](https://en.wikipedia.org/wiki/Vector_clock) to implement byzantine fault tolerant logical clocks. The key innovation is the use of public key signatures and incrementing vectors to detect dishonest nodes. The canonical research paper is [here](http://www.cs.cmu.edu/~smith/papers/signed.pdf).

## Tendermint

A software library, written in Go, which is an [implementation](#implementation) of a variation of [Practical Byzantine Fault Tolerance](#practical-byzantine-fault-tolerance). Multiple participating Tendermint validator nodes provide a guaranteed order of transactions to application code.

## TestNet

...

## Throughput

The amount of data that can be processed by a system in a given unit of time, e.g. 100 transactions per second. From a user point of view, it's one component of perceived blockchain speed. The other is latency. Throughput has no relationship with latency, though: a system may have a throughput of 1 million transactions per second, but at a 6 second latency. It may meet quite different needs than a system that can achieve 300 transactions per second at a 500 millisecond latency.

## Validators

From the [Tendermint documentation](https://docs.tendermint.com/v0.34/tendermint-core/validators.html):

> Validators are responsible for committing new blocks in the blockchain. These validators participate in the consensus protocol by broadcasting votes which contain cryptographic signatures signed by each validator's private key.
> Some Proof-of-Stake consensus algorithms aim to create a "completely" decentralised system where all stakeholders (even those who are not always available online) participate in the committing of blocks. [Tendermint](#tendermint) has a different approach to block creation. Validators are expected to be online, and the set of validators is permissioned/curated by some external process.
