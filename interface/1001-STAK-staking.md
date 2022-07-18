# Staking

Staking is the act of securing a Vega network by nominating good validators with the governance token. Staking is rewarded with a share of trading fees (and [treasury rewards](../0056-REWA-rewards_overview.md)). See the [glossary](../glossaries/staking-and-governance.md) and [these specs](../protocol#delegation-staking-and-rewards) for more on staking.

When staking a user may be motivated to select validators to maximise the rewards they get for the tokens they hold, this means selecting validator who are less likely to be penalized (e.g. over staked, poor performance). Users may wish to stake more than one validator. Users will want/need to manage their stake over time to ensure they are getting a good return. Staking is also important for protocol upgrades.

Governance tokens are standard ERC20 ethereum tokens, they may be attributed to a wallet in a normal way or be held by the vesting contract, these can also be associated while vesting, but a user will needed to disassociate them before they can be removed from the vesting contract.

## Understand staking on Vega
When considering whether to stake on Vega, I...

- can see information to help inform me on what return I might expect from staking (other protocols might show a typical APY)
- can see that the governance token is an ethereum ERC20 token and needs to attributed (or associated to a Vega wallet for use on Vega)
- can see the ETH address of the token contract
- can see links to documentation on staking on Vega

...so I can decide if I want to stake on Vega, and how to go about doing it

Notes: There are many ways that "understanding the return" can be done, and this does not impose a particular solution. Solutions could...
- look at previous epochs, 
- average this over a period, 
- select a range of validators or just one, 
- could have a calculator that allows the user to enter some values or just show this on the list of validators 
  
Income may come in a range of tokens, as markets can settle in different assets, and there may be rewards paid out by the treasury.

## Associate tokens
See [Associate tokens](./1000-ASSO-associate.md)

## Select validator
When selecting where to place my stake, I...

- can see all the data that goes into a calculation of the staking return
- can see the data for previous epochs
- can see information about the validator
  - name
  - Vega public key
  - a URL where to find more information about the validator

...so I can select validators that should give me the biggest return (or secure/upgrade the network)

## Nominate validator
Note: Interfaces may use the term Nominate, technically the function is called delegate. Delegating tokens to a validator may imply that you also give that validator your vote on proposals, at time of writing, it does not. It only gives them the potential for more "voting power" in the production of blocks.

Within a staking epoch (typically 24 hours) a user can change their nominations many times, however the changes are only effective at the end of the epoch. You will only get rewards for a full epoch staked.

When attributing some (or all of my governance tokens to a given validator), I...

- can select an amount of tokens (with a link to auto populate this with an un-delegated amount)
  - Includes the amount that will be un-delegated this epoch
- am warned if the amount I am about to nominate is invalid. e.g. is...
  - below a minimum amount (spam protection)
  - more than I have associated
  - more than I have un-nominated
- can submit the nomination
- can see feedback that my nomination has been registered, and will be processed at the next epoch
- can see all the pending nomination changes for the next epoch

...so that I am rewarded for a share based on this validators performance

## Monitor staking rewards
When checking if im getting the staking return that I was expecting, I... 

- can see a when the epoch started and should finish 
- Can see the stake i have nominated to 
- see the staking income I have received for each epoch, broken down by...
  - asset
  - validator staked
  - market 
- I can see where I did not receive full income because the validator suffered penalties 

...so that I can make decisions about my staking

## Un-nominate validator

When removing stake from a validator, I...

- can set an amount to remove from a validator (with a link to populate with the maximum amount)
- warned if amount is greater than the amount that will be on that validator at the end of the epoch
- have the option of withdrawing the nomination now or at the end of the epoch (so I get the full epoch reward)
- can submit un-nomination
- see feedback that the un-nomination has been registered

... so that I can use this stake for another validator etc

## Disassociate tokens

When wanting to remove governance tokens, I...

- can (if i have any in vesting contract) select to return tokens to Vesting contract
- can return tokens that are not held by the vesting contract to my ethereum wallet
- can select and amount of tokens to disassociate 
- can action the disassociation on ethereum
- see feedback on the progress of the disassociation 

...so that I can transfer them to another eth wallet (e.g. sell them on an exchange)