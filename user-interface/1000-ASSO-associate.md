# Associate and disassociate governance tokens with a Vega key
The Governance token on a Vega network is an ERC20 ethereyn token. It has two utilities on Vega, 
- Staking the Proof of stake network,
- Participating in Governance.

To use the Governance token on a Vega network it first needs to be associated with a Vega key/party. This Vega key can then stake, propose and vote.

The word "associate" is used in some user interfaces, as apposed the word "stake" in function names. Stake can be avoided to prevent users thinking they would get a return only after the staking step. On Vega `Staking = Association + Nomination`, as in you need to run the "stake " function on Ethereum but then the nominate step on Vega before you get staking income. See [Glossary](../glossaries/staking-and-governance.md).

Associate tokens also count as vote weight in on-Vega governance (new markets etc), A parties vote weight is back by the number of Governance tokens associated with that Vega key/party.

Associating tokens to a Vega key is a little like depositing, except, a deposit can only be released by the Vega network, where as an association can be revoked on ethereum by the the eth key that did the association.

Governance tokens may be held by a [Vesting contract](1001-VEST-vesting.md).

## Token discovery
When looking to acquire governance tokens, I...

- **must** see the contract address for the governance token of the Vega network [1000-ASSO-01](#1000-ASSO-01 "1000-ASSO-01")

...so I can participate in governance and staking.

## Associate
When looking to stake validators or participate in governance, I first need to associate governance tokens with a Vega wallet/key, I...

- **must** [connect an Ethereum wallet/key](0004-EWAL-connect_ethereum_wallet.md) to see tokens it may have in wallet or attributed to it in the vesting contract [1000-ASSO-002](#1000-ASSO-002 "1000-ASSO-002")
- **must** select a Vega key to associate to [1000-ASSO-003](#1000-ASSO-003 "1000-ASSO-003")
  - **must** be able use the [connected Vega wallet](0002-WCON-connect_vega_wallet.md) as instead of manually inputting a public key [1000-ASSO-004](#1000-ASSO-004 "1000-ASSO-004")
  - **should** be able to populate field with a string [1000-ASSO-005](#1000-ASSO-005 "1000-ASSO-005")
- if the connected ethereum wallet has vesting tokens: **must** be able to select to associate from either the vesting contract or the wallet  [1000-ASSO-006](#1000-ASSO-006 "1000-ASSO-006")
- **must** see the number of un-associated tokens in the selected wallet/vesting contract [1000-ASSO-007](#1000-ASSO-007 "1000-ASSO-007")
- **must** be select the amount of tokens to associate [1000-ASSO-008](#1000-ASSO-008 "1000-ASSO-008")
  - **must** be able to populate the input with the amount of un-associated tokens for the selected wallet/vesting contract [1000-ASSO-009](#1000-ASSO-009 "1000-ASSO-009")
- **must** be warned if the amount being associated is greater than the amount [1000-ASSO-010](#1000-ASSO-010 "1000-ASSO-010")
- **must** submit the association on [Ethereum transaction(s) inc ERC20 approval if required](0005-ETXN-submit_ethereum_transaction.md) [1000-ASSO-011](#1000-ASSO-011 "1000-ASSO-011")
- **must** see feedback whether my association has been registered on Ethereum [1000-ASSO-012](#1000-ASSO-012 "1000-ASSO-012")
- **must** see feedback that the association has been registered by Vega and that it can be used after the number of Ethereum block confirmations required (typically 50) [1000-ASSO-013](#1000-ASSO-013 "1000-ASSO-013")
  - **should** be able to see a balance for the number of tokens associated and ready for use [1000-ASSO-014](#1000-ASSO-014 "1000-ASSO-014")
  - **should** be able to see a balance for the number of tokens that for each pending association [1000-ASSO-015](#1000-ASSO-015 "1000-ASSO-015")
- on completion: **should** be prompted to go on to [nominate](1002-STAK-staking.md) and/or participate in [Governance](1004-GOVE-governance_list.md) [1000-ASSO-030](#1000-ASSO-030 "1000-ASSO-030")

...so I can then use the Vega wallet to use my tokens. 


## Disassociate  
When wanting to remove governance tokens, I...

- **must** [connect an Ethereum wallet/key](0004-EWAL-connect_ethereum_wallet.md) to see tokens it may have in wallet or attributed to it in the vesting contract [1000-ASSO-018](#1000-ASSO-018 "1000-ASSO-018")
- **must** see a list Vega keys that the connected Ethereum wallet has associated too [1000-ASSO-019](#1000-ASSO-019 "1000-ASSO-019")
  - **must** see an amount [1000-ASSO-020](#1000-ASSO-020 "1000-ASSO-020")
  - **must** see the full Vega public key associated too [1000-ASSO-021](#1000-ASSO-021 "1000-ASSO-021")
  - **must** see the the origin of the association: wallet or vesting contract [1000-ASSO-022](#1000-ASSO-022 "1000-ASSO-022")
  - **Should** be able to select one row to populate disassociate form [1000-ASSO-023](#1000-ASSO-023 "1000-ASSO-023")
- If some of the tokens for the given eth key are held by the vesting contract: **must** select to return tokens to Vesting contract [1000-ASSO-024](#1000-ASSO-024 "1000-ASSO-024")
- **must** select and amount of tokens to disassociate [1000-ASSO-031](#1000-ASSO-031 "1000-ASSO-031")
  - **must** be able to populate the input with the amount of associated tokens for the selected wallet/vesting contract [1000-ASSO-025](#1000-ASSO-025 "1000-ASSO-025")
- **should** be warned that disassociating will forfeit and rewards for the current epoch and reduce the Vote weigh on any open proposals [1000-ASSO-032](#1000-ASSO-032 "1000-ASSO-032")
- **must** be warned if the inputs on the form will result in an invalid withdraw [1000-ASSO-026](#1000-ASSO-026 "1000-ASSO-026")
- **must** action the disassociation [Ethereum transaction](0005-ETXN-submit_ethereum_transaction.md) [1000-ASSO-027](#1000-ASSO-027 "1000-ASSO-027")
- **must** feedback on the progress of the disassociation on ethereum [1000-ASSO-028](#1000-ASSO-028 "1000-ASSO-028")
- **must** see new associated balances in Vega (theses should be applied instantly) [1000-ASSO-029](#1000-ASSO-029 "1000-ASSO-029")
- on completion (if tokens were returned to vesting contract): **could** be prompted to go on to [redeem](1001-VEST-vesting.md).

...so that I can transfer them to another Ethereum wallet (e.g. sell them on an exchange).