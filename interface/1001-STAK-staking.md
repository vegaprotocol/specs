# Staking

Staking is the act of securing a Vega network by nominating good validators with the governance token. Staking is rewarded by a share of trading fees (inc treasury rewards). See the [glossary](../glossaries/staking-and-governance.md) and [these specs](../protocol#delegation-staking-and-rewards).

Generally when staking a user may be motivated to select validators to get rewards for the tokens they hold, this means selecting validator who are less likely to be penalized (e.g. over staked, poor performance) or spreading their stake to diversify. Users will want/need to manage their stake to ensure they are getting a good return. Staking is also important in protocol upgrades.

Governance tokens may be held by the vesting contract, These can also be associated, for staking and governance, but a user will needed to disassociate them before they can be removed from the staking contract.

## Understand staking
When considering whether to stake on Vega, I...

- can see information to help inform me on what return I might expect from staking (other protocols might show a typical APY)

...so I can select validators that should give me the biggest return (or secure/upgrade the network)

Notes: There are many ways this can be done, and this does not impose a particular solution. Solutions could look at previous epochs, average this over a period, select a range of validators or just one, could have a calculator that allows the user to enter some values. 
Income may come in a range of tokens, as markets can settle in different assets, and there may be rewards paid out by the treasury.

## Associate tokens
Note: the word "associate" is used in user interfaces, the work stake is used on function names. Stake was avoided in an attempt to prevent people thinking they would get a return only after staking. On Vega Staking = Association + Nomination

When looking to stake validators, I first need to associate Governance tokens with a Vega wallet, I...

- can connect an eth wallet to see tokens it may have in wallet (and the vesting contract)
- can select a Vega key to associate to 

...so I can then use the wallet to 

## Select validator
When selecting where to place my stake, I...

- can see all the data that goes into a calculation of the staking return
- can see the data for previous epochs

...so I can select validators that should give me the biggest return (or secure/upgrade the network)

## Nominate validator
Note: the function on chain is called delegate. Nominate if often used in its place due to the face that the governance token also allows you to vote on proposals. Delegating tokens to a validator does not (at time of writing) give them any governance power beyond that of the "voting power" for blocks.

When attributing some (or all of my governance tokens to a given validator), I...

- can select an amount of tokens (with a link to auto populate this with an un-delegated amount)
  - Includes the amount that will be un-delegated this epoch
- can submit the nomination
- am warned if the amount I am about to nominate is invalid
  - below a minimum amount
  - more than I have associated
  - more than I have un-nominated
- can see feedback that my nomination has been registered, and will be processed at the next epoch

...so that I am rewarded for a share based on this validators performance

## Monitoring staking rewards
When checking if im getting the staking return that I was expecting, I... 

- can see a when the epoch start and finish 
- see the staking income (broken down)

...so that I can make decisions about my staking


## un-nominate validator

When removing stake from a validator, I...

- set an amount to remove from a validator (with a link to populate with the maximum amount)
- warned if amount is invalid
- have the option of
- can submit un-nomination
- feedback on progress

... so that I can use this stake for another validator

## disassociate tokens

When wanting to remove governance tokens, I...

- vesting or not

...so that I can transfer them to another eth wallet (e.g. sell them on an exchange)