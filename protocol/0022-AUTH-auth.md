# Auth

## Summary

This specs covers authentication of a user with the vega network.
We'll introduce a new tool to use with the vega network in order to allow a user to authenticate a transaction.
No implementation details will be covered.

In a blockchain / decentralised / public world authentication is often done by pairing a payload with the corresponding cryptographic signature (e.g: a `submitOrder` transaction) that a user is sending to the application (in our case the vega network).
Creating a signature is often made by using a public key signature system (e.g:`ed25519`), which are composed of a private key (which the user need to keep secure) which will allow a user to sign a payload (basically a blob of bytes), and a public key derived from the private key (meant to be share with any actors in the system) used in order to verify a signature for a given payload. As the private key is meant to be used only by the owner of it, we can assume that if a signature can be verified, the original transaction was emitted by the owner of the private key.

For the purposes of this spec, we use the following terminology:

- A _user_ is a user as registered in the wallet / KMS service.
- A _party_ is one set of key pairs, created by the user.
- A user can have many key pairs / parties.

## Guide-level explanation

As a first version of the authentication, we do not expect the vega network itself to create the signature for a given transaction only to verify such signature, we expect the user to send any transaction paired with the signature.
In order to facilitate this process we will provide a new service responsible for storing users private keys, and signing an arbitrary blob of bytes (the actual transaction), requested by the user associated to a specific identity on the service, we can call this service a `wallet service`. This service will run separately from the node.
Users should log in to this service, and be able to choose one of their keys they want to use to sign their transactions

The Vega network will implement a new command to be submitted to the chain to propagate a new public key over the network. This should be initiated by the owner of the public private key.
Once this new command made it to a block, we would expect the whole network to be able to verify any signature from this user.

Any transaction with an invalid signature should be rejected by the network.

## High level walkthrough

- The Vega network exists with X validators
- Y Markets are configured and live
- 0 parties exist within the network

The process of adding a new party to the network and placing the first order will be as follows:

- Bob knows the address of a node running a wallet service
- Bob calls the create user API on that wallet service and creates a wallet service account on that node, receiving an authentication token in return
- Bob calls the create party API on that wallet service, which creates a public and private key pair for a party belonging to the user 'bob'
- Bob creates an order object and submits it (unsigned, unencrypted) with his auth token to the wallet service for signing, receiving back a signature for the transaction
- Bob calls the create transaction API on a vega validator, including the unencrypted transaction and signature
- As this is the first transaction for this party, the public key announce message is submitted to the chain
- The transaction passes basic validation and is submitted to the chain
- Upon execution the public key is derived from the transaction signature and validated to ensure that the transaction was signed on behalf of the correct party
- The transaction is executed

## Reference-level explanation

### Core changes

- Uses of the old auth service will no longer exist
- The existing `partyId` will be replaced with a public key

### Wallet service

The wallet service should provide the following features:

- Manage users
  - Create a new user
  - sign-in, login, logout to the wallet (authentication method to be defined by implementation)
- Manage a user's parties and associated key pairs (a party is associated with exactly one key pair)
  - create a party and associated key pair
  - list all parties and key pairs
  - delete a party and its associated key pair
- Sign blob of data
  - accept a request from a authenticated user containing a blob of data and reference to a party (and therefore a key pair) to be used to sign the blob

#### Wallet service: A user

A user in the wallet service consists of:

- The minimum details required to support an authentication such as OAUTH
- A list of parties consisting of:
  - A private key
  - A public key

The root user ID is not used or represented in the Vega chain. It only exists on the Wallet Service on the node that the user is connecting to the network through, and is used to tie together Parties, the public and private key pairs that are used to make and validate transactions on the network.

#### Wallet service: Signing a blob of user

- Via an API, the user will provide a transaction in JSON (or similar) format, and also provide a session token that validates their access to the signing service.
- The API will return the complete data required to submit that transaction to the network

#### Wallet service: exporting a wallet

A wallet is represented as an encrypted file containing a list of public and private key.

- We want a user of the wallet service to be able to download his wallet.
- The API should return the full wallet file of the user.
- The user should be able to use the file locally and decrypt it in order to use the public and private key.

### Network

The network will need to update the existing command in order to add to them a signature or public key.

- Each transaction is paired with a signature, so it can verify the user address/ID from the signature
- The recovered user address is the `partyID`

The network will verify `partyID` from signature for all transactions.
When to verify them will need to be decided and profile as verifying transaction will be at some cost for the nodes, but ideally we should:

- Verify a signature for a transaction before it's sent to the chain so we can stop a transaction to be proposed to the chain if it's an invalid signature
- Verify a signature for a transaction after it's added to the block for security as well.

## Pseudo-code / Examples

Protobuf proposal for the new transaction format sent through the chain:

```proto
messge TransactionBundle {
	// the protobuf transaction bytes, e.g: submitOrder, cancelOrder, ...
	bytes tx = 1;
	// signature
	bytes sig = 2;
	// either a signature or a public key
	oneof auth {
		bytes address = 3;
		bytes pubKey = 4;
	}
}
```

## Acceptance Criteria

### Wallet service acceptance criteria

- As a user, I can create a new account on the Wallet service (account creation requirement to be implementation details)  (<a name="0022-AUTH-001" href="#0022-AUTH-001">0022-AUTH-001</a>)(<a name="0022-SP-AUTH-001" href="#0022-SP-AUTH-001">0022-SP-AUTH-001</a>)
- As a user, I can login to the Wallet service with my wallet name and password (<a name="0022-AUTH-002" href="#0022-AUTH-002">0022-AUTH-002</a>)(<a name="0022-SP-AUTH-002" href="#0022-SP-AUTH-002">0022-SP-AUTH-002</a>)
- As a user, I can logout of the Wallet service with a token given to me at login (<a name="0022-AUTH-003" href="#0022-AUTH-003">0022-AUTH-003</a>)(<a name="0022-SP-AUTH-003" href="#0022-SP-AUTH-003">0022-SP-AUTH-003</a>)
- As a user, if I'm logged in, I can create a new party (with a key pair) for for my account on the Wallet service. (<a name="0022-AUTH-004" href="#0022-AUTH-004">0022-AUTH-004</a>)(<a name="0022-SP-AUTH-004" href="#0022-SP-AUTH-004">0022-SP-AUTH-004</a>)
- As a user, if I'm logged in, I can list all my parties (and their key pairs) on the Wallet service (<a name="0022-AUTH-005" href="#0022-AUTH-005">0022-AUTH-005</a>)(<a name="0022-SP-AUTH-005" href="#0022-SP-AUTH-005">0022-SP-AUTH-005</a>)
- As a user, if I'm logged in, I can create a signature for a blob of data, using one of my parties (and its key pair). (<a name="0022-AUTH-007" href="#0022-AUTH-007">0022-AUTH-007</a>)(<a name="0022-SP-AUTH-007" href="#0022-SP-AUTH-007">0022-SP-AUTH-007</a>)

### Vega network acceptance criteria

- As a user, I can send a transaction to the vega network with a signature for it. (<a name="0022-AUTH-008" href="#0022-AUTH-008">0022-AUTH-008</a>)(<a name="0022-SP-AUTH-008" href="#0022-SP-AUTH-008">0022-SP-AUTH-008</a>)
- As a vega node, I ensure that all transaction are paired with a signature. (<a name="0022-AUTH-009" href="#0022-AUTH-009">0022-AUTH-009</a>)(<a name="0022-SP-AUTH-009" href="#0022-SP-AUTH-009">0022-SP-AUTH-009</a>)
  - A signature is verified before the transaction is sent to the chain.
  - If a signature is valid, the transaction is sent to the chain (<a name="0022-AUTH-010" href="#0022-AUTH-010">0022-AUTH-010</a>)(<a name="0022-SP-AUTH-010" href="#0022-SP-AUTH-010">0022-SP-AUTH-010</a>)
  - If a signature is invalid, the transaction is not sent to the chain, an error is returned (<a name="0022-AUTH-011" href="#0022-AUTH-011">0022-AUTH-011</a>)(<a name="0022-SP-AUTH-011" href="#0022-SP-AUTH-011">0022-SP-AUTH-011</a>)
  - A transaction with an invalid signature is never sent to the chain and the transaction is discarded. (<a name="0022-AUTH-013" href="#0022-AUTH-013">0022-AUTH-013</a>) (<a name="0022-SP-AUTH-013" href="#0022-SP-AUTH-013">0022-SP-AUTH-013</a>)
  - A transaction with no signature is rejected (<a name="0022-AUTH-014" href="#0022-AUTH-014">0022-AUTH-014</a>)(<a name="0022-SP-AUTH-014" href="#0022-SP-AUTH-014">0022-SP-AUTH-014</a>)
- A `partyId` that is not a valid public key is inherently invalid, and should be rejected (<a name="0022-AUTH-015" href="#0022-AUTH-015">0022-AUTH-015</a>)(<a name="0022-AUTH-SP-015" href="#0022-AUTH-SP-015">0022-SP-AUTH-015</a>)
  - _Note:_ In early versions of Vega, the `partyId` was an arbitrary string. This is no longer valid, and should be rejected. This includes the [network party](./0017-PART-party.md#network-party) - that is used where transactions are generated by the system, and it should never be possible to submit a transaction as `network`.

## Future work

The implementation outline explicitly ties the party performing the action to the public key. We may in future want to allow
a key to sign actions on behalf of another party. This would probably involve some sort of new chain-based announcement of the
delegation.
