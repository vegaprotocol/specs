# On Chain Referral Program Specification

## Summary

The aim of the on-chain referral program is to allow users of the protocol to incentivise users and community members to refer new traders by voting to provide benefits for referrers and/or referees.

Whilst a referral program is active, the following benefits may be available to eligible parties:

- a **referrer** will receive a proportion of all referee taker fees as a **reward**.
- a **referee** will be eligible for a **discount** on any taker fees they incur.

The size of the reward or discount will be dependent on the benefit tier the referee's [team](#team-mechanics) is currently placed in. A team becomes eligible for greater benefits by reaching a minimum running volume over a number of epochs. Both referrers and referees contribute to their team's running volume.

On-chain referral programs can be created and updated through [governance proposals](#governance-proposals).

## Network Parameters

- `referralProgram.maxBenefitTiers` - limits the maximum number of [benefit tiers](#governance-proposals) which can be specified as part of a referral program
- `referralProgram.maxReferralRewardFactor` - limits the maximum reward factor which can be specified as part of a referral program
- `referralProgram.maxReferralDiscountFactor` - limits the maximum discount factor which can be specified as part of a referral program governance proposal
- `referralProgram.maxPartyVolumePerEpoch` - limits the volume in quantum units which is eligible each epoch for referral program mechanisms
- `referralProgram.minStakedVegaTokens` - limits team creation to parties staking at least this number of tokens

## Governance Proposals

Enabling or changing the terms of the on-chain referral program can be proposed via governance. As part of the proposal, the proposer specifies the following fields:

- `benefit_tiers`: a list of dictionaries with the following fields
  - `minimum_running_volume`: the required `running_team_volume` in quantum units for a team to access this tier
  - `minimum_epochs_in_team`: the required number of epochs a referee must have been in a team to access this tier
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
                "minimum_epochs_in_team": 0,
                "referral_reward_factor": 0.001,
                "referral_discount_factor": 0.001,
            },
            {
                "minimum_running_volume": 20000,
                "minimum_epochs_in_team": 7,
                "referral_reward_factor": 0.005,
                "referral_discount_factor": 0.005,
            },
            {
                "minimum_running_volume": 30000,
                "minimum_epochs_in_team": 31,
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
- all `minimum_epochs_in_team` values must be an integer strictly greater than 0
- all `referral_reward_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `referralProgram.maxReferralRewardFactor`.
- all `referral_discount_factor` values must be greater than or equal to `0` and be less than or equal to the network parameter `referralProgram.maxReferralDiscountFactor`.
- `window_length` must be an integer strictly greater than zero.

The referral program will start the epoch after the `enactment_timestamp` is reached.

## Referral program lifecycle

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

### Creating / updating teams

To create a team and generate a referral code, a party must fulfil the following criteria:

- party must not currently be a **referrer**
- party must not currently be a **referee**
- party must be staking at least `referralProgram.minStakedVegaTokens` tokens.
- party must not have an active liquidity provision

The staking requirement is constant. If a referrer un-stakes enough tokens to fall below the requirement, they and their referees will no long be eligible for program benefits. If the referrer re-stakes enough tokens to fulfil the staking requirement, the team will become eligible for referral program benefits. Note, referees will be able to "move team" by submitting a new team.

The liquidity provision restriction is constant, once a party has become a referrer they will be restricted from committing liquidity. Any liquidity provision transactions from a referrer should be rejected.

To generate a team id / referral code, the party must submit a signed `CreateTeam` transaction with the following optional team information.

- `name`: an optional team name to be added to the referral banner.
- `teamUrl`: an optional link to a team forum, discord, etc.
- `avatarUrl`: an optional url to an image to be used as the teams avatar

```protobuf
message CreateTeam
    name: "VegaRocks",
    teamUrl: https://discord.com/channels/vegarocks
    avatarUrl: https://vega-rocks/logo-360x360.jpg
```

If a party which is already a referrer submits a `CreateTeam` transaction, their team metadata is simply updated.

### Joining / moving teams

To join a team the party must fulfil the following criteria:

- party must not currently be a **referrer**
- party must not have an active liquidity provision

The liquidity provision restriction is constant, once a party has become a referee they will be restricted from committing liquidity. Any liquidity provision transactions from a referee should be rejected.

To become a referee, a referee must submit a signed `JoinTeam` transaction with the following fields:

- `id`: the id of the team they want to join (same as the referral code)

```protobuf
message JoinTeam{
    id: "abcd3fgh1jklmn0pqf5tuvwzyz"
}
```

If a party is already a referee, and submits another `JoinTeam` transaction, their membership will be transferred to the new team at the end start of the next epoch. Note, if the referee has submitted multiple transactions in an epoch, the referee will be transferred using the latest valid transaction.

## Disbanding a team

If a referrer needs to to disband a `Team` (either to join a team themselves or to become a liquidity provider without creating a new key) they are able to submit a `DisbandTeam` transaction. If a party submits a `DisbandTeam` transaction and is not currently a referrer then the transaction should be rejected.

If a referrer disbands a team, the transaction is only enacted at the end of the current epoch. Referees are still eligible for discounts for the duration of the current epoch. At the end of the epoch, all referees are disassociated from the team and if they have any pending `JoinTeam` proposals then these are applied.

Note, once a team disbandment message is submitted and accepted by the network, it cannot be cancelled.

### Party epoch volumes

Whilst a referral program or [volume discount program](./0083-VDPR-volume_discount_program.md) is `STATUS_ACTIVE`, the network must track the cumulative volume of trades for each party in that epoch, call this value `party_epoch_volume`. Each time a trade is generated, the network should increment a parties `party_epoch_volume` by the quantum volume of the trade. For a spot market, the quantum is the quantum of the asset used to express the price (i.e. the [quote_asset](./0080-SPOT-product_builtin_spot.md/#1-product-parameters)).

```pseudo
party_epoch_volume = party_epoch_volume + (trade_price * trade_size * settlement_asset_quantum)
```

At the end of an epoch, the `party_epoch_value` is stored by the network and each parties `party_epoch_value` is reset to `0` ready for the next epoch.

### Team epoch and running volumes

At the end of an epoch, for each team, a `team_epoch_volume` is calculated by summing each team members `party_epoch_volume`. The amount a party can contribute to their teams volume however is capped by the network parameter `referralProgram.maxPartyVolumePerEpoch`. (Note this cap should not be directly to `party_epoch_volume` in case the network parameter is updated during an epoch).

```pseudo
team_epoch_volume = sum[min(party_epoch_volume, referralProgram.maxPartyVolumePerEpoch) for each party in team]
```

After the values are calculated, the `team_epoch_volume` is stored by the network.

The network can then calculate the teams `team_running_volume` by summing a teams `team_epoch_volume` values over the last n epochs where n is the `window_length` set in the [governance proposal](#governance-proposals).

## Benefit mechanics

### Setting benefit factors

Whilst a referral program is `STATUS_ACTIVE`, at the start of an epoch (after pending `JoinTeam` transactions have been processed) the network must set the `referral_reward_factor` and `referral_discount_factor` for each referee.

#### Setting the referral reward factor

The `referral_reward_factor` should be set by identifying the "highest" benefit tier where the following conditions are fulfilled.

- `team_running_volume` is greater than the tiers `minimum_running_volume`.

The referees `referral_reward_factor` is then set to the `referral_reward_factor` defined in the selected benefit tier.

#### Setting the referral discount factor

The `referral_discount_factor` should be set by identifying the "highest" benefit tier where **BOTH** the following conditions are fulfilled.

- `team_running_volume` is greater than the tiers `minimum_running_volume`.
- the referee has been a member of the team for more than the tiers `minimum_epochs_in_team`.

The referees `referral_discount_factor` is then set to the `referral_discount_factor` defined in the selected benefit tier.

#### Example

```pseudo
Given:
    benefit_tiers: [
        {
            "minimum_running_volume": 10000,
            "minimum_epochs_in_team": 0,
            "referral_reward_factor": 0.001,
            "referral_discount_factor": 0.001,
        },
        {
            "minimum_running_volume": 20000,
            "minimum_epochs_in_team": 7,
            "referral_reward_factor": 0.005,
            "referral_discount_factor": 0.005,
        },
        {
            "minimum_running_volume": 30000,
            "minimum_epochs_in_team": 31,
            "referral_reward_factor": 0.010,
            "referral_discount_factor": 0.010,
        },
    ]

And:
    team_running_volume=22353
    party_epochs_in_team=4

Then:
    referral_reward_factor=0.005
    referral_discount_factor=0.001
```

These benefit factors are then fixed for the duration of the next epoch.

### Applying benefit factors

Referral program benefit factors are applied by modifying [the fees](./0029-FEES-fees.md) paid by a party (either during continuous trading or on auction exit).


## APIs

The Teams API should expose the following information:

- a list of all **teams** (by `id`) and the following information:
  - the teams founding **referrer**
  - the teams **referees** and their current number of epochs in the team
- a list of all **teams** (by `id`) and the following metrics:
  - current `team_running_volume` (value at the start of the epoch)
  - current `referral_reward_factor` applied to referee taker fees
  - current `referral_discount_factor` applied to referee taker fees
  - any data required for additional reward metrics

The Trades API should now also expose the following additional information for every trade:

- Referral program rewards
  - `infrastructure_fee_reward`
  - `liquidity_fee_reward`
  - `maker_fee_reward`
- Referral program discounts
  - `infrastructure_fee_discount`
  - `liquidity_fee_discount`
  - `maker_fee_discount`

## Acceptance Criteria

### Governance Proposals

1. If an `UpdateReferralProgram` proposal does not fulfil one or more of the following conditions, the proposal should be `STATUS_REJECTED`:
    - the `closing_timestamp` must be less than or equal to the proposals `enactment_time`.
    - the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `referralProgram.maxBenefitTiers`.
    - all `minimum_epochs_in_team` values must be an integer strictly greater than 0.
    - all `referral_reward_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `referralProgram.maxReferralRewardFactor`.
    - all `referral_discount_factor` values must be greater than or equal to `0` and be less than or equal to the network parameter `referralProgram.maxReferralDiscountFactor`.
    - the `window_length` must be an integer strictly greater than zero.
1. A referral program should be started the first epoch change after the `enactment_datetime` is reached.
1. A referral program should be closed the first epoch change after the `closing_timestamp` is reached.
1. If a referral program is already active and a proposal `enactment_datetime` is reached, the referral program is updated at the next epoch change.
    - Propose program A with `enactment_timestamp` 1st Jan and `closing_timestamp` 31st Dec.
    - Proposal for program A accepted and begins first epoch after 1st Jan.
    - Propose program B with `enactment_timestamp` 1st June and `closing_timestamp` 31st Aug.
    - Proposal for program B accepted and overrides program A the first epoch after 1st June.
    - Program is closed first epoch after 31st Aug, there should be no active proposals.

### Team Mechanics

#### Creating / updating teams

1. If a party **is not** currently a referrer, the party can **create** a team, by submitting a signed `CreateTeam` transaction.
1. If a party **is** currently a referrer, the party can **update** a team, by submitting a signed `CreateTeam` transaction.
1. If one or more of the following conditions are not met, any `CreateTeam` transaction should be rejected.
    - party must not currently be a **referee**.
    - party must be staking at least `referralProgram.minStakedVegaTokens` tokens.
    - party must not have an active liquidity provision.
1. If a referrer removes sufficient stake to not meet the required tokens, the referrers team should not be eligible for the following referral program benefits:
    - team member trades should not contribute to their teams volume.
    - the referrer should not be rewarded for any referee taker fees.
    - referees should not receive any discount on their taker fees.
1. If the referrer of a team currently not eligible for benefits re-stakes enough tokens, their team will become eligible for benefits from the next epoch.

1. If a party has created a team (i.e. is a referrer) any future liquidity provision transactions from the party should be rejected.

#### Joining / moving teams

1. If a party **is not** currently a **referee**, the party can join a team by submitting a signed `JoinTeam` transaction.
1. If a party **is** currently a **referee**, the party can move team (at the start of the next epoch) by submitting a signed `JoinTeam` transaction.
1. If a party **is** currently a **referee** and submits multiple `JoinTeam` transactions in an epoch, the latest valid `JoinTeam` transaction will be applied.
1. If one or more of the following conditions are not met,  any `JoinTeam` transaction should be rejected.
    - a party must not currently be a **referrer**.
    - party must not have an active liquidity provision.
1. If a party has joined a team (i.e. is a referee) any future liquidity provision transactions from the party should be rejected.

#### Disbanding teams

1. If a party **is** currently a **referrer**, the party can disband a team by submitting a signed `DisbandTeam` transaction.
1. The party will be disbanded at the end of the current epoch at which point all referees and referrers will be disassociated from the team.
1. If a party **is not** currently a **referrer**, they should be able to create a new team after disbanding a team, their `Create` transaction should be accepted (providing it is valid).
1. If a party **is not** currently a **referee**, they should not be able to join a disbanded team, their `JoinTeam` transaction should be rejected.
1. If a party **is** currently a **referee**, they should not be able to move to a disbanded team, their `JoinTeam` transaction should be rejected.

#### Team epoch and running volumes

1. Each trade should increment both the maker and taker parties `party_epoch_volume` by the volume of the trade (expressed in quantum units) providing both parties are not members of the same team.
1. At the end of the epoch, the `team_epoch_volume` should be calculated by summing each team members `party_epoch_volume`.
1. A party cannot contribute more than the current network parameter `referralProgram.maxPartyVolumePerEpoch` to their teams `team_epoch_volume`.
1. A teams `team_running_volume` is calculated as the sum of all `team_epoch_volumes` over the last `epoch_window` epochs.

### Benefit Mechanics

#### Setting benefit factors

1. At the start of an epoch, each referees `referral_reward_factor` and `referral_discount_factor` is reevaluated and fixed for the epoch.
1. At the start of an epoch, a referees `referral_reward_factor` is set equal to the factor in the highest benefit tier they qualify for.
1. At the start of an epoch, a referees `referral_discount_factor` is set equal to the factor in the highest benefit tier they qualify for.
1. If when evaluating the tier to set the `referral_reward_factor`, a referee does not qualify for any tier, their `referral_reward_factor` is set to `0`.
1. If when evaluating the tier to set the `referral_discount_factor`, a referee does not qualify for any tier, their `referral_reward_factor` is set to `0`.

