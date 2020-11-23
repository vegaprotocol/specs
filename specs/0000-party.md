# Party 

A party is...


# Summary

A party may have:
- 0 or more [accounts](./0013-accounts.md)
    - These accounts may contain a balance of a single [asset](./0040-asset-framework). This is known as [collateral](./0005-collateral.md)

A party can:
- [Submit an order](./0025-order-submission.md)
- [Amend an order](./0026-amends.md)
- [Cancel an order](./0033-cancel-orders.md)
- [Submit a governance proposal](./0028-governance.md)
- [Vote on a governance proposal](./0028-governance.md)
- [Commit to provide liquidity on a market](./0038-liquidity-provision-order-type)

# Guide-level explanation

## Special Parties
There are a limited number of 'special' parties in Vega. They are controlled by Vega, and no entity should be able to perform an action as a special party other than Vega.

### 'network' party
The `network` party is a pseudoparty. It is used in [position resolution](./0012/position-resolution.md) to close distressed [positions](./0006-positions-core.md) or [orders](./0024-order-status.md). 

# Acceptance Criteria


## Criteria
1. When a party must be uniquely identified, it must be identified by the public key of an ed25519 keypair
    1. The exception to this rule is [special parties](#special-parties), which are unique strings
        1. A special party must not have a public/private keypair
1. A party with no balance in any account must have their transactions rejected.
1. The special network party...
