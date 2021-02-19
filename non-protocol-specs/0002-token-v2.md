# Token V2

Version 2 of the $VEGA token replaces the existing token and providse two crucial upgrades:

1. It allows for more sophisticated unlocking (vesting) schedules to be implemented and enforced on chain
1. It places the total supply of the token in the control of  network/token holder governance


## 1. Token supply

1. Supply is "fixed" initially at 64,999,723
1. Supply **can** be increased by the community (e.g. multisig control or token holders voting...?) 
1. Supply cannot be changed by the contract owner/administrator


## 2. Migration from Token V1

1. Deployment/activation of the token contract will automatically issue tokens based on the wallet balances of the V1 token at deployment time
1. The contract owner must be able to assign vesting tranche for auto-issued tokens
1. Each address receiving auto-issed tokens may have a different vesting tranche
1. Auto-issued tokens with no assigned vesting tranche must remain locked


## 3. Issuance mechanics

1. The contract owner must be able to assign the ability to issue tokens to new wallets or smart contract addresses ("permitted issuers")
1. The contract owner must be able to revoke the ability to issue tokens from any current permitted issuer address
1. The contract onwer must be able to assign limits per permitted issuer address for total issuance by that address
1. The contract onwer must be able to change the issuance limit for a permitted issuer address
1. When issued, tokens are always issued to a vesting category/tranche OR must be locked until a tranche is assigned
1. Tokens must remain locked until they unlock per the vesting (unlock) rules below, as applied for the tranche they are assigned to (the rules can mean they are immediately unlocked)
1. Tokens cannot be recalled/clawed back or re-issued once issued


## 4. Vesting/unlock tranches and rules

1. New tranches can be created at any time by the contract "owner"
1. Each tranche has a `cliff duration` (i.e. 1 month, 4 months, immediate)
1. Each tranche has a `vesting duration` (i.e. 6 months, 9 months, immediate/all at once)
1. The countdown to unlock (i.e. start of the cliff) is triggered by a manual smart contract call with a `trigger start date/time` parameter, which may be in the past or future
1. Tokens in the tranche start vesting (unlocking) at `trigger start date/time + cliff duration`
1. Tokens in the tranche vest (unlock) linearly (i.e. block-by-block) over the `vesting duration`
    - Therefore: the tranche is 100% vested (unlocked) at `trigger start date/time + cliff duration + vesting duration`


## 5. Future upgrades (nice to have)

1. The token can be upgraded by the community (e.g. multisig control or token holders voting...?) 
1. During an upgrade, all addresses with balances should retain their original balance 
1. During an upgrade, all unlocked tokens should remain unlocked


## 6. Security and control

1. The contract owner must not be able to change anything about tokens that have been issued and unlocked
1. The contract owner must not be able to change the supply of the token
1. The contract owner must not be able to effect a token contract upgrade
1. The contract owner must not be able to modify the functionality of the token contract, except to renounce ownership entirely, for example by assigning a null address as the new contract owner (which would mean the contract owner no longer held any powers)