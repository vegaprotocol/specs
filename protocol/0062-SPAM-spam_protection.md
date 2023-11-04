# Spam protection

## Governance spam

The spam protection enforcement for governance actions require that a public key must have a set minimum amount of tokens to be allowed to issue a proposal or vote on a proposal (`spam.protection.proposal.min.tokens`/`spam.protection.voting.min.tokens`). If the network detects successful spam in spite of this minimum, then the limit can be increased automatically.

The following three policies are also specific to governance actions:

- Vote transactions can be rejected if a party has less than `spam.protection.voting.min.tokens`.
- Any governance proposal transaction can be rejected if a party has less than `spam.protection.proposal.min.tokens`. Setting these reasonably high provides some level of protection.
- Any qualified voter can vote `spam.protection.max.votes` times per epoch per active proposal (e.g., if it's `3` then one initial vote and 2 follow-on votes to change their mind.

All are network parameters and thus up for discussion/governance vote. A change of parameters takes effect in the epoch following the acceptance of the corresponding proposal.

### Policy Enforcement

The policy enforcement mechanism rejects governance messages that do not follow the anti-spam rules. This can happen in two different ways:

- **pre-block rejection**: A transaction is rejected before it enters the validators' mempool. For Tendermint-internal reasons, this can only happen based on the global state coordinated through the previous block; in particular, it cannot be based on any other transactions received by the validator but not yet put into a block (e.g., only three transactions per party per block). Once a block is scheduled, all validators also test all transactions in their mempool to confirm they are still passing the test, and remove them otherwise.
- **post-block-rejection**: A transaction has made it into the block, but is rejected before it is passed to the application layer. This mechanism allows for more fine-grained policies than the previous one, but at the price that the offending transaction has already taken up space in the blockchain. This is currently not used and only kept in here for reference.

The policies enforced are the following thresholds:

```text
num_votes = 3                         // maximum number of times per epoch a tokenholder van change their vote on an issue
min_voting_tokens = 1                 // minimum tokens required to be allowed to vote
num_proposals = 3                     // maximum number of governance proposals per tokenholder per epoch
min_proposing_tokens = 200000         // minimum amount of tokens required to make governance proposals
max_delegations = 390                 // maximal number of de-delegations per tokenholder per epioch
min_tokens_for_delegation = 1         // minimum number of tokens needed to re-delegate
minimum_withdrawal = 10               // minimum amount of asset withdrawals
min_transfer = 0.1                    // minimum amount of assets for internal transfers
max_transfer_commands_per_epoch = 20  // maximal amount of internal asset transfers per epoch per key
max_batch_size = 15                   // maximal number of transactions allowed in one batch; this is the maximum size of a batch
```

(for consistency reasons, the prevailing source for all parameter values is the [defaults](https://github.com/vegaprotocol/vega/blob/develop/core/netparams/defaults.go)code file. In case of differences, the information in that file is the valid one).

- Any tokenholder with more than `min_voting_tokens` tokens on a public key has `num_votes` voting attempts per epoch and proposal, i.e., they can change their mind `num_votes-1` times in one epoch. This means a transaction is **pre-block rejected** if there are `num_votes` or more on the same proposal in the blockchain in the same epoch.
- A proposal can only be issued by a tokenholder with more than `min_proposing_tokens` associated with one public key at the start of the epoch. Also (like above), only `num_proposals` proposals can be made per tokenholder per epoch. Thus, proposals get **pre-block rejected** if the sum of proposals already in the blockchain for that epoch equals or exceeds `num_proposals`. This parameter is the same for **all proposals**. There also is a separate parameter to the same end that is enforced in the core. For Sweetwater, both these parameters had the same value, but the spam protection value can be set lower, as the amplification effect of a proposal (i.e., a proposal resulting in a very large number of votes) would also then be covered by the core.

### Notes

- What counts is the number of tokens at the beginning of the epoch. While it is unlikely (given gas prices and ETH speed) that the same token is moved around to different entities, this explicitly doesn't work.
- Every tokenholder with more than `min_voting_tokens` can spam exactly one block.
- There is some likelihood that policies will change. It would thus be good to have a clean separation of policy definition and enforcement, so a change in the policies can be implemented and tested independently of the enforcement code.

## Withdrawal spam

As unclaimed withdrawals do not automatically expire, an attacker could generate a large number of messages as well as an ever-growing data structure through [withdrawal requests](0030-ETHM-multisig_control_spec.md).

To avoid this, all withdrawal requests need a minimum withdrawal amount controlled by the network parameter `spam.protection.minimumWithdrawalQuantumMultiple`.

The minimum allowed withdrawal amount is `spam.protection.minimumWithdrawalQuantumMultiple x quantum`, where `quantum` is set per [asset](0040-ASSF-asset_framework.md) and should be thought of as the amount of any asset on Vega that has a rough value of 1 USD.

Any withdrawal request for a smaller amount is immediately rejected.

### Referral spam

The [on-chain referral program](./0083-RFPR-on_chain_referral_program.md) adds three transaction types which can be submitted with no cost/risk to the party:

- `CreateReferralSet`
- `UpdateReferralSet`
- `ApplyReferralCode`

To avoid spamming of `CreateReferralSet` and `UpdateReferralSet` transactions, a party must meet the staked governance tokens ($VEGA) threshold set by the network parameter `referralProgram.minStakedVegaTokens`. A party who does not meet this requirement should have any transactions of the aforementioned types pre-block rejected.

To avoid spamming of `ApplyReferralCode`, a party must meet the deposited funds threshold set by the network parameter `spam.protection.applyReferral.min.funds`.  All assets count towards this threshold and balances should be scaled appropriately by the assets quantum. A party who does not meet this requirement should have any transactions of the aforementioned type pre-block rejected. This requirement will be checked against snapshots of account balances taken at a frequency determined by the network parameter `spam.protection.balanceSnapshotFrequency`. This network parameter is a duration (e.g. `5s`, `1m5s`).

Further, each party is allowed to submit up to `n` transactions per epoch where `n` is controlled by the respective network parameter for that transaction type (`spam.protection.max.CreateReferralSet`, `spam.protection.max.UpdateReferralSet`, `spam.protection.max.ApplyReferralCode`).

### Related topics

- [Spam protection: Proof of work](https://github.com/vegaprotocol/specs/blob/master/protocol/0072-SPPW-spam-protection-PoW.md)
- [Transaction gas and priority](https://github.com/vegaprotocol/specs/blob/master/protocol/0079-TGAP-transaction_gas_and_priority.md)

### Acceptance Criteria

A spam attack using votes/governance proposals is detected and the votes transactions are rejected, i.e., a party that issues too many votes/governance proposals gets the follow-on transactions rejected. This means (given the original parameters from [0054-NETP-network_parameters.md](https://github.com/vegaprotocol/specs-internal/blob/master/protocol/0054-NETP-network_parameters.md))

More than 360 delegation changes in one epoch (or, respectively, the value of `spam.protection.max.delegation`). This includes the undelegate transactions. Specifically, verify:

- More than the allowed quota through delegation change only
- More than the allowed quota through undelegation only (this might require lowering the parameter)
- More than the allowed quota through a mix, where each individual set of messages is within the quota (<a name="0062-SPAM-001" href="#0062-SPAM-001">0062-SPAM-001</a>)
- Delegating while having less than one vega (`10^18` of our smallest unit) (`spam.protection.delegation.min.tokens`)  (<a name="0062-SPAM-002" href="#0062-SPAM-002">0062-SPAM-002</a>)
- Making a proposal when having less than 100.000 vega (`spam.protection.proposal.min.tokens`)  (<a name="0062-SPAM-003" href="#0062-SPAM-003">0062-SPAM-003</a>)
- Changing the value of network parameter `spam.protection.proposal.min.tokens` will immediately change the minimum number of associated tokens needed for any kind of governance proposal. Proposals already active aren't affected.(<a name="0062-SPAM-014" href="#0062-SPAM-014">0062-SPAM-014</a>)
- Transactions creating more than `spam.protection.max.proposals` proposals in one epoch are rejected.  (<a name="0062-SPAM-004" href="#0062-SPAM-004">0062-SPAM-004</a>)
- Transactions submitting votes by parties with less than `spam.protection.voting.min.tokens` of Vega associated are rejected.  (<a name="0062-SPAM-005" href="#0062-SPAM-005">0062-SPAM-005</a>)
- Transactions submitting a vote more than `spam.protection.max.votes` times on any one proposal are rejected. (<a name="0062-SPAM-006" href="#0062-SPAM-006">0062-SPAM-006</a>)
- Any rejection due to spam protection is reported to the user upon transaction submission detailing which criteria the key exceeded / not met  (<a name="0062-SPAM-013" href="#0062-SPAM-013">0062-SPAM-013</a>)
- Try to create a withdrawal bundle for an amount smaller than defined by `spam.protection.minimumWithdrawalQuantumMultiple x quantum` and verify that it is rejected (<a name="0062-SPAM-021" href="#0062-SPAM-021">0062-SPAM-021</a>)
- Try to set `spam.protection.minimumWithdrawalQuantumMultiple` to `0` and verify that the parameter is rejected.(<a name="0062-SPAM-022" href="#0062-SPAM-022">0062-SPAM-022</a>)
- Increase `spam.protection.minimumWithdrawalQuantumMultiple` and verify that a withdrawal transaction that would have been valid according to the former parameter value is rejected with the new one. (<a name="0062-SPAM-023" href="#0062-SPAM-023">0062-SPAM-023</a>)
- Decrease `spam.protection.minimumWithdrawalQuantumMultiple` and verify that a withdrawal transaction that would have been invalid with the old parameter and is valid with the new value and is accepted.(<a name="0062-SPAM-024" href="#0062-SPAM-024">0062-SPAM-024</a>)
- Issue a valid withdrawal bundle. Increase `spam.protection.minimumWithdrawalQuantumMultiple` to a value that would no longer allow the creation of the bundle. Ask for the bundle to be re-issued and verify that it's not rejected. (<a name="0062-PALAZZO-001" href="#0062-PALAZZO-001">0062-PALAZZO-001</a>)
- A party staking less than `referralProgram.minStakedVegaTokens` should have any `CreateReferralSet` transactions **pre-block** rejected (<a name="0062-SPAM-026" href="#0062-SPAM-026">0062-SPAM-026</a>).
- A party staking less than `referralProgram.minStakedVegaTokens` should have any `UpdateReferral` transactions **pre-block** rejected (<a name="0062-SPAM-027" href="#0062-SPAM-027">0062-SPAM-027</a>).
- Given longer than `spam.protection.balanceSnapshotFrequency` has elapsed since a party deposited or transferred funds, a party who has less then `spam.protection.applyReferral.min.funds` in their accounts should have any `ApplyReferralCode` transactions **pre-block** rejected. All assets count towards this threshold and balances should be scaled appropriately by the assets quantum. (<a name="0062-SPAM-028" href="#0062-SPAM-028">0062-SPAM-028</a>).
- A party who has submitted strictly more than `spam.protection.max.CreateReferralSet` `CreateReferralSet` transactions in an epoch should have any future `CreateReferralSet` transactions in that epoch **pre-block** rejected (<a name="0062-SPAM-029" href="#0062-SPAM-029">0062-SPAM-029</a>).
- A party who has submitted more than `spam.protection.max.CreateReferralSet` transactions in the current epoch plus in the current block, should have their transactions submitted in the current block **pre-block** rejected (<a name="0062-SPAM-032" href="#0062-SPAM-032">0062-SPAM-032</a>).
- A party who has submitted strictly more than `spam.protection.max.updateReferralSet` `UpdateReferralSet` transactions in an epoch should have any future `UpdateReferralSet` transactions in that epoch **pre-block** rejected (<a name="0062-SPAM-030" href="#0062-SPAM-030">0062-SPAM-030</a>).
- A party who has submitted more than `spam.protection.max.updateReferralSet` transactions in the current epoch plus in the current block, should have their transactions submitted in the current block **pre-block** rejected (<a name="0062-SPAM-034" href="#0062-SPAM-034">0062-SPAM-034</a>).
- A party who has submitted strictly more than `spam.protection.max.applyReferralCode` `ApplyReferralCode` transactions in an epoch should have any future `ApplyReferralCode` transactions in that epoch **pre-block** rejected (<a name="0062-SPAM-031" href="#0062-SPAM-031">0062-SPAM-031</a>).
- A party who has submitted more than `spam.protection.max.applyReferralCode` transactions in the current epoch plus in the current block, should have their transactions submitted in the current block **pre-block** rejected (<a name="0062-SPAM-036" href="#0062-SPAM-036">0062-SPAM-036</a>).


> **Note**: If other governance functionality (beyond delegation-changes, votes, and proposals) are added, the spec and its acceptance criteria need to be augmented accordingly. This issue will be fixed in a follow up version.
