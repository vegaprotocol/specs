# Staking

Staking is the act of securing a Vega network by nominating good validators with the governance token. Staking is rewarded with a share of trading fees (and [treasury rewards](../0056-REWA-rewards_overview.md)). See the [glossary](../glossaries/staking-and-governance.md) and [these specs](../protocol#delegation-staking-and-rewards) for more on staking.

When staking a user may be motivated to select validators to maximise the rewards they get for the tokens they hold, this means selecting validator who are less likely to be penalized (e.g. over staked, poor performance). Users may wish to stake more than one validator. Users will want/need to manage their stake over time to ensure they are getting a good return. Staking is also important for protocol upgrades.

Governance tokens are standard ERC20 ethereum tokens, they may be attributed to a wallet in a normal way or be held by the vesting contract, these can also be associated while vesting, but a user will needed to disassociate them before they can be removed from the vesting contract.

## Understand staking on Vega
When considering whether to stake on Vega, I...

- **must** see information to help inform me on what return I might expect from staking (other protocols might show a typical APY) [1002-STAK-0001](#1002-STAK-0001 "1002-STAK-0001")
- **must** see that the governance token is an ethereum ERC20 token and needs to attributed (or associated) to a Vega wallet for use on Vega [1002-STAK-0002](#1002-STAK-0002 "1002-STAK-0002")  
- **must** see the ETH address of the token contract [0000-SORD-0003](#0000-SORD-0003 "0000-SORD-0003") 
- **must** see detailed documentation on how staking works on Vega [0000-SORD-0004](#0000-SORD-0004 "0000-SORD-0004") 

...so I can decide if I want to stake on Vega, and how to go about doing it

Notes: There are many ways that "understanding the return" can be done, and this does not impose a particular solution. Solutions could...
- look at previous epochs, 
- average this over a period, 
- select a range of validators or just one, 
- could have a calculator that allows the user to enter some values or just show this on the list of validators 
  
Income may come in a range of tokens, as markets can settle in different assets, and there may be rewards paid out by the treasury.

## Associate tokens
See [Associate tokens](./1000-ASSO-associate.md) with a Vega wallet/key...

- **should** see that if no further action is taken newly associated tokens will be nominated to validators based on existing distribution 

...so that i know that I do not need to manually re-re-nominate

## Select validator
When selecting where to place my stake, I...

- **must** see the current "status" of each validator [1002-STAK-0005](#1002-STAK-0005 "1002-STAK-0005")
- **must** see information about the validator [1002-STAK-0006](#1002-STAK-0006 "1002-STAK-0006")
  - name 
  - Vega public key
  - a URL where to find more information about the validator

- **must** see the overall "score" for a validator for the previous epoch [1002-STAK-0007](#1002-STAK-0007 "1002-STAK-0007")
- **must** see all the inputs to that "score" [1002-STAK-0008](#1002-STAK-0008 "1002-STAK-0008")

- **must** see the the overall "score" for all previous epochs for each validator [1002-STAK-0009](#1002-STAK-0009 "1002-STAK-0009")
- **must** see a breakdown of all the inputs to that "score" for all previous epochs [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")

...so I can select validators that should give me the biggest return (or secure/upgrade the network)

## Nominate a validator
Note: User interfaces may use the term "Nominate", technically the function is called "delegate". Delegating tokens to a validator may imply that you also give that validator your vote on proposals, at time of writing, it does not. It only gives them the potential for more "voting power" in the production of blocks.

Within a staking epoch (typically 24 hours) a user can change their nominations many times, however the changes are only effective at the end of the epoch. You will only get rewards for a full epoch staked.

When attributing some (or all of my governance tokens to a given validator), I...

- **must** select a validator I want to nominate [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** select an amount of tokens (with a link to auto populate this with the un-delegated amount) [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
  - Includes the amount that will be un-delegated this epoch 
- **must** be warned if the amount I am about to nominate is invalid. e.g. is... 
  - below a minimum amount (spam protection) [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
  - more than I have associated [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
  - more than I have un-nominated [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** submit the nomination [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** see feedback that my nomination has been registered, and will be processed at the next epoch [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** see all the pending nomination changes for the next epoch [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")

...so that I am rewarded for a share based on this validators performance

## Monitor staking rewards
When checking if im getting the staking return that I was expecting, I... 

- See [Staking income](./1002-INCO-income.md)

...so that I can make decisions about my staking, e.g. whether to re-distribute my stake

## Un-nominate validator

When removing stake from a validator, I...

- **must** select a validator I want to un-nominate [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** set an amount to remove from a validator (with a link to populate with the maximum amount) [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** be warned if amount is greater than the amount that will be on that validator at the end of the epoch [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** have the option of withdrawing nominated amount at the end of the epoch (and maintain the staking income for the current epoch) [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **should** have the option of withdrawing nomination amount now immediately (and forefit the staking income) [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** submit un-nomination [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")
- **must** see feedback that the un-nomination has been registered, and that the un-nominated amount is now availible for re-nomination [1002-STAK-0010](#1002-STAK-0010 "1002-STAK-0010")

... so that I can use this stake for another validator etc

## Disassociate tokens

Now that i'm done staking the governance tokens I wish to release them to Eth...

See [Associate](1000-ASSO-associate.md#disassociate)

...for sale etc