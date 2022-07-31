# Vesting
Some governance tokens may be held by a Vesting contract. This means that can be "owned" by an Ethereum key but not freely transferred until a vesting terms are complete.

## list of tranches

When looking to understand to overall vesting schedule for tokens, I...

- **must** see a list of tranches [1001-VEST-001](#1001-VEST-001 "1001-VEST-001")
- **should** see a visualization of the vesting schedule with a break down of the type of token holders (e.g. team, investors, community) [1001-VEST-002](#1001-VEST-002 "1001-VEST-002")

For each tranche:

- **must** see a tranche number [1001-VEST-003](#1001-VEST-003 "1001-VEST-003")
- **could** see any annotation of what this tranche is about (e.g. community schedule A) [1001-VEST-004](#1001-VEST-004 "1001-VEST-004")
- **must** see a sum of tokens in the tranche [1001-VEST-005](#1001-VEST-005 "1001-VEST-005")
  - **must** see how many tokens in the tranche are locked [1001-VEST-006](#1001-VEST-006 "1001-VEST-006")
  - **must** see how how many tokens in the tranche are redeemable [1001-VEST-007](#1001-VEST-007 "1001-VEST-007")
- **must** see the vesting terms for each tranche [1001-VEST-008](#1001-VEST-008 "1001-VEST-008")
  - **must** see when the tranche starts (or will start) unlocking [1001-VEST-009](#1001-VEST-009 "1001-VEST-009")
  - **must** see when all the tokens in tranche should be unlocked [1001-VEST-010](#1001-VEST-010 "1001-VEST-010")
- **could** see the number of wallets with tokens in each tranche [1001-VEST-011](#1001-VEST-011 "1001-VEST-011")

... so I can understand how circulating supply could change over time.

## details of a tranche 

When looking into a specific tranche, I...

- **must** see all the same details as the [list of tranches](#details-of-a-tranche) [1001-VEST-012](#1001-VEST-012 "1001-VEST-012")
- **must** see a list of ethereum wallets with tokens in this tranche [1001-VEST-013](#1001-VEST-013 "1001-VEST-013")

for each ethereum wallet:

- **must** see the full eth address of the wallet [1001-VEST-014](#1001-VEST-014 "1001-VEST-014")
- **must** see the total tokens this address holds from this tranche [1001-VEST-015](#1001-VEST-015 "1001-VEST-015")
  - **must** see how many tokens in the tranche are locked [1001-VEST-016](#1001-VEST-016 "1001-VEST-016")
  - **must** see how how many tokens in the tranche are redeemable [1001-VEST-017](#1001-VEST-017 "1001-VEST-017")

... so I can see the details of how tokens are distributed in this tranche

## see summary for a given Ethereum key

When looking to see how many tokens I have in total, and how many I might be able to redeem, I...

- **must** be able to [Connect and ethereum wallet](0004-EWAL-connect_ethereum_wallet.md) [1001-VEST-018](#1001-VEST-018 "1001-VEST-018")
- **should** be able input an ethereum address [1001-VEST-019](#1001-VEST-019 "1001-VEST-019")

for the a given Ethereum wallet/address/key:

- **must** see a total of tokens across all tranches [1001-VEST-020](#1001-VEST-020 "1001-VEST-020")
  - **must** see how many tokens across all tranches are locked [1001-VEST-021](#1001-VEST-021 "1001-VEST-021")
  - **must** see how many tokens across all tranches are redeemable [1001-VEST-022](#1001-VEST-022 "1001-VEST-022")
- **must** see a list of tranches this key has tokens in [1001-VEST-023](#1001-VEST-023 "1001-VEST-023")
- **must** see a total of tokens in each tranche [1001-VEST-024](#1001-VEST-024 "1001-VEST-024")
  - **must** see how many tokens in each tranche are locked [1001-VEST-025](#1001-VEST-025 "1001-VEST-025")
  - **must** see how many tokens in each tranche are redeemable [1001-VEST-026](#1001-VEST-026 "1001-VEST-026")
  - **must** see an option to redeem from tranche [1001-VEST-027](#1001-VEST-027 "1001-VEST-027")
  - **must** be warned if amount that can be redeemed from that tranche is greater than the un-associated balance for that Eth key (because this will cause the redeem function to fail) [1001-VEST-028](#1001-VEST-028 "1001-VEST-028")

... so I can easily see how many tokens I have, and can redeem.

## redeem tokens from a tranche
Note: it is not possible to choose how many tokens you redeem from a tranche, instead you select a tranche and the smart contract will attempt to redeem all. However, it will fail if some of the amount it attempts to redeem have been associated to a Vega key. Therefore the job of this page is to help the user work out how many tokens to disassociate before they can successfully redeem.

When looking to redeem tokens, I...

- **must** [connect the ethereum wallet](0004-EWAL-connect_ethereum_wallet.md) that holds tokens [1001-VEST-029](#1001-VEST-029 "1001-VEST-029")
- **must** select a tranche to redeem from [1001-VEST-030](#1001-VEST-030 "1001-VEST-030")
- **must** see the number of tokens that can be redeemed [1001-VEST-031](#1001-VEST-031 "1001-VEST-031")
- **must** submit the redeem from tranche [ethereum transaction](0005-ETXN-submit_ethereum_transaction.md) [1001-VEST-032](#1001-VEST-032 "1001-VEST-032")
- **must** get feedback on the progress of the Ethereum transaction [1001-VEST-033](#1001-VEST-033 "1001-VEST-033")
- **must** see updated balances after redemption [1001-VEST-034](#1001-VEST-034 "1001-VEST-034")

... so that I can use this tokens more generally on Ethereum (transfer to another key etc)