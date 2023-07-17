# On Chain Referral Program Specification

## Summary

The aim of the on-chain referral program is to allow users of the protocol to incentivise users and community members to refer new traders by voting to provide benefits for referrers and/or referees. 

Whilst a referral program is active, the following benefits may be available to eligible parties:

- a **referrer** will receive a proportion of all referee taker fees as a **reward**.
- a **referee** will be eligible for a **discount** on any taker fees they incur.

The size of the reward or discount will be dependent on the benefit tier the referee's [team](#team-mechanics) is currently placed in. A team becomes eligible for greater benefits by reaching a minimum running volume over a number of epochs. Both referrers and referees contribute to their team's running volume.

On-chain referral programs can be created and updated through [governance proposals](#governance-proposals).

## Network Parameters

- `referralProgram.maxBenefitTiers` - limits the maximum number of [benefit tiers](#benefit-tiers) which can be specified as part of a referral program
- `referralProgram.maxReferralRewardFactor` - limits the maximum reward factor which can be specified as part of a referral program
- `referralProgram.maxReferralDiscountFactor` - limits the maximum discount factor which can be specified as part of a referral program governance proposal
- `referralProgram.maxPartyVolumePerEpoch` - limits the volume in quantum units which is eligible each epoch for referral program mechanisms
- `referralProgram.minStakedVegaTokens` - limits team creation to parties staking at least this number of tokens

## Governance Proposals

Enabling or changing the terms of the on-chain referral program can be proposed via governance. As part of the proposal, the proposer specifies the following fields:

- `benefit_tiers`: a list of dictionaries with the following fields
  - `minimum_running_volume`: the required `running_team_volume` in quantum units for a team to access this tier
  - `referral_reward_factor`: the proportion of the referees taker fees to be rewarded to the referrer
  - `referral_discount_factor`: the proportion of the referees taker fees to be discounted
- `closing_timestamp`: the timestamp after which when the current epoch ends, the programs status will become `STATE_CLOSED` and benefits will be disabled
- `window_length`:  the number of epochs over which to evaluate a teams running volume

```protobuf
message UpdateReferralProgram{
    changes: UpdateReferralProgramConfiguration{
        benefit_tiers: [
            {
                "minimum_running_volume": 10000,
                "referral_reward_factor": 0.000,
                "referral_discount_factor": 0.000,
            },
            {
                "minimum_running_volume": 20000,
                "referral_reward_factor": 0.005,
                "referral_discount_factor": 0.005,
            },
            {
                "minimum_running_volume": 30000,
                "referral_reward_factor": 0.010,
                "referral_discount_factor": 0.010,
            },
        ],
        closing_timestamp: 123456789,
        window_length: 7,
    }
}
```

When submitting a referral program proposal through governance the following conditions apply:
- a proposer cannot set an `closing_timestamp` less than the proposals `enactment_time`.
- the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `referralProgram.maxBenefitTiers`.
- all `referral_reward_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `referralProgram.maxReferralRewardFactor`.
- all `referral_discount_factor` values must be greater than or equal to `0` and be less than or equal to the network parameter `referralProgram.maxReferralDiscountFactor`.
- `window_length` must be an integer strictly greater than zero.

The referral program will start the epoch after the `enactment_timestamp` is reached.

## Referral Program Lifecycle:

After a referral program [proposal](#governance-proposals) is validated and accepted by the network, the network referral program is created / updated and can be one of the following states. The current state of the network referral program should be exposed via an API.

| Status               | Benefits Enabled | Condition for entry                                       | Condition for exit                                                |
| -------------------- | ---------------- | --------------------------------------------------------- | ----------------------------------------------------------------- |
| `STATUS_PROPOSED`    | No               | Governance proposal valid and accepted                    | Governance proposal voting period ends (or proposal is invalid)   |
| `STATUS_REJECTED`    | No               | Governance vote fails (or is invalid)                     | New governance proposal submitted to the network                 |
| `STATUS_PENDING`     | No               | Governance vote passes                                    | End of epoch after network reaches proposal `enactment_timestamp` |
| `STATUS_ACTIVE`      | Yes              | Previously `STATUS_PENDING`                               | End of epoch after network reaches proposal `closing_timestamp`   |
| `STATUS_CLOSED`      | No               | Previously `STATUS_ACTIVE`                                | New governance proposal submitted to the network                  |              

## Team Mechanics
A team is comprised of a referrer and all their referees. There can only ever be one referrer per team but the number of referees is unlimited.

### Creating / updating a team

To create a team and generate a referral code, a party must fulfil the following criteria:

- party must not currently be a **referrer**
- party must not currently be a **referee**
- party must be staking at least `referralProgram.minStakedVegaTokens` tokens.
- party must not have a liquidity provision in any of the following states:
    - `STATUS_ACTIVE`
    - `STATUS_PENDING`
    - `STATUS_UNDEPLOYED`

This staking requirement is constant. If a referrer un-stakes enough tokens to fall below the requirement, they and their referees will no long be eligible for program benefits. If the referrer re-stakes enough tokens to fulfil the staking requirement, the team will become eligible for referral program benefits.

To generate a team id / referral code, the party must submit a signed `CreateTeam` transaction with the following optional team information.

- name: an optional team name to be added to the referral banner.
- teamUrl: an optional link to a team forum, discord, etc.
- avatarUrl: an optional url to an image to be used as the teams avatar

```protobuf
message CreateTeam
    name: "VegaRocks",
    teamUrl: https://discord.com/channels/vegarocks
    avatarUrl: https://vega-rocks/logo-360x360.jpg
```

If a party which is already a referrer submits a `CreateTeam` transaction, their team metadata is simply updated.

### Joining a team

To join a team the party must fulfil the following criteria:
- party must not currently be a **referrer**
- party must not currently be a **referee**
- party must not have a liquidity provision in any of the following states:
    - `STATUS_ACTIVE`
    - `STATUS_PENDING`
    - `STATUS_UNDEPLOYED`

To become a referee, a referee must submit a signed `JoinTeam` transaction with the following fields:
- `id`: the id of the team they want to join (same as the referral code)

```protobuf
message JoinTeam{
    id: "abcd3fgh1jklmn0pqf5tuvwzyz"
}
```

A user should also be able to do this process by approving a transaction from a dApp.

### Team epoch and running volumes
Whilst a referral program is `STATUS_ACTIVE`, the network must track the cumulative volume of trades for each party in that epoch, call this value `party_epoch_volume`. Each time a trade is generated, the network should increment a parties `party_epoch_volume` by the quantum volume of the trade. Note, for a spot market, the quantum is the quantum of the asset used to express the price (i.e. the [quote_asset](./0080-SPOT-product_builtin_spot.md/#1-product-parameters)).

```pseudo
party_epoch_volume = party_epoch_volume + (trade_price * trade_size * settlement_asset_quantum)
```

At the end of an epoch, for each team, a `team_epoch_volume` is calculated by summing each team members `party_epoch_volume`. The amount a party can contribute to their teams volume however is capped by the network parameter `referralProgram.maxPartyVolumePerEpoch`. (Note this cap should not be directly to `party_epoch_volume` in case the network parameter is updated during an epoch).

```pseudo
team_epoch_volume = sum[min(party_epoch_volume, referralProgram.maxPartyVolumePerEpoch) for each party in team]
```

After the values are calculated, the `team_epoch_volume` is stored by the network and each parties `party_epoch_volume` is reset to `0` ready for the next epoch.

The network can then calculate the teams `team_running_volume` by summing a teams team_epoch_volume values over the last n epochs where n is the `window_length` set in the [governance proposal](#governance-proposals).

### Removing liquidity providers

As stated in [creating a team](#creating--updating-a-team) and [joining a team](#joining-a-team), referrers and referees are restricted from having a liquidity provision in one of the following states:
- `STATUS_ACTIVE`
- `STATUS_PENDING`
- `STATUS_UNDEPLOYED`.

This rule is constant and cannot be broken even after becoming a referrer of referee.

If a current referee becomes a liquidity provider they are simply removed from their team and are no longer eligible for benefits from the referral program.

If a current referrer becomes a liquidity provider, the following actions happen each referees `referral_reward_factor` is set to `0`. At the end of the each epoch, the network should check if the referrer has cancelled their liquidity provision. If they have set each referees `referral_reward_factor` as detailed in [setting benefit factors](#setting-benefit-factors) 

## Benefit mechanics

### Setting benefit factors

Whilst a referral program is `STATUS_ACTIVE`, at the start of an epoch the network must set the `referral_reward_factor` and `referral_discount_factor` for each referee. This is done by identifying a referees team and identifying the teams current benefit tier. A teams benefit tier is defined as the highest tier for which their `team_running_volume` is greater or equal to the tiers `minimum_running_volume`. If a party does not qualify for any tier, both values are set to `0`.

```psuedo
Given:
    benefit_tiers=[
        {
            "minimum_running_volume": 10000,
            "referral_reward_factor": 0.001,
            "referral_discount_factor": 0.001,
        },
        {
            "minimum_running_volume": 20000,
            "referral_reward_factor": 0.005,
            "referral_discount_factor": 0.005,
        },
        {
            "minimum_running_volume": 30000,
            "referral_reward_factor": 0.010,
            "referral_discount_factor": 0.010,
        },
    ]

And:
    team_running_volume=22353

Then:
    referral_reward_factor=0.005
    referral_discount_factor=0.005
```

These benefit factors are then fixed for the duration of the next epoch.

### Applying benefit factors

Whenever a fee is incurred by a referee (either during continuous trading or on auction exit) the network must apply referral program benefits.

The network can first calculate individual fee components following the [fees specification](./0029-FEES-fees.md#calculating-fees) and apply any usual checks.

The network must then:

- Calculate the rewards due to the referrer.
    ```pseudo
    infrastructure_fee_reward = floor(infrastructure_fee * referral_reward_factor) 
    liquidity_fee_reward = floor(liquidity_fee * referral_reward_factor) 
    maker_fee_reward = floor(maker_fee * referral_reward_factor) 
    ```
- Calculate the discounts due to the referee.
    ```pseudo
    infrastructure_fee_discount = floor(infrastructure_fee * referral_discount_factor)
    liquidity_fee_discount = floor(liquidity_fee * referral_discount_factor)
    maker_fee_discount = floor(maker_fee * referral_discount_factor)
    ```
- And then update the fees.
    ```pseudo
    infrastructure_fee = infrastructure_fee - infrastructure_fee_reward - infrastructure_fee_discount
    liquidity_fee = liquidity_fee - liquidity_fee_reward - liquidity_fee_discount
    maker_fee = maker_fee - maker_fee_reward - maker_fee_discount
    ```

Note the rewards and discounts are floored rather than raised to ensure the final infrastructure fee cannot be negative.

The network can then carry out the normal fee transfers using the updated fee amounts followed by additional transfers from the referees general account to the referrers general account. These transfers will use the following new transfer types.

- `TRANSFER_TYPE_MAKER_FEE_REWARD_PAY`
- `TRANSFER_TYPE_LIQUIDITY_FEE_REWARD_PAY`
- `TRANSFER_TYPE_INFRASTRUCTURE_FEE_REWARD_PAY`

## Acceptance Criteria

### Governance Proposals

1. If an `UpdateReferralProgram` proposal does not fulfil one or more of the following conditions, the proposal should be `STATUS_REJECTED`:
    - the `closing_timestamp` must be less than or equal to the proposals `enactment_time`.
    - the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `referralProgram.maxBenefitTiers`
    - all `referral_reward_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `referralProgram.maxReferralRewardFactor`
    - all `referral_discount_factor` values must be greater than or equal to `0` and be less than or equal to the network parameter `referralProgram.maxReferralDiscountFactor`
    - the `window_length` must be an integer strictly greater than zero.
1. A referral program should be started the first epoch change after the `enactment_datetime` is reached.
1. A referral program should be closed the first epoch change after the `closing_timestamp` is reached.
1. If a referral program is already active and a proposal `enactment_datetime` is reached, the referral program is updated at the next epoch change.
    - Propose program A with `enactment_timestamp` 1st Jan and `closing_timestamp` 31st Dec
    - Proposal for program A accepted and begins first epoch after 1st Jan
    - Propose program B with `enactment_timestamp` 1st June and `closing_timestamp` 31st Aug
    - Proposal for program B accepted and overrides program A the first epoch after 1st June
    - Program is closed first epoch after 31st Aug, there should be no active proposals.

### Team Mechanics

#### Creating / updating a team

1. If a party **is not** currently a referrer, the party can **create** a team, by submitting a signed `CreateParty` transaction.
1. If a party **is** currently a referrer, the party can **update** a team, by submitting a signed `CreateParty` transaction.
1. If one or more of the following conditions are not met, any `CreateParty` transaction should be rejected.
    - party must not currently be a **referee**
    - party must be staking at least `referralProgram.minStakedVegaTokens` tokens.
    - party must not have a liquidity provision in any of the following states:
        - `STATUS_ACTIVE`
        - `STATUS_PENDING`
        - `STATUS_UNDEPLOYED`

#### Joining a team

1. If a party **is not** currently a **referee**, the party can join a team by submitting a signed `JoinParty` transaction.
1. If one or more of the following conditions are not met,  any `JoinParty` transaction should be rejected.
    - a party must not currently be a **referrer**
    - a party must not currently be a **referee**
    - party must not have a liquidity provision in any of the following states:
        - `STATUS_ACTIVE`
        - `STATUS_PENDING`
        - `STATUS_UNDEPLOYED`

#### Team epoch and running volumes

1. Each trade should increment both the maker and taker parties `party_epoch_volume` by the volume of the trade (expressed in quantum units) providing both parties are not members of the same team.
1. At the end of the epoch, the `team_epoch_volume` should be calculated by summing each team members `party_epoch_volume`.
1. A party cannot contribute more than the current network parameter `referralProgram.maxPartyVolumePerEpoch` to their teams `team_epoch_volume`.
1. A teams `team_running_volume` is calculated as the sum of all `team_epoch_volumes` over the last `epoch_window` epochs.

#### Reviewing team members

1. If a **referrer** de-stakes enough tokens to no longer fulfil the `referralProgram.minStakedVegaTokens` requirement, the following actions are taken:
    - volume from any trades involving the party no longer contribute to `party_epoch_volume`
    - the `referral_reward_factor` of all **referees** is set to `0`
    - at the start of the next epoch, the network will evaluate if the **referrer** has re-staked enough tokens. 
1. If a **referrer** becomes a liquidity provider, the following actions are taken.
    - volume from any trades involving the party no longer contribute to `party_epoch_volume`
    - the `referral_reward_factor` of all **referees** is set to `0`
    - at the start of the next epoch, the network will evaluate if the **referrer** has cancelled their liquidity commitment. 
1. If a **referee** becomes a liquidity provider, they are removed from the team.

### Benefit Mechanics

#### Setting benefit factors

1. At the start of an epoch, each referees `referral_reward_factor` and `referral_discount_factor` is reevaluated and fixed for the epoch.
1. A referees `referral_reward_factor` and `referral_discount_factor` is set equal to the factors in the highest benefit tier their team qualifies for.
1. If a referees team does not qualify for the lowest tier, their `referral_reward_factor` and `referral_discount_factor` are both set to `0`.
1. If a referees `referral_reward_factor` or `referral_discount_factor` is set to `0` during an epoch, their factors are not reevaluated until the start of the next epoch.

#### Applying benefit factors

1. Referee discounts are correctly calculated and applied for each taker fee component during continuous trading.
    - infrastructure fee 
    - liquidity fee
    - maker fee
1. Referee discounts are correctly calculated and applied for each taker fee component when exiting an auction.
    - infrastructure fee 
    - liquidity fee
    - maker fee
1. Referrer rewards are correctly calculated and transferred for each taker fee component during continuous trading.
    - infrastructure fee 
    - liquidity fee
    - maker fee
1. Referrer rewards are correctly calculated and transferred for each taker fee component when exiting an auction.
    - infrastructure fee 
    - liquidity fee
    - maker fee

### APIs
The following must be exposed via an API.
1. A list of teams and there comprising **referrer** and **referees**
1. Previous `team_epoch_volume` values and the current `team_running_volume` value for each team
1. The `referral_reward` and `referral_discount` for every trade