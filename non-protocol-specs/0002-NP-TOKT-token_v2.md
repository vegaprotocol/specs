# Token V2

Version 2 of the $VEGA token replaces the existing token and provides two crucial upgrades:

1. It allows for more sophisticated unlocking (vesting) schedules to be implemented and enforced on chain
1. It places the total supply of the token in the control of  network/token holder governance

## 1. Token supply

1. Supply is fixed initially at `64,999,723`
1. Supply cannot be increased before a date (TBC) known as the `supply fix cut-off date`
1. After the `supply fix cut-off date`, supply **can** be increased by community governance on the Vega chain (i.e. via multisig control)
1. Supply cannot be changed by the contract owner/administrator
1. If supply is ever increased, the issuance of this supply should be done by the Vega chain too (i.e. via multisig control). It is not obvious that we need to enforce this, as long as multisig control can be an allowed issuer.
1. If supply is ever increased, the issuance of this supply must be possible, even if the contract owner has relinquished control.
1. If supply is ever increased, it is most almost certain that it would/should be paid into the bridge and distributed by the Vega protocol from there.

## 2. Migration from Token V1

1. Deployment/activation of the token contract will automatically issue tokens based on the wallet balances of the V1 token at deployment time
1. The contract owner must be able to assign vesting tranches for auto-issued tokens
1. Tokens held by a single address may comprise tokens in multiple tranches
1. Each address receiving auto-issued tokens may have a different vesting tranche
1. Auto-issued tokens with no assigned vesting tranche must remain locked

## 3. Issuance mechanics

1. The contract owner must be able to assign the ability to issue tokens to new wallets or smart contract addresses ("permitted issuers")
1. The contract owner must be able to revoke the ability to issue tokens from any current permitted issuer address
1. The contract owner must be able to assign limits per permitted issuer address for total issuance by that address
1. The contract owner must be able to change the issuance limit for a permitted issuer address
1. When issued, tokens are always issued to a vesting category/tranche OR must be locked until a tranche is assigned
1. An address may have a balance in multiple tranches
1. Tokens must remain locked until they unlock per the vesting (unlock) rules below, as applied for the tranche they are assigned to (the rules can mean they are immediately unlocked)
1. Tokens cannot be recalled/clawed back or re-issued once issued

## 4. Vesting/unlock tranches and rules

1. New tranches can be created at any time by the contract "owner"
1. Each tranche has a `cliff duration` (i.e. 1 month, 4 months, 0 = immediate)
1. Each tranche has a `vesting duration` (i.e. 6 months, 9 months, immediate/all at once)
1. The countdown to unlock (i.e. start of the cliff) is triggered by a manual smart contract call with a `trigger start date/time` parameter, which may be in the past or future
1. Each tranche may be triggered with a different `trigger start date/time` and this may be set at different times for each tranche
1. Tokens in the tranche start vesting (unlocking) at `trigger start date/time + cliff duration`
1. Tokens in the tranche vest (unlock) linearly (i.e. block-by-block) over the `vesting duration`
    - Therefore: the tranche is 100% vested (unlocked) at `trigger start date/time + cliff duration + vesting duration`
1. Unlocked/vested tokens can *never* become locked again
1. The `cliff duration`, `vesting duration` and `trigger start date/time` can be changed before the `trigger start date/time` or if the `trigger start date/time` has not been set
1. Once the `trigger start date/time` has been set and reach (i.e. the cliff/vesting have started), the process must be irreversible and deterministic.

## 5. Future upgrades (nice to have)

1. The token can be upgraded by the community (e.g. multisig control or token holders voting...?)
1. During an upgrade, all addresses with balances should retain their original balance
1. During an upgrade, all unlocked tokens should remain unlocked

## 6. Security and control

1. It should be possible for the contract owner to be a multisig, an instance of multisig control, or another smart contract, if needed
1. The contract owner must not be able to change anything about tokens that have been issued and unlocked
1. The contract owner must not be able to change the supply of the token
1. The contract owner must not be able to effect a token contract upgrade
1. The contract owner must not be able to modify the functionality of the token contract, except to renounce ownership entirely, for example by assigning a null address as the new contract owner (which would mean the contract owner no longer held any powers)

## 7. Staking and delegation

1. Staking mostly occurs on the Vega protocol side, however for two reasons, it *may* be sensible or necessary to include some support for it in the token itself:

    1. We need to support staking of locked tokens
    1. There may be a security advantage to not having staked tokens under the control of the bridge/multisigcontrol (i.e. so that taking over the validators/network would not allow you to also take ownership of **all** staked tokens)

1. It must be possible to stake locked tokens as a validator/for delegation on the Vega network.
1. Unlocked tokens that have been transferred away cannot be or remain staked.
1. Once staked on the Vega side, tokens cannot be allowed to be transferred to another address even if they are unlocked from the perspective of vesting

For instance these goals could be achieved by using a special "stake" function on the smart contract that interacts with the bridge/multisigcontrol to mark them as staked (for either validator staking or delegation), and allowing "unstaking" to occur only from the Vega side, via multisigcontrol. This way even once vested, the tokens would still be marked as staked until the network releases them, and even though the network has control over whether they are staked, it does not hold them in the bridge pool while staked and cannot transfer them.
