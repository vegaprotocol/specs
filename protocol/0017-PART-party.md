# Party

A party is any entity participating on Vega blockchain with one-to-one mapping between a Vega wallet public key and “party”. Also known as user / trader / participant / voter.

## Summary

A standard party may have:

- 0 or more [accounts](./0013-ACCT-accounts.md). These accounts may contain a balance of a single [asset](./0040-ASSF-asset_framework.md). This is known as [collateral](./0005-COLL-collateral.md)
- positions on 0 or more [markets](./0001-MKTF-market_framework.md)
- orders on 0 or more [markets](./0001-MKTF-market_framework.md)
- 0 or more governance proposals submitted,see [governance](./0028-GOVE-governance.md)

A standard party can:

- [Submit an order](./0025-OCRE-order_submission.md)
- [Amend an order](./0004-AMND-amends.md)
- [Cancel an order](./0033-OCAN-cancel_orders.md)
- [Submit a governance proposal](./0028-GOVE-governance.md)
- [Vote on a governance proposal](./0028-GOVE-governance.md)
- [Commit to provide liquidity on a market](./0044-LIME-lp_mechanics.md#commit-liquidity-network-transaction)

## Guide-level explanation

### Standard party

A standard party is any that is controlled via transactions signed by an [ed25519 keypair](./0067-KEYS-key_management.md). Throughout the specifications, if the term 'party' is used without qualification, it probably means a standard party.

### Special parties

There is currently one 'special' party in Vega. They are controlled by the Vega core, and no entity should be able to perform an action as a special party other than the core. Transactions cannot be submitted via the blockchain as any special party, and there is no keypair specifically associated with a special party.

### 'network' party

The `network` party is a pseudo party. It is used in [position resolution](./0012-POSR-position_resolution.md) to close distressed [positions](./0006-POSI-positions_core.md) or [orders](./0024-OSTA-order_status.md). See [Order Types: Network Orders](./0014-ORDT-order_types.md#network-orders) for more detail on how these orders are used.

## Acceptance Criteria

1. [x] When a [standard party](#standard-party) must be uniquely identified, it must be identified by the public key of an ed25519 keypair (<a name="0017-PART-001" href="#0017-PART-001">0017-PART-001</a>)


Note that when and how a party can submit transactions is set out and restricted in:

- [Transactions](./0049-TVAL-validate_transaction_preconsensus.md)
- [Spam protection](./0062-SPAM-spam_protection.md)
- [Proof of work spam protection](./0072-SPPW-spam-protection-PoW.md)
