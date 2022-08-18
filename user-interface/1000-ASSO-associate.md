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

- **must** see the contract address for the governance token of the Vega network <a name="1000-ASSO-01" href="#1000-ASSO-01">1000-ASSO-01</a>

...so I can participate in governance and staking.

## Associate

When looking to stake validators or participate in governance, I first need to associate governance tokens with a Vega wallet/key, I...

- **must** [connect an Ethereum wallet/key](0004-EWAL-connect_ethereum_wallet.md) to see tokens it may have in wallet or attributed to it in the vesting contract <a name="1000-ASSO-002" href="#1000-ASSO-002">1000-ASSO-002</a>
- **must** select a Vega key to associate to <a name="1000-ASSO-003" href="#1000-ASSO-003">1000-ASSO-003</a>
  - **must** be able use a [connected Vega wallet](0002-WCON-connect_vega_wallet.md) as instead of manually inputting a public key <a name="1000-ASSO-004" href="#1000-ASSO-004">1000-ASSO-004</a>
  - **should** be able to populate field with a string <a name="1000-ASSO-005" href="#1000-ASSO-005">1000-ASSO-005</a>
- if the connected ethereum wallet has vesting tokens: **must** be able to select to associate from either the vesting contract or the wallet <a name="1000-ASSO-006" href="#1000-ASSO-006">1000-ASSO-006</a>
- **must** see the number of un-associated tokens in the selected wallet/vesting contract <a name="1000-ASSO-007" href="#1000-ASSO-007">1000-ASSO-007</a>
- **must** be select the amount of tokens to associate <a name="1000-ASSO-008" href="#1000-ASSO-008">1000-ASSO-008</a>
  - **must** be able to populate the input with the amount of un-associated tokens for the selected wallet/vesting contract <a name="1000-ASSO-009" href="#1000-ASSO-009">1000-ASSO-009</a>
- **must** be warned if the amount being associated is greater than the amount available in the connected ethereum wallet <a name="1000-ASSO-010" href="#1000-ASSO-010">1000-ASSO-010</a>
- **must** submit the association on [Ethereum transaction(s) inc ERC20 approval if required](0005-ETXN-submit_ethereum_transaction.md) <a name="1000-ASSO-011" href="#1000-ASSO-011">1000-ASSO-011</a>
- **must** see feedback whether my association has been registered on Ethereum <a name="1000-ASSO-012" href="#1000-ASSO-012">1000-ASSO-012</a>
- **must** see feedback that the association has been registered by Vega and that it can be used after the number of Ethereum block confirmations required (typically 50) <a name="1000-ASSO-013" href="#1000-ASSO-013">1000-ASSO-013</a>
  - **should** be able to see a balance for the number of tokens associated and ready for use <a name="1000-ASSO-014" href="#1000-ASSO-014">1000-ASSO-014</a>
  - **should** be able to see a balance for the number of tokens that for each pending association <a name="1000-ASSO-015" href="#1000-ASSO-015">1000-ASSO-015</a>
- on completion: **should** be prompted to go on to [nominate](1002-STAK-staking.md) and/or participate in [Governance](1004-GOVE-governance_list.md) <a name="1000-ASSO-030" href="#1000-ASSO-030">1000-ASSO-030</a>

...so I can then use the Vega wallet to use my tokens.

## Disassociate

When wanting to remove governance tokens, I...

- **must** [connect an Ethereum wallet/key](0004-EWAL-connect_ethereum_wallet.md) to see tokens it may have in wallet or attributed to it in the vesting contract <a name="1000-ASSO-018" href="#1000-ASSO-018">1000-ASSO-018</a>
- **must** see a list Vega keys that the connected Ethereum wallet has associated too <a name="1000-ASSO-019" href="#1000-ASSO-019">1000-ASSO-019</a>
  - **must** see an amount <a name="1000-ASSO-020" href="#1000-ASSO-020">1000-ASSO-020</a>
  - **must** see the full Vega public key associated too <a name="1000-ASSO-021" href="#1000-ASSO-021">1000-ASSO-021</a>
  - **must** see the the origin of the association: wallet or vesting contract <a name="1000-ASSO-022" href="#1000-ASSO-022">1000-ASSO-022</a>
  - **Should** be able to select one row to populate disassociate form <a name="1000-ASSO-023" href="#1000-ASSO-023">1000-ASSO-023</a>
- If some of the tokens for the given eth key are held by the vesting contract: **must** select to return tokens to Vesting contract <a name="1000-ASSO-024" href="#1000-ASSO-024">1000-ASSO-024</a>
- **must** select and amount of tokens to disassociate <a name="1000-ASSO-031" href="#1000-ASSO-031">1000-ASSO-031</a>
  - **must** be able to populate the input with the amount of associated tokens for the selected wallet/vesting contract <a name="1000-ASSO-025" href="#1000-ASSO-025">1000-ASSO-025</a>
- **should** be warned that disassociating will forfeit and rewards for the current epoch and reduce the Vote weigh on any open proposals <a name="1000-ASSO-032" href="#1000-ASSO-032">1000-ASSO-032</a>
- **must** be warned if the inputs on the form will result in an invalid withdraw <a name="1000-ASSO-026" href="#1000-ASSO-026">1000-ASSO-026</a>
- **must** action the disassociation [Ethereum transaction](0005-ETXN-submit_ethereum_transaction.md) <a name="1000-ASSO-027" href="#1000-ASSO-027">1000-ASSO-027</a>
- **must** feedback on the progress of the disassociation on ethereum <a name="1000-ASSO-028" href="#1000-ASSO-028">1000-ASSO-028</a>
- **must** see new associated balances in Vega (theses should be applied instantly) <a name="1000-ASSO-029" href="#1000-ASSO-029">1000-ASSO-029</a>
- on completion (if tokens were returned to vesting contract): **could** be prompted to go on to [redeem](1001-VEST-vesting.md).

...so that I can transfer them to another Ethereum wallet (e.g. sell them on an exchange).
