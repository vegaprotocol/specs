# Account abstraction

Note: this is a WIP document outlining the features and requirements, not a spec, at this point.


## Background

Vega has the concept of a "party" which is an entity within the system (unrelated to the concept of legal entities) that can to change the state of the system.

Prior to implementation of this feature, parties map 1:1 with owners of public/private Vega keypairs.
This means that there is a single private key which can sign messages to act as any given party.
It also means that all parties can be identified by one (and only one) public key.
The keypair representing a given party cannot be changed.
**As a result, public keys in Vega are currently reused directly as party IDs.**


## Change summary

This PR will add specs for four major changes:

1. Decoupling of party "accounts" from the type of account (e.g. keypair) and implementation detail (e.g. ed25519 public key).

2. Addition of an account type enabling flexible "multisig" functionality.

3. Addition of an account type that allows restriction, permissioning, and delegation of the capability to perform various types of action to to other accounts.

4. Addition of an account type that operates as a non-custodial fund, separating deposits and withdrawals from fund deployment decisions, and only allowing a depositor to withdraw their share of the fund's value.


## Account abstraction requirements

Account abstraction decouples party acccounts as a concept from public/private keypairs. It lays the groundwork for new account types like multisigs and "fund" accounts.

- After this change there will be multiple types of account.

- This means that account IDs will need to change.
  They can no longer be public keys but instead might, for instance, be deterministically generated at account creation time (similar to order IDs).

- It is CRITICAL that ANY account type can be used ANYWHERE that an account is expcted.

- The first type of account will be a standard public/private keypair.

- The other three are described below.

- There will need to be appropriate core and data node APIs for querying accounts and connecting between accounts (for example getting the account ID for a public key).

- Will need a way to wrap to inform Vega of the account to be used.
  For example, whether I am acting theough my pubkey account, a multisig, fund account, etc.
	To prevent excessive complexity, layered wrapping of account types could be done when setting an account up but it would probably make sense to generate a single account ID for each potential destination at that point. Note to review and get comfortable with the approach here.

- There should be a fee and appropriate spam protection to create or update account contructs.

- A portion of the fee could be stored on creation and released if an account is destroyed to encourage not having accounts live forever.

- Destroying an account is only possible for an account with no open positions and no liquidity commitments.

- When destroying an account, an account ID to inherit any and all assets must be specified.
  This may be an insurance pool, network treasury, etc. account.

- Note: all the virtual account types have a "controller" concept that if specified can configure the account, including changing the controller (unless prevented by permissions, see below).
  This could be genericised/abstracted and the same code/functionality reused in all cases.


## Multisig account requirements

Multisig accounts allow an action to be taken by more than one party/account and for actions to require more than one party's approval to happen.

- A mutlisig can be created and is given an ID.
  The account ID for a given multisig never changes once it is assigned.

- A multisig contains a list of one of more accounts plus associated weights (default weight of 1 for all accounts if not specified).

- A threshold integer number of approvals.
  At least this number of the listed accounts must approve a transaction.
  May be blank/zero in which as the number of accounts check automatically passes.

- A threshold weight-fraction for approval.
  At least this frsction of the sum of all  accounts' weights must approve a transaction .
  May be blank/zero in which as the weight check automatically passes.

- If both thresholds are zero than any of the listed accounts can always unilaterally take action.

- A maximum transacton timeout in seconds optionally set at the multisig account level.
  If present and non-zero then a transaction must be approved within this time or it is cancelled.

- A maximum transaction timeout in seconds optionally set on each transaction.
  If present and non-zero then a transaction must be approved within this time or it is cancelled.
  Does not overried the account level timeout, i.e. the timeout applied if both are present is the shorter of the two.

- A controller account ID.
  The controller can be the multisig itself (self controlling) or any other account of any type.
	If not present then the multisig is immutable once created.

- The controller can change the controller account ID.

- The controller can add to and remove from the list of accounts in the multisig.

- The controller can update the weights of each account.

- The controller can change the approval number threshold.

- The controller can change the approcal weight-fraction threshold.

- The controller can change the account-wide timeout.


## Account permissions and restrictions

This feature allows an accounts to be given restricted permission to act, and for the permission to take different types of actions to be delegated to different accounts.

- A permissioned/delegated account can be created and is given an ID.
  The account ID for a given permissioned/delegated account never changes once it is assigned.

- A permissioned/delegated account holds a list of permission rules.

- A permission rule contains:

	- A list of account IDs
	
	- One or more action selectors, which may be any of the below.
	  Note that it may be possible to use transaction types or other data to make specifying this more generic or the list of actions may need to be explicitly coded:

		- Action type TRADING plus either a list of asset IDs, a list of market IDs or ALL

		- Action type PROVIDE_LIQUIDITY, plus either a list of asset IDs, a list of market IDs or ALL

		- Action type MARKET_GOVERNANCE_PROPOSE plus either a list of asset IDs, a list of market IDs or ALL

		- Action type MARKET_GOVERNANCE_VOTE, plus either a list of asset IDs, a list of market IDs or ALL

		- Action type NETWORK_GOVERNANCE_PROPOSE

		- Action type NETWORK_GOVERNANCE_VOTE

		- Action type SINGLE_TRANSFER plus either a list of destination accounts or ALL

		- Action type RECURRING_TRANSFER plus either a list of destination accounts or ALL

		- Action type WITHDRAW plus either a list of destinations or ALL

		- Action type MANAGE_ACCOUNT plus:

			- either ALL or a list of account IDs (that may be being managed)
			
			- either ALL or a list of sub actions from CHANGE_CONTROLLER, MANAGE_MULTISIG_ACCOUNTS_AND_WEIGHTS, MANAGE_MULTISIG_RULES, MANAGE_PERMISSION_RULES, DESTROY_ACCOUNT
	
	- Whether the rule ALLOWS or DENIES the account(s) to take the action.

	- Rules will be evaluated in order.

	- The action is DENIED unless at least one rule ALLOWs it and no rules DENY it.
	  Therefore is no rules match, the actrion is denied.

- A controller account ID.
  The controller can be the multisig itself (self controlling) or any other account of any type.
  If not present then the multisig is immutable once created.

- The controller can change the controller account ID.

- The controller can manage the permission rules.

Example, if a new permissioned accont PPPP is created with two rules:

```
PPPP = CreatedPermissionedAccount {
	rules = [
		Deny { accounts: [AAAA, BBBB], actions: [TRADING(asset=DOGECOIN)] }
		Allow { accounts: [AAAA, BBBB], actions: [TRADING(markets=ALL)] }
	]
}
```

Then as AAAA or BBBB I could send a "wrapped" transaction to act as PPPP (i.e. use PPPP's funds, administer its positions, etc.) on any market that does not settle in DOGECOIN.

Note that when combined with fund accounts, this feature would enable control over which managers of a fund account can operate in which markets, and indeed limit the set of markets or assets on which the fund account can operate, by making the manager account ID a permissioned account.


## Fund accounts

This feature, particularly when used together with the multisig and permissioned acocunts features, allows for a variety of on-chain funds and fund like structures as well as DAO operations to be performed in a completely non-custodial way.

- A fund account can be created and will be given an ID.
  The account ID for a given fund account never changes once it is assigned.

- A fund account has a list of supported collateral assets, or ALL.
  For each supported asset a cap or maximum total deposits (not maximum total value) can be set.
	There can be no cap (any amount of the asset may be added), or the cap can be zero (no more of the asset can be added regardless of how much is currently there or even if funds are removed).

- A fund account has a list of account IDs that can add collateral, or ALL for an unrestricted fund account.

- An account can only add funds if they are on the list or the acount is unresticted.

- An account can only remove funds if they are on the list or the acount is unresticted or they have a non-zero share of the account's existing balance of any asset.

- When an account ID adds collateral its share of the total value of the fund account in that asset is recorded.
  An account ID's share of the fund account for that asset remains constant if the account gains or loses fund through trading, fees, or liquidity provision, etc.

- When collateral is added or removed from the fund account, the shares are adjusted.
  
- New entrants must always have the correct share for the amount added (i.e. added amount as a fraction of the account's total balance of that asset).
	 
- Participants hat remove funds can only remove up to their share multiplied by the total value of the asset.
  Their share is reduced by the fraction of the asset that is removed.

- A fund account has a manager account ID.

- The manager account can deploy funds through trading, liquidity provision, transfers, or by placing funds in other fund accounts.
  Actions of the manager account may be delegated or restricted by making it permissioned account.
	The actions may be performed by a DAO or committee by making it a multisig.
  The manager account could be a multisig with permissions applied, or some combinations of permissions and several multisigs, etc. to create more complex structures.

- The 


## Future work 

- **Data source / Ethereum controlled account.** In future a new account type which can be created from and controlled by a data source (or if that is two ambitious, events from a new Ethereum bridge contract) will allow, for example, an account to be operated from another bridged chain.

- **Two way bridge.** In future the two way bridge will allow account information and potentially even actions beyond withdrawals to flow from Vega to another bridged chain.


## Examples

TODO: some examples of how these can be used together, what this achieves and various use cases we are trying to enabled.

- Liquidity provision fund

- Trading fund

- Fund of funds

- Standard multisig

- Multisig used for key rotation

- Multisig used for social account recovery

- Closed fund (community interested specifically here)

- Market creation DAO

- Trading DAO/fund

- Reward distribution DAO

- etc.....
