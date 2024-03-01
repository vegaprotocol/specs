# Auth

## Summary

This specs covers authentication of a user on the Vega network.

In a decentralised world, authentication is often done by pairing a payload sent to an application with a cryptographic signature.

Creating this cryptographic signature is often made by using a public key signature system (e.g:`ed25519`). This system is composed of a **private key** and a **public key**.

The **private key** is used to generate a unique signature of a payload. It's a critical component that must be kept secure, and should only be known to the user. The payload being signed can be any blob of bytes.

The **public key**, derived from the private key, is used to verify the authenticity of the signature of a given payload. Contrary to the private key, this key is meant to be shared with any actors of a system, so anyone can verify the signature. Therefore, the public key belongs to the user's identity. And, as the private key is meant to only be used by its owner (the user), we can determine whether a signed payload has been emitted by that user, or not.

By leveraging such system, we can safely authenticate users and their transactions on the Vega network. Any transaction with an invalid signature is rejected by the network.

## Terminology

For the purposes of this spec, we use the following terminology:

- A _wallet_ is a set of cryptographic key pairs. Each key pair is composed of a public and private keys.
- A _party_ is one set of key pairs, associated to a _wallet_.
- A _user_ is a person owning one or several _wallets_, that can use any of the _parties_ to sign transactions.

## Guide-level explanation

For a transaction to be accepted by the Vega network, we expect users to send their transactions paired with cryptographic signatures, as well as their associated public keys.

In order to facilitate this process, we provide a system responsible for:

- creating and managing wallets
- generating and managing parties
- signing transactions using a party selected by the user
- and, sending the signed transactions to the Vega network.

This system is called the `wallet management application`. It runs separately from the node, and, is usually run by the users themselves. It acts as a middle-man between the users and the Vega network.

## High level walkthrough

The process of sending the first transaction for a user is as follows:

1. Bob creates a wallet and generates a party in that wallet using his wallet management application.
2. Bob requests to his wallet management application a signature of a transaction by submitting the transaction and the public key of the party to use.
3. The transaction is checked, signed, and bundled with the signature and the public key by the wallet management application.
4. The signed transaction is then submitted to the Vega network, which verify the authenticity of the transaction and its content to ensure the transaction was signed on behalf of the correct party.
5. The network also verifies the transaction is not an attempt to replay an old transaction.
6. If correct, the transaction is executed.

There is no prior announcement of the party required for the party to be used. As long as the party has enough resources to execute the transaction, the Vega network welcomes it.

## Reference-level explanation

### Wallet management application

The wallet management application should provide the following features:

- **Manage wallets**
  - Create a wallet
  - Delete a wallet
  - Restore a wallet
- **Manage parties of a wallet**
  - Generate a party and associated key pair
  - List all parties and key pairs
- **Sign any payload**
  - Sign a text
  - Sign a transaction
- **Send transactions**

## Technical reference

### Wallet generation

The wallet should be implemented as a _hierarchical deterministic wallet_.

1. The recovery phrase (commonly known as _mnemonic_) is generated using [BIP-0039](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) implementation. The entropy bit size to use is 256, which should generate a list of 24 words.
2. The seed is derived from the recovery phrase without password.
3. The root master key is derived from the seed using [SLIP-0010](https://github.com/satoshilabs/slips/blob/master/slip-0010.md). This master key is the upmost key of the wallet.
4. We derive the Vega wallet master key from the following hardened index path `1789'/0'`. This node is the one used to derive the parties.

The key generation for parties starts at the hardened index `1'`. So, the generation of the keys follow the following sequence:

1. `1789'/0'/1'`: First party
2. `1789'/0'/2'`: Second party
3. `1789'/0'/3'`: Third party
4. `1789'/0'/x'`: Party number _x_

#### Using the Vega wallet master key

This master key should only be used when the Vega network needs to identify multiple parties as tied to a single user, like with key rotations for validator. This is not covered in this specification. See [0063-VALK](0063-VALK-validator_vega_master_keys.md).

### Signed transaction format

The transaction sent through the chain could be represented by the following Protocol Buffers message:

```proto
messge TransactionBundle {
	// The transaction serialized as bytes.
	bytes transaction = 1;

	// The signature of the transaction specified at field number 1.
	bytes signature = 2;

	// The public key to use to verify the signature at field number 2.
	bytes public_key = 3;
}
```

## Acceptance criteria

### Wallet

- As a user, I can create a wallet. It automatically generates the first key, and I get a recovery phrase in return.
- As a user, I can generate additional keys.
- As a user, I can list the public keys hold by my wallet.
- As a user, I can delete a wallet.
- As a user, I can restore a wallet using the recovery phrase. The generated keys are the same as my previous instance. It is deterministically generated.
- As a user, I can sign a transaction and send it to the network. (<a name="0022-AUTH-008" href="#0022-AUTH-008">0022-AUTH-008</a>)
- As a user, I can sign an arbitrary blob of bytes.

### On the network

- As a vega node, I ensure that all transaction are paired with a signature. (<a name="0022-AUTH-009" href="#0022-AUTH-009">0022-AUTH-009</a>)
  - A signature is verified before the transaction is sent to the chain.
  - If a signature is valid, the transaction is sent to the chain (<a name="0022-AUTH-010" href="#0022-AUTH-010">0022-AUTH-010</a>)
  - If a signature is invalid, the transaction is not sent to the chain, an error is returned (<a name="0022-AUTH-011" href="#0022-AUTH-011">0022-AUTH-011</a>)
  - A transaction with an invalid signature is never sent to the chain and the transaction is discarded. (<a name="0022-AUTH-013" href="#0022-AUTH-013">0022-AUTH-013</a>)
  - A transaction with no signature is rejected (<a name="0022-AUTH-014" href="#0022-AUTH-014">0022-AUTH-014</a>)
- A `partyId` that is not a valid public key is inherently invalid, and should be rejected (<a name="0022-AUTH-015" href="#0022-AUTH-015">0022-AUTH-015</a>)
