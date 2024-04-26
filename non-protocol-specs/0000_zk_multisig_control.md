# ZK Rollup Multisig Control

### **TL;DR: Fixed-cost Ethereum multisig transactions regardless of signer count.**

Ethereum is expensive to use in general and in our current smart contract model every added signer increases the cost of transactions. These transactions range from asset withdrawals and governance changes and are vital to Vega’s Ethereum integration. With the 13 validators we have right now, a withdrawal can cost $250 or more ([https://etherscan.io/tx/0xf7963ba84a6b6427e2f8046bbf27c0360ec878c1cb5878e838ba82230378eb31](https://etherscan.io/tx/0xf7963ba84a6b6427e2f8046bbf27c0360ec878c1cb5878e838ba82230378eb31)).

To combat this we have built a new multisignature process using ZK Rollups in a programming language called Circom. These rollups have a fixed-size proof and can accommodate a huge (500+) number of validators/signers at a fixed cost of roughly 5 signers in our current system.

## How it works
For any ZKMC-enabled smart contract function a user provides the output from a zksnark circuit. To obtain this, a user requests a bundle of signatures and balances from the signers to run through the signer circuit.

For every transaction, participating Vega signers will each sign an MIMC7+Poseidon (zk-friendly) hash of the ETH-side message hash plus the MIMC7+Poseidon  hash of the signer balance array. The ETH-side message hash is a keccak256 hash of the parameters of the protected smart contract function along with a byte4 hash of the function and the address of the specific instance of the smart contract. signers will sign this final MIMC7+Poseidon hash using an EDDSA function using the MIMC+Poseidon hash function.

Each signature is paired up with that signer’s balance which are all then bundled into an object to be used as input for the zksnark circuit.

The input to the zksnark circuit transaction looks like this:
* MIMC7+Poseidon Hash of signer balance array
 * bytes32
 * Poseidon(MIMC7([uint256]))
* Ordered array of token balances of associated public keys (weights)
 * [uint256]
* Ordered array of signer public keys
 * Xs - [uint256]
 * Ys - [uint256]
* Keccak256 Message Hash
 * keccak256(abi.encode(param_1, param_2, ... , byte4 function hash, sender eth address, nonce))
* Ordered arrays of Signatures
 * EDDSA_Mixed(MIMC+Poseidon).sign(Poseidon(MIMC7(message hash,  Poseidon(MIMC7(signer balances)))))
 * R8xs - [uint256]
 * R8ys - [uint256]
 * S - [uint256]
* Ordered Array of Enabled flags - [uint256]

The output from running the circuit contains the proof, the total balance of all the participating signers, the MIMC7+Poseidon hash of the signers’ Ax public key array, and the ETH-side message hash.

If a signer does not wish to participate, their public keys must still be included and the enabled flag set to zero, their balance will not be counted in the output.

This circuit output is then fed into the smart contract along with the other parameters. The verifier smart contract verifies the proof, then compares the signer set hash to the stored signer set hash and allows the transaction if and only if it matches and the balance is over the set threshold.

## ZK Rollup/ZK Snark
ZK Rollups are a type of zero knowledge proof that can be verified on-chain. They work by using black magic polynomial math. ZKPs allow a verifier (in this case a smart contract) to trust the output of a process without access to the input data. ZKSnarks are a specific type of a ZKP that are non-interactive and thus require no interaction between prover and verifier. The nature of the proving mechanism (aforementioned black magic) means that generating the proving mechanism (compilation) is quite compute-intensive.  The structure of snarks bring with it a couple interesting risks that need to be investigated:
1. This proving mechanism relies on a trusted setup which is compute heavy and requires multiple parties with good entropy input. Luckily once complete it doesn’t need to be redone. This is a potential bottleneck and there are unknowns in the security of the process. This needs further research.
2. SHA is too looped to use in a zero knowledge setting, so here we use MIMC7 hash then hash the result using a Poseidon hash. Both hashes are said to and appear to be cryptographically sound, but this needs to be proven.
3. The signing is EDDSA_Mixed (MIMC+Poseidon). This is the standard EDDSA algorithm but using the MIMC hash which is then hashed using Poseidon. This will need to be proven safe.

Resources:
* ZKRollups
 * [https://en.wikipedia.org/wiki/Zero-knowledge_proof](https://en.wikipedia.org/wiki/Zero-knowledge_proof)
 * [https://z.cash/technology/zksnarks/](https://z.cash/technology/zksnarks/)
 * [https://hackmd.io/@n2eVNsYdRe6KIM4PhI_2AQ/SJJ8QdxuB](https://hackmd.io/@n2eVNsYdRe6KIM4PhI_2AQ/SJJ8QdxuB)
 * [https://medium.com/coinmonks/zk-rollups-how-the-layer-2-solution-works-8fd07c222329](https://medium.com/coinmonks/zk-rollups-how-the-layer-2-solution-works-8fd07c222329)
* Trusted Setup:
 * [https://zeroknowledge.fm/the-power-of-tau-or-how-i-learned-to-stop-worrying-and-love-the-setup/](https://zeroknowledge.fm/the-power-of-tau-or-how-i-learned-to-stop-worrying-and-love-the-setup/)
 * [https://medium.com/coinmonks/announcing-the-perpetual-powers-of-tau-ceremony-to-benefit-all-zk-snark-projects-c3da86af8377](https://medium.com/coinmonks/announcing-the-perpetual-powers-of-tau-ceremony-to-benefit-all-zk-snark-projects-c3da86af8377)
* Circom:
 * [https://keen-noyce-c29dfa.netlify.app/#0](https://keen-noyce-c29dfa.netlify.app/#0)
 * [https://hackmd.io/@n2eVNsYdRe6KIM4PhI_2AQ/SJJ8QdxuB](https://hackmd.io/@n2eVNsYdRe6KIM4PhI_2AQ/SJJ8QdxuB)
* MIMC7:
 * [https://byt3bit.github.io/primesym/](https://byt3bit.github.io/primesym/)
 * [https://eprint.iacr.org/2016/492.pdf](https://eprint.iacr.org/2016/492.pdf)
* Poseidon:
 * [https://dusk.network/news/poseidon-the-most-efficient-zero-knowledge-friendly-implementation](https://dusk.network/news/poseidon-the-most-efficient-zero-knowledge-friendly-implementation)
 * [https://github.com/dusk-network/poseidon252](https://github.com/dusk-network/poseidon252)
 * [https://eprint.iacr.org/2019/458.pdf](https://eprint.iacr.org/2019/458.pdf)

## Auditing
Given the complexities of the tech stack, auditing is expected to be quite difficult. We will need to find an audit report for ZKSnark as well as CIRCOM the compiler. The circom libraries used will need to be audited but the source code is readily available. The language is far less straight-forward than expected. Finally the smart contract itself will need to be audited. I don’t expect we will easily find an auditor with CIRCOM experience.

## Integration
The workflow is quite similar to what we have now, but it will require changes to validators to use the new signing methods. There will also need to be new tooling to allow a user to generate the proof from the input bundle they receive from core.

### **TL;DR: Fixed-cost Ethereum multisig transactions regardless of signer count.**
