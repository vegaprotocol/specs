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


# Acceptance Criteria


## Criteria
1. When a party must be uniquely identified, it must be identified by the public key of an ed25519 keypair
1. A party with no balance in any account must have their transactions rejected.
