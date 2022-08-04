# Staking

Staking is the act of securing a Vega network by nominating good validators with the [governance token](../protocol/0071-STAK-erc20_governance_token_staking.md). Staking is rewarded with a share of trading fees (and [treasury rewards](../0056-REWA-rewards_overview.md)). See the [glossary](../glossaries/staking-and-governance.md) and [these specs](../protocol#delegation-staking-and-rewards) for more on staking.

When staking a user may be motivated to select validators to maximize the rewards they get for the tokens they hold, this means selecting validator(s) who are less likely to be penalized (e.g. over staked, poor performance). Users may wish to stake more than one validator to diversify. Users will want/need to manage their stake over time to ensure they are getting a good return, e.g. move stake between validators. Staking is also important for facilitating protocol upgrades.

## Understand staking on Vega

When considering whether to stake on Vega, I...

- **must** see information to help inform me what return I might expect from staking (other protocols might show a typical APY) <a name="1002-STKE-001" href="#1002-STKE-001">1002-STKE-001</a>
- **must** see that the governance token is an ethereum ERC20 token and needs to attributed (or associated) to a Vega wallet for use on Vega <a name="1002-STKE-002" href="#1002-STKE-002">1002-STKE-002</a>
- **must** see detailed documentation on how staking works on Vega <a name="1002-STKE-003" href="#1002-STKE-003">1002-STKE-003</a>

...so I can decide if I want to stake on Vega, and how to go about doing it.

Note: There are many ways that "understanding the return" can be done, and this does not impose a particular solution. Solutions could...

- look at previous epochs,
- average this over a period,
- select a range of validators or just one,
- could have a calculator that allows the user to enter some values or just show this on the list of validators

Note: Income may come in a range of different tokens, as markets can settle in different assets, and there may be rewards paid out by the treasury.

## Associate tokens

Before I stake, I need to [Associate tokens](./1000-ASSO-associate.md) with a Vega wallet/key...

- See [Associate tokens](./1000-ASSO-associate.md)
- **should** see that if no further action is taken, newly associated tokens will be nominated to validators based on existing distribution <a name="1002-STKE-004" href="#1002-STKE-004">1002-STKE-004</a>

...so that I can nominate validators.

## Select validator(s)

When selecting what validators to nominate with my stake, I...

- can see all validator information without having to connect Vega wallet <a name="1002-STKE-050" href="#1002-STKE-050">1002-STKE-050</a>
- can see "static" information about the validator
  - name <a name="1002-STKE-006" href="#1002-STKE-006">1002-STKE-006</a>
  - ID <a name="1002-STKE-007" href="#1002-STKE-007">1002-STKE-007</a>
  - Vega public key <a name="1002-STKE-008" href="#1002-STKE-008">1002-STKE-008</a>
  - a URL where to find more information about the validator <a name="1002-STKE-009" href="#1002-STKE-009">1002-STKE-009</a>
  - Etherum address <a name="1002-STKE-010" href="#1002-STKE-010">1002-STKE-010</a>
- can see data for the current/next epoch, for each validator
  - **must** see the current "status" (consensus, Ersatz, New etc) <a name="1002-STKE-011" href="#1002-STKE-011">1002-STKE-011</a>
  - **must** see a total stake (inc self stake) <a name="1002-STKE-012" href="#1002-STKE-012">1002-STKE-012</a>
    - **should** see self stake <a name="1002-STKE-013" href="#1002-STKE-013">1002-STKE-013</a>
    - **should** see nominated stake <a name="1002-STKE-014" href="#1002-STKE-014">1002-STKE-014</a>
    - **should** see total stake as a % of total staked across all nodes <a name="1002-STKE-051" href="#1002-STKE-051">1002-STKE-051</a>
  - **must** see total stake change next epoch <a name="1002-STKE-015" href="#1002-STKE-015">1002-STKE-015</a>
    - **should** see self stake <a name="1002-STKE-016" href="#1002-STKE-016">1002-STKE-016</a>
    - **should** see nominated stake <a name="1002-STKE-017" href="#1002-STKE-017">1002-STKE-017</a>
    - **should** see total stake as a % change <a name="1002-STKE-052" href="#1002-STKE-052">1002-STKE-052</a>
  - **must** see the version of Vega they are currently running <a name="1002-STKE-018" href="#1002-STKE-018">1002-STKE-018</a>
  - **must** see the version of Vega they propose running <a name="1002-STKE-019" href="#1002-STKE-019">1002-STKE-019</a>
- can see data for the previous epoch
  - **must** see the overall "score" for a validator for the previous epoch <a name="1002-STKE-020" href="#1002-STKE-020">1002-STKE-020</a>
  - can see all the inputs to that "score"
    - **must** see Ranking score <a name="1002-STKE-021" href="#1002-STKE-021">1002-STKE-021</a>
    - **must** see stake score <a name="1002-STKE-022" href="#1002-STKE-022">1002-STKE-022</a>
    - **must** see performance score <a name="1002-STKE-023" href="#1002-STKE-023">1002-STKE-023</a>
    - **must** see voting score <a name="1002-STKE-024" href="#1002-STKE-024">1002-STKE-024</a>
- can see data for previous epochs
  - **should** see the the overall "score" for all previous epochs for each validator <a name="1002-STKE-025" href="#1002-STKE-025">1002-STKE-025</a>
  - can see a breakdown of all the inputs to that "score" for all previous epochs
    - **should** see Ranking score <a name="1002-STKE-026" href="#1002-STKE-026">1002-STKE-026</a>
    - **should** see stake score <a name="1002-STKE-028" href="#1002-STKE-028">1002-STKE-028</a>
    - **should** see performance score <a name="1002-STKE-029" href="#1002-STKE-029">1002-STKE-029</a>
    - **should** see voting score <a name="1002-STKE-030" href="#1002-STKE-030">1002-STKE-030</a>

...so I can select validators that should give me the biggest return.

## Nominate a validator

Note: User interfaces may use the term "Nominate", technically the function is called "delegate". Delegating tokens to a validator may imply that you also give that validator your vote on proposals, at time of writing, it does not. It only gives them the potential for more "voting power" in the production of blocks.

Within a staking epoch (typically 24 hours) a user can change their nominations many times, however the changes are only effective at the end of the epoch. You will only get rewards for a full epoch staked.

When attributing some (or all of my governance tokens to a given validator), I...

- **must** select a validator I want to nominate <a name="1002-STKE-031" href="#1002-STKE-031">1002-STKE-031</a>
- **must** be [connected to a Vega wallet/key](0002-WCON-connect_vega_wallet.md) that has associated Vega (or Pending association) <a name="1002-STKE-032" href="#1002-STKE-032">1002-STKE-032</a>
- **must** select an amount of tokens <a name="1002-STKE-033" href="#1002-STKE-033">1002-STKE-033</a>
  - **must** be able to populate this the the amount of governance tokens that will be associated but not nominated at the beginning of the next epoch <a name="1002-STKE-034" href="#1002-STKE-034">1002-STKE-034</a>
  - **must** be warned if the amount I am about to nominate is below a minimum amount (spam protection) <a name="1002-STKE-035" href="#1002-STKE-035">1002-STKE-035</a>
  - **must** be warned if the amount I am about to nominate is more than I have associated - nominated at the end of current epoch <a name="1002-STKE-036" href="#1002-STKE-036">1002-STKE-036</a>
- **must** submit the nomination [Vega transactions](0003-WTXN-submit_vega_transaction.md) <a name="1002-STKE-037" href="#1002-STKE-037">1002-STKE-037</a>
- **must** see feedback that my nomination has been registered, and will be processed at the next epoch <a name="1002-STKE-038" href="#1002-STKE-038">1002-STKE-038</a>
- **must** see all my pending nomination changes for the next epoch <a name="1002-STKE-039" href="#1002-STKE-039">1002-STKE-039</a>

...so that I am rewarded for a share based on this validators performance.

## Monitor staking rewards

When checking if im getting the staking return that I was expecting, I...

- See [Staking income](./1002-INCO-income.md)

...so that I can make decisions about my staking, e.g. whether to re-distribute my stake.

## Un-nominate validator

When removing stake from a validator, I...

- **must** select a validator I want to un-nominate <a name="1002-STKE-040" href="#1002-STKE-040">1002-STKE-040</a>
- **must** be [connected to a Vega wallet/key](0002-WCON-connect_vega_wallet.md) <a name="1002-STKE-041" href="#1002-STKE-041">1002-STKE-041</a>
- - **must** have the option of withdrawing nominated amount at the end of the epoch (and maintain the staking income for the current epoch) <a name="1002-STKE-053" href="#1002-STKE-053">1002-STKE-053</a>
- **should** have the option of withdrawing nomination amount now immediately (and forfeit the staking income) <a name="1002-STKE-043" href="#1002-STKE-043">1002-STKE-043</a>
- **must** set an amount to remove from a validator <a name="1002-STKE-044" href="#1002-STKE-044">1002-STKE-044</a>
  - **must** be able populate with the total delegated at the point where un-nominate will happen). <a name="1002-STKE-045" href="#1002-STKE-045">1002-STKE-045</a>
  - **must** be warned if amount is greater than the amount that will be on that validator at the end of the epoch <a name="1002-STKE-046" href="#1002-STKE-046">1002-STKE-046</a>
    <a name="1002-STKE-047" href="#1002-STKE-047">1002-STKE-047</a>
- **must** submit un-nominate [Vega transaction](0003-WTXN-submit_vega_transaction.md). <a name="1002-STKE-048" href="#1002-STKE-048">1002-STKE-048</a>
- **must** see feedback that the un-nomination has been registered, and that the un-nominated amount is now available for re-nomination <a name="1002-STKE-049" href="#1002-STKE-049">1002-STKE-049</a>

... so that I can use this stake for another validator etc.

## Disassociate tokens

Now that I'm done staking the governance tokens I wish to release them to Eth...

See [Associate and disassociate](1000-ASSO-associate.md#disassociate)

...for sale etc.
