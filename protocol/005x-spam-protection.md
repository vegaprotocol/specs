# Spam protection
To operate efficiently, Vega should make an effort to drop transactions that are known not to be useful, without risking dropping valid transactions. To solve this problem, there are a number of mechanisms that build on the existing transaction validation in [0049 - Validate Transactions Preconsensus](./0049-validate-transaction-preconsensus.md):


## 1. Vote spam prevention
 - 1.1 Governance vote
  For each governance parameter, each account has 2 votes per epoch, as well as the possibility to cancel the vote. All further votes are rejected until the next epoch. 
  Adding a PoW (see below) for votes is supported, but not activated in the beginning.
 - 1.2 Delegation Vote
  The number of re-delegates per epoch depends on the amount of represented stake:
   - 1.2.1 Users with up to 100 tokens have 2 (re)delegates
   - 1.2.2 Users with up to 1000 tokens have 3
   - 1.2.3 Users with more than 10000 tokens have 3 per 10000 tokens.
   The rationale is that accounts with few tokens are cheap to generate, but accounts with many tokens will need more redelegation. Precise numbers may still be adapted.
   - 1.2.4 Users can always undelegate-in-anger, though this has to remove all delegation from a validator and thus can be done only once per validator per epoch
 - 1.3 Market votes
   Not relevant for Sweet water. 
## 2. Reject transactions from accounts with no balance
- 2.1 All of the actions that a [party](./0017-party.md) can take require [an account balance](./0013-accounts.md) in at least one asset. For example:
  - 2.1.1 [Proposing a market](./0028-governance.md) requires collateral for the [Liquidity Commitment](./0044-lp-mechanics.md#orders-buy-shapesell-shape), and [governance asset balance](./0028-governance.md)
  - 2.1.2 [Voting on a proposal](./0028-governance.md) requires a [governance asset balance](./0028-governance.md)
  - 2.1.3 [Placing an order](./0011-check-order-allocate-margin.md#outline) requires collateral
  - 2.1.4 [Cancelling an order](./0033-cancel-orders.md) means the user previously had collateral, and will have a margin account balance
  - 2.1.5 [Amending an order](./0033-cancel-orders.md) also the user have a margin account balance
- 2.2 Therefore we can use the existing of accounts as an indicator that the party has previously participated productively in the network. 
- 2.3 If they have no accounts, they therefore have not, and their transaction can be dropped.This should be done without performing and extra
- work such as verifying a signature or paesing the content of the transaction, though the IP adress should be logged.

## 3. Rate limiting on the nodes
- 3.1 A validator node can keep a running total of the transactions for each party, across a number of blocks
- 3.2 Through configuration, a maximum number of transactions for that block-window, for each party, can be set
- 3.3 Any transactions beyond that maximum will be rejected
- 3.4 This should be replaced by [4. client side proof of work](#4-rate-limiting-through-client-side-proof-of-work) when it is specified

## 4. Rate limiting through client-side Proof Of Work

- 4.1 Account quality:
Every account has a quality level that is determined by the investment required to create that account. Accounts with 
a low quality thus are required to do a more difficult proof of work than accounts with a high quality. 
For sweet water, accounts cannot perform any market actions, and thus their quality is entirely determined by
the locked thake these accounts represent.
- 4.2 Proof of Work
The proof of work for a transaction is done in a way similar to bitcoin, i.e., through finding a a nonce to add
to the transaction identifyer so that the hash of (nonce|tid) ends with a number of zeroes depending on the
difficulty level. The hash algorithm used at this time is MD6, primarilty due to the absence of optimised hardware. 
This may change though in future versions and be replaced by a different hash function or a variant of a VDF.
- 4.3 Dynamic Adaption
In a future version, the difficulty of the PoW and other parameters might be changes on the fly depending on network 
load. This needs to be worked out further though, as it causes some issues
  - 4.3.1 To react ro a real attack, an adaption needs to be executed fast. This however can cause old transactions
         to float around that are not adapted to the new PoW difficulty. A fast change of parameters could form a
         DoS in itself
  - 4.3.2 If votes are handeled indepedndently, validators could make it difficult to vote once they're happy
 - 4.4 Other Todos:
  - 4.4.1 Anaylise the Tendermint gossip protocol if there's potential to spam directly on that level
  - 4.4.2 Analyse all buffers if it is possible to fill up buffers through spam
  - 4.4.3 Analyse of there's a possibility to cause computation work, e.g., verifying a lot of signatures
  - 4.4.4 Look into classical DoS attacks on TCP/IP level


