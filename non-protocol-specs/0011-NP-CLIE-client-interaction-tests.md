# Client interaction

## Summary

This specification contains a set of tests/acceptance criteria that clients (wallets/bots) interacting with Vega are advised to test against to assure that they can authenticate properly, pass spam protection, process notifications, etc.

## Acceptance criteria

1. The parameter `spam.pow.numberofTxPerBlock` is decreased. Verify that:

   - The new parameter is communicated to and adapted/used by the wallet, i.e., if a user has too many transactions according to the new parameter, the wallet does not submit the excess transactions and returns an appropriate error message OR reprocesses the transactions. (<a name="0011-NP-CLIE-001" href="#0011-NP-CLIE-001">0011-NP-CLIE-001</a>)
   - The new parameter is communicated to and adapted/used by the wallet, i.e., if a user has too many transactions according to the new parameter, AND if the parameter `spam.pow.increaseDifficulty` is set to `1`, the wallet submits the excess transactions by submitting a PoW of higher difficulty. (<a name="0011-NP-CLIE-002" href="#0011-NP-CLIE-002">0011-NP-CLIE-002</a>)

1. The parameter `spam.pow.numberOfTxPerBlock` is increased. Verify that:

   - This is communicated to the wallet, and the wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened.
   - This means that a wallet, for each transaction tied to a block with a height lower than the one in which the change happened will honour the previous limit. (<a name="0011-NP-CLIE-003" href="#0011-NP-CLIE-003">0011-NP-CLIE-003</a>)
   - This means that a wallet, for each transaction tied to a block with a height higher than the one in which the change happened will honour the new limit. (<a name="0011-NP-CLIE-004" href="#0011-NP-CLIE-004">0011-NP-CLIE-004</a>)

1. The parameter `spam.pow.difficulty` is increased. Verify that:

   - This is communicated to the wallet, and the wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. (<a name="0011-NP-CLIE-005" href="#0011-NP-CLIE-005">0011-NP-CLIE-005</a>)

1. The parameter `spam.pow.difficulty` is decreased. Verify that

   - This is communicated to the wallet, and the wallet uses these new parameters for each transaction tied to a block with a height higher than the one in which the change happened. (<a name="0011-NP-CLIE-006" href="#0011-NP-CLIE-006">0011-NP-CLIE-006</a>)

1. The parameter `spam.pow.increaseDifficulty` is changed from `0` to `1`. Verify that

   - This is communicated to the wallet, and wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. This requires the wallet to be subjected to a difficulty increase due to too many messages (<a name="0011-NP-CLIE-007" href="#0011-NP-CLIE-007">0011-NP-CLIE-007</a>)

1. The parameter `spam.pow.decreaseDifficulty` is changed from `1` to `0`. Verify that

   - This is communicated to the wallet, and wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. The wallet should submit no more than `spam.pow.numberofTxPerBlock` number of transactions when tied to a block higher than the one in which the change happened. In case of excess transactions (i.e. greater than `spam.pow.numberofTxPerBlock`), transactions should not be sent and returns an appropriate error message OR reprocesses the transactions. (<a name="0011-NP-CLIE-008" href="#0011-NP-CLIE-008">0011-NP-CLIE-008</a>)

1. Set the parameter `SpamPoWNumberOfPastBlocks` to 10, `SpamPoWNumberOfTxPerBlock` to 2, and `spam.pow.increaseDifficulty` to 0. Halt the chain to stop new blocks from being generated. Send 400 transactions (i.e., significantly more than `SpamPoWNumberOfTxPerBlock` * `SpamPowNumberOfPastBlocks` through the wallet. After that, allow the chain to resume, and keep sending transactions at a rate of more than 4 in the time a block is processed for at least 100 more blocks. Verify that the user does not get banned, and either sends all transactions eventually, or returns a meaningful error for transactions that are not sent through the chain. (<a name="0011-COSMICELEVATOR-009" href="#0011-COSMICELEVATOR-009">0011-COSMICELEVATOR-009</a>)
1. Set the parameter `SpamPoWNumberOfPastBlocks` to 10, `SpamPoWNumberOfTxPerBlock` to 2, and `spam.pow.increaseDifficulty` to 1. Halt the chain to stop new blocks from being generated. Send 100 transactions (i.e., significantly more than `SpamPoWNumberOfTxPerBlock` * `SpamPowNumberOfPastBlocks` through the wallet. Verify that the wallet does not become unresponsive (this might happen if it tries to perform a proof of work with massively increased difficulty). After that, allow the chain to resume, and keep sending transactions at a rate of more than 4 in the time a block is processed for at least 20 more blocks. Verify that the user does not get banned, and either sends all transactions eventually, or returns a meaningful error for transactions that are not sent through the chain.(<a name="0011-COSMICELEVATOR-010" href="#0011-COSMICELEVATOR-010">0011-COSMICELEVATOR-010</a>)
1. Submit significantly (ten times) more votes than allowed (`SpamProtectionMaxVotes` = 3) for the same proposal at the same time, and verify that the wallet does not allow more than (`SpamProtectionMaxVotes` = 3) to be submitted simultaneously, i.e., does not cause the account to get blocked.(<a name="0011-NP-CLIE-012" href="#0011-NP-CLIE-012">0011-NP-CLIE-012</a>)
1. Submit significantly (ten times) more proposals than allowed (`SpamProtectionMaxProposals` = 3) at the same time (from an account that has more than `SpamProtectionMinTokensForProposal` tokens), and verify that the wallet does not allow more than (`SpamProtectionMaxProposals` = 3) to be submitted simultaneously, i.e., does not cause the account to get blocked.(<a name="0011-NP-CLIE-013" href="#0011-NP-CLIE-013">0011-NP-CLIE-013</a>)
1. Submit significantly (ten times) more delegation changes than allowed (`SpamProtectionMaxDelegations` = 390) at the same time (from an account that has more than `SpamProtectionMinTokensForDelegation` tokens), and verify that the wallet does not allow more than (`SpamProtectionMaxProposals` = 390) to be submitted simultaneously, i.e., does not cause the account to get blocked.(<a name="0011-NP-CLIE-014" href="#0011-NP-CLIE-014">0011-NP-CLIE-014</a>)
1. Submit one vote less than (`SpamProtectionMaxVotes` = 3) , i.e., 2 votes in the same epoch. Once all votes are processed, submit 2 new votes at once (still in the same epoch). Verify that the wallet does not allow more than 1 to be submitted simultaneously, i.e., does not cause the account to get blocked. Submit 2 new simultaneous votes on that proposal in the next epoch and verify that the wallet allows it (and the account does not get blocked)(<a name="0011-NP-CLIE-015" href="#0011-NP-CLIE-015">0011-NP-CLIE-015</a>)
1. Submit one proposal less than (`SpamProtectionMaxProposals` = 3) , i.e., 2 proposals in an epoch from an account that has more than `SpamProtectionMinTokensForProposal` tokens). Once all proposals are processed, submit 2 new proposals at once (still in the same epoch). Verify that the wallet does not allow more than 1 proposal to be submitted simultaneously, i.e., does not cause the account to get blocked. Submit 2 new proposals at the same time in the next epoch and verify that the wallet allows it (and the account does not get blocked)(<a name="0011-NP-CLIE-016" href="#0011-NP-CLIE-016">0011-NP-CLIE-016</a>)
1. Submit one delegation less than (`SpamProtectionMaxDelegations` = 10) , i.e., 9 delegations in the same epoch from an account that has more than `SpamProtectionMinTokensForDelegation` tokens). Once all delegations are processed, submit 5 new delegations at once (still in the same epoch). Verify that the wallet does not allow more than 1 delegation to be submitted simultaneously, i.e., does not cause the account to get blocked. Submit 10 new delegations at once in the next epoch and verify that the wallet allows it (and the account does not get blocked).(<a name="0011-NP-CLIE-017" href="#0011-NP-CLIE-017">0011-NP-CLIE-017</a>)
1. Create a key with sufficient tokens to be allowed to submit proposals and delegations (i.e., more than `SpamProtectionMinTokensForDelegation` and `SpamProtectionMinTokensForProposal`. Submit random (but valid) votes, delegation changes, transactions and proposals in sets of at least 13 each at the same time, at a rate of one set per second. Let that run for 4 epochs, with an epoch length of at least 100 blocks. Verify that the wallet returns an error for the excess transactions OR reprocesses the transactions. Verify the account never gets banned, and that the client never crashed. (<a name="0011-NP-CLIE-018" href="#0011-NP-CLIE-018">0011-NP-CLIE-018</a>)
1. Create 20 keys with sufficient tokens to be allowed proposals and delegations (i.e., more than `SpamProtectionMinTokensForDelegation` and `SpamProtectionMinTokensForProposal`. For all keys (within their respective wallets), submit random (but valid) votes, delegation changes, transactions and proposals in sets of at least 13 each at the same time, at a rate of one set per second. Let that run for 4 epochs, with an epoch length of at least 100 blocks. Verify that the wallet returns an error for the excess transactions OR reprocesses the transactions. Verify that no account ever gets banned, and that the clients never crash. (<a name="0011-NP-CLIE-019" href="#0011-NP-CLIE-019">0011-NP-CLIE-019</a>)

### Wallet service

This acts as a guideline to implement network-based (remote) wallet management applications with third-party applications.

#### API v1

DEPRECATED: The wallet API v1 is no longer officially supported. The desktop wallet not longer support sending transaction using the API v1. The CLI wallet still expose this API, but updates to the API V2 are not back ported to API V1. Once the browser wallet is officially released, the API v1 will be removed from all wallet software.

- As a user, I can create a new account on the Wallet service (account creation requirement to be implementation details)  (<a name="0022-AUTH-001" href="#0022-AUTH-001">0022-AUTH-001</a>)
- As a user, I can login to the Wallet service with my wallet name and password (<a name="0022-AUTH-002" href="#0022-AUTH-002">0022-AUTH-002</a>)
- As a user, I can logout of the Wallet service with a token given to me at login (<a name="0022-AUTH-003" href="#0022-AUTH-003">0022-AUTH-003</a>)
- As a user, if I'm logged in, I can create a new party (with a key pair) for for my account on the Wallet service. (<a name="0022-AUTH-004" href="#0022-AUTH-004">0022-AUTH-004</a>)
- As a user, if I'm logged in, I can list all my parties (and their key pairs) on the Wallet service (<a name="0022-AUTH-005" href="#0022-AUTH-005">0022-AUTH-005</a>)
- As a user, if I'm logged in, I can create a signature for a blob of data, using one of my parties (and its key pair). (<a name="0022-AUTH-007" href="#0022-AUTH-007">0022-AUTH-007</a>)

#### API v2

These acceptance criteria do not account for the authentication scheme between the wallet application and the third-party application. This is left to the implementation.

##### Knowing the connected network

- As a third-party application, I can query chain ID the wallet management application is connected to.

##### Initiating a connection

- As a third-party application, I can connect to a wallet.
- As a user, I can accept the connection request from a third-party application, select the wallet I want to use with that third-party application.
- As a user, I can reject the connection request from a third-party application.

##### Listing the keys

- As a third-party application, I can list the keys the user gave me access to.
- As a user, I can grant access to my wallet's public keys to a third-party application. Granting that access to that third-party application doesn't grant access to other third-party applications. The access is granted per third-party applications.
- As a user, I can deny access to my wallet's public keys to a third-party application. Denying that access to that third-party application doesn't deny access to other third-party applications. The access is denied per third-party applications.

#### Signing transaction

- As a third-party application, I can request the signing of a transaction, and get the resulting signed transaction. The transaction should not be sent to the network.
- As a user, I can accept the signing of a transaction.
- As a user, I can reject the signing of a transaction.

#### Checking transaction

- As a third-party application, I can request the checking of a transaction, and get the resulting signed transaction, if valid. The transaction should not be sent to the network.
- As a user, I can accept the checking of a transaction.
- As a user, I can reject the checking of a transaction.

#### Sending transaction

- As a third-party application, I can request the sending of a transaction, and get the resulting transaction hash. The transaction should be sent to the network.
- As a user, I can accept the sending of a transaction.
- As a user, I can reject the sending of a transaction.
