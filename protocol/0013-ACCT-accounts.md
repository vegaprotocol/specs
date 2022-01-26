Feature name: accounts

# Acceptance Criteria

## All accounts

- [ ] Double entry accounting is maintained at all points. (<a name="0013-ACCT-001" href="#0013-ACCT-001">0013-ACCT-001</a>)
- [ ] Only transfer requests move money between accounts. (<a name="0013-ACCT-002" href="#0013-ACCT-002">0013-ACCT-002</a>)

## Party asset accounts
- [ ] Every party that deposits an asset on Vega will have an asset account created for that asset. (<a name="0013-ACCT-003" href="#0013-ACCT-003">0013-ACCT-003</a>)
  -  [ ] Only one general asset account exists per party per asset. (<a name="0013-ACCT-004" href="#0013-ACCT-004">0013-ACCT-004</a>)
  -  [ ] When a party deposits collateral onto Vega, the asset account will increase in balance by the same amount. (<a name="0013-ACCT-005" href="#0013-ACCT-005">0013-ACCT-005</a>)
  -  [ ] When a party withdraws collateral onto Vega, the asset account for that asset will decrease in balance by the same amount. (<a name="0013-ACCT-006" href="#0013-ACCT-006">0013-ACCT-006</a>) 

## Party margin accounts
- [ ] Every party that submits an order on a market will have a margin account for that market created. (<a name="0013-ACCT-007" href="#0013-ACCT-007">0013-ACCT-007</a>)
- [ ] Each party should only have one margin account per market. (<a name="0013-ACCT-008" href="#0013-ACCT-008">0013-ACCT-008</a>)
- [ ] Cannot have a non-zero balance on a margin account where there's no position / position size = 0 and no active orders. (<a name="0013-ACCT-009" href="#0013-ACCT-009">0013-ACCT-009</a>)
- [ ] Cannot transfer into or out of a margin account where there's no position / position size = 0 and no active orders. (<a name="0013-ACCT-010" href="#0013-ACCT-010">0013-ACCT-010</a>)
- [ ] [Fees earned from liquidity provision](./0044-LIQM-lp_mechanics.md#fees) are paid in to this account. (<a name="0013-ACCT-011" href="#0013-ACCT-011">0013-ACCT-011</a>)

## Party staking accounts
- [ ] Every party that deposits staked asset on Vega will have a stake account created for that asset. (<a name="0013-ACCT-012" href="#0013-ACCT-012">0013-ACCT-012</a>)
  - [ ] Only one staked asset account exists per party per asset. (<a name="0013-ACCT-013" href="#0013-ACCT-013">0013-ACCT-013</a>)
  - [ ] The balance can only be delegated to Validators (<a name="0013-ACCT-014" href="#0013-ACCT-014">0013-ACCT-014</a>)
  - [ ] The balance cannot be traded, or used as margin, or transferred, or withdrawn (<a name="0013-ACCT-015" href="#0013-ACCT-015">0013-ACCT-015</a>)
  - [ ] Delegated stake remains in the trader's staking account (<a name="0013-ACCT-016" href="#0013-ACCT-016">0013-ACCT-016</a>)

One key difference with staking accounts is that the collateral is not held in an asset bridge, but in the [staking bridge](../non-protocol/0006-erc20-governance-token-staking.md). The balance is changed by events on Ethereum, rather than actions taken on the Vega chain.

## Liquidity Provider bond accounts
- [ ] A bond account holds collateral to maintain collateral for [Liquidity Providers](./0044-LIQM-lp_mechanics.md). (<a name="0013-ACCT-017" href="#0013-ACCT-017">0013-ACCT-017</a>)
- [ ] Each party that has placed a [Liquidity Provision order](./0038-OLIQ-liquidity_provision_order_type.md) will have one bond account per market they have provided liquidity to (<a name="0013-ACCT-018" href="#0013-ACCT-018">0013-ACCT-018</a>)
- [ ] [Fees earned from liquidity provision](./0044-LIQM-lp_mechanics.md#fees) are *not* paid in to this bond account - [they are paid in to the _margin_ account for this trader](./0042-LIQF-setting_fees_and_rewarding_lps.md#distributing-fees) (<a name="0013-ACCT-019" href="#0013-ACCT-019">0013-ACCT-019</a>)

## Insurance pool accounts
- [ ] When a market opens for trading, there is an insurance account that is able to be used by that market for every settlement asset of that market. (<a name="0013-ACCT-020" href="#0013-ACCT-020">0013-ACCT-020</a>)
- [ ] Only transfer requests move money in or out of the insurance account. (<a name="0013-ACCT-021" href="#0013-ACCT-021">0013-ACCT-021</a>)
- [ ] When all markets of a risk universe expire and/or are closed, the insurance pool account has its outstanding funds transferred to the [network treasury](./0055-TREA-on_chain_treasury.md) account for the appropriate asset (if it doesn't exist create it).  (<a name="0013-ACCT-022" href="#0013-ACCT-022">0013-ACCT-022</a>)


# Summary

Accounts are used on Vega to maintain a record of the amount of collateral that is deposited and deployed by participants in the market.


# Reference-level explanation

Various actions that occur in the protocol will prompt the creation and/or deletion of accounts. Double entry accounting is maintained at all points.

All accounts must:

- have an initial value of zero for whichever asset it maintains

- only change balance as a response to a valid transfer request that adheres to double entry accounting standards.

- only be created and deleted by transfer requests. Deletion account transfer requests must specify which account should receive any outstanding funds in the account that's being deleted.

## Accounts for assets

**Creation:**

The first time an entity deposits an asset into Vega's collateral smart contract, an asset account is created for that party on Vega and credited with the equivalent amount. 

This account:

* is where the trading profits for all markets that have settlement in that asset will be eventually distributed back to (this occurs when the protocol releases collateral from a margin account)
* is where the protocol searches for collateral if the trader has entered a collateral search zone. 
* is used by all Vega markets with that settlement asset.
* will have it's balance increased or decreased when a party deposits or withdraws that asset from Vega.

**Deletion:**

The core protocol does not require these general asset accounts if they have a balance of zero. 

## Margin accounts

Margin accounts are used by the protocol to maintain [margin requirements](./0010-MARG-margin_orchestration.md) and collect and distribute [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). Each party only needs a margin account created for a market they've ever put an order on.

Moreover, margin accounts are conceptually connected to open positions and given there no such thing as a zero open position a margin account may therefore be transient (i.e. there would be no such thing as a margin account that has a balance of zero).


**Creation:**

When a trader places an order on a market and they do not have a margin account for that market, a margin accounts is created for the trader for each settlement asset of that market. This may be due to either:
* it's the first time a trader has placed an order or;
* they've previously had a margin account but it was deleted for the reason listed below.

**Deletion:**

When a trader no longer has collateral requirements for a  market (because they don't have open positions or active orders), these accounts no longer have utility in the core protocol and may be deleted. Accounts may also be deleted for other reasons (e.g. a system account at the conclusion of a set of [closeouts](./0012-POSR-position_resolution.md)).

If there is a positive balance in an account that is being deleted, that balance should be transferred to the account specified in the transfer request (which for margin accounts will typically be the insurance pool of the market).

## Insurance pools

Every market will have at least one insurance pool account that holds collateral that can be used to cover losses in case of unreasonable market events.

**Creation:**

When a market launches, an insurance pool account is created for that market for each settlement asset. This account is used by the protocol during the collection of [margin requirements](./0010-MARG-margin_orchestration.md) and the collection of [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). 

**Deletion:**

When a market is finalised / closed remaining funds are distributed to the on chain treasury.  This occurs using ledger entries to preserve double entry accounting records within the collateral engine.

# Pseudo-code / Examples

# Test cases

