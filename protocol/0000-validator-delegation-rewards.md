THIS FILE CAN BE REPLACED BY EDD'S simple-staking-and-delegating.md file.

# Validator and Staking Rewards
This describes the Alpha Mainnet requirements for calculation and distribution of rewards to delegators and validators. For more information on the overall approach, please see this [research document](https://github.com/vegaprotocol/research-internal/blob/master/validator_rewards/ValPol7.pdf).

## Calculation



## Collection and Distribution

A component of the trading fees that are collected from price takers of a market are reserved for rewarding validators and stakers (see [fees](./0029-fees.md)). These fees are denominated in the settlement currencies of the markets and are collected into an infrastructure fee account for that asset.

These fees are "held" in this pool account for a length of time, determined by a network parameter.

They are then distributed to the general accounts of eligible recipients; that is, the validators and delegators, in amounts as per above calculation.