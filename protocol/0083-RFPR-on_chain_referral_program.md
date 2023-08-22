# On Chain Referral Program Specification

## Summary

The aim of the on-chain referral program is to allow users of the protocol to incentivise users and community members to refer new traders by voting to provide benefits for referrers and/or referees.

A party will be able to [create a referral code](#creating-a-referral-set) and share this code with referees. Referees who [apply the code](#applying-a-referral-code) will be added to the referrers "referral set".

Whilst a referral program is active, the following benefits may be available to members of a referral set:

- a **referrer** may receive a proportion of all referee taker fees as a **reward**.
- a **referee** may be eligible for a **discount** on any taker fees they incur.

Providing a party has been associated with a referral set for long enough, they will become eligible for greater benefits as their referral sets running taker volume increases.

To create an emphasis on community, collaboration, and competition. Referrers will be able to designate their referral set as a team. Teams will have additional fields which allow them to be visible on leaderboards and later to compete for team based rewards.

![referral-set-hierarchy-diagram](./0083-RFPR-on_chain_referral_program_referral_set_hierarchy.png)

## Glossary

- `referrer`: a party who has generated a referral code for a referral set
- `referee`: a party who has applied a referral code to join a referral set
- `referral_set`: a group comprised of a single referrer and all their referees
- `team`: a `referral_set` which has been designated as a team and enriched with additional details allowing it to be visible on leaderboards.

## Network Parameters

- `referralProgram.maxBenefitTiers` - limits the maximum number of [benefit tiers](#governance-proposals) which can be specified as part of a referral program
- `referralProgram.maxReferralRewardFactor` - limits the maximum reward factor which can be specified as part of a referral program
- `referralProgram.maxReferralDiscountFactor` - limits the maximum discount factor which can be specified as part of a referral program governance proposal
- `referralProgram.maxPartyNotionalVolumeByQuantumPerEpoch` - limits the notional volume in quantum units which is eligible each epoch for referral program mechanisms
- `referralProgram.minStakedVegaTokens` - limits referral code generation to parties staking at least this number of tokens

Note, if any of the above mentioned network parameters are updated whilst a referral program is active, the active program will not be affected in anyway even if the active program breaches the new network parameter value. The new network parameter value however will be checked on any future [referral program proposals](#governance-proposals).

If the community wish to update the referral program limits **and** apply these to the existing program, they can do so by first updating the network parameters and then submitting a proposal to update the program (adhering to the new limits).

## Governance Proposals

Enabling or changing the terms of the on-chain referral program can be proposed via governance. As part of the proposal, the proposer specifies the following fields:

- `benefit_tiers`: a list of dictionaries with the following fields
  - `minimum_running_notional_taker_volume`: the required [`referral_set_running_notional_taker_volume`](#referral-set-volumes) in quantum units for parties to access this tier
  - `minimum_epochs`: the required number of epochs a party must have been in a referral set to access this tier
  - `referral_reward_factor`: the proportion of the referees taker fees to be rewarded to the referrer
  - `referral_discount_factor`: the proportion of the referees taker fees to be discounted
- `closing_timestamp`: the timestamp after which when the current epoch ends, the programs status will become `STATE_CLOSED` and benefits will be disabled
- `window_length`:  the number of epochs over which to evaluate a referral sets running notional taker volume

```protobuf
message UpdateReferralProgram{
    changes: UpdateReferralProgramConfiguration{
        benefit_tiers: [
            {
                "minimum_running_notional_taker_volume": 10000,
                "minimum_epochs": 0,
                "referral_reward_factor": 0.001,
                "referral_discount_factor": 0.001,
            },
            {
                "minimum_running_notional_taker_volume": 20000,
                "minimum_epochs": 7,
                "referral_reward_factor": 0.005,
                "referral_discount_factor": 0.005,
            },
            {
                "minimum_running_notional_taker_volume": 30000,
                "minimum_epochs": 31,
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
- all `minimum_epochs` values must be an integer strictly greater than 0
- all `referral_reward_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `referralProgram.maxReferralRewardFactor`.
- all `referral_discount_factor` values must be greater than or equal to `0` and be less than or equal to the network parameter `referralProgram.maxReferralDiscountFactor`.
- `window_length` must be an integer strictly greater than zero.

The referral program will start the epoch after the `enactment_timestamp` is reached.

## Referral program lifecycle

After a referral program [proposal](#governance-proposals) is validated and accepted by the network, the network referral program is created / updated and can be one of the following states. The current state of the network referral program should be exposed via an API.

| Status               | Benefits Enabled | Condition for entry                                       | Condition for exit                                                |
| -------------------- | ---------------- | --------------------------------------------------------- | ----------------------------------------------------------------- |
| `STATUS_INACTIVE`    | No               | No proposal ever submitted, or previous proposal ended    | New governance proposal submitted to the network                  |
| `STATUS_PROPOSED`    | No               | Governance proposal valid and accepted                    | Governance proposal voting period ends (or proposal is invalid)   |
| `STATUS_PENDING`     | No               | Governance vote passes                                    | End of epoch after network reaches proposal `enactment_timestamp` |
| `STATUS_ACTIVE`      | Yes              | Previously `STATUS_PENDING`                               | End of epoch after network reaches proposal `closing_timestamp`   |

## Referral set mechanics

A referral set is comprised of a referrer and all the referees who have applied the associated referral code. There can only ever be one referrer per referral set but the number of referees is unlimited. Referees can move between referral sets by applying a new referral code.

### Creating a referral set

To create a new referral set and become a referrer, a party must fulfil the following criteria:

- party must not currently be a **referrer**
- party must not currently be a **referee**
- party must be staking at least `referralProgram.minStakedVegaTokens` tokens

The staking requirement is constant. If a referrer un-stakes enough tokens to fall below the requirement, they and their referees will immediately no longer be eligible for referral benefits. If the referrer re-stakes enough tokens to fulfil the staking requirement, they and their referees will become eligible for referral benefits **at the start of the next epoch**. Note, for the case where a party does not re-stake, the protocol will still allow referees to "move" referral sets by [applying](#applying-a-referral-code) a new referral code as normal.

To create a referral set and generate a referral code, the party must submit a signed `CreateReferralSet` transaction. When creating a referral set, a party can optionally designate it as a [team](#glossary) and provide additional team details. When designated as a team a referral set will be visible on leaderboards and in future releases will be eligible for team rewards.  A `CreateReferralSet` transaction has the following fields:

- `is_team`: a boolean defining whether the referral set should be designated as a team
- `team_details`: an optional dictionary defining the teams details (non-optional if `is_team` is `True`)
  - `name`: mandatory string team name
  - `team_url`: optional string of a link to a team forum, discord, etc. (defaults to empty string / none-type)
  - `avatar_url`: optional string of a link to an image to be used as the teams avatar (defaults to empty string / none-type)
  - `closed`: optional boolean, defines whether a team is accepting new members (defaults to false)

*Example: if party wants to create a simple referral set.*

```protobuf
message CreateReferralSet{
    is_team: False
    team_details: None
}
```

*Example: if party wants to create a referral set and designate it as a team.*

```protobuf
message CreateReferralSet{
    is_team: True
    team_details: {
        name: "VegaRocks",
        team_url: "https://discord.com/channels/vegarocks",
        avatar_url: "https://vega-rocks/logo-360x360.jpg",
        closed: False,
}
```

When the network receives a valid `CreateReferralSet` transaction, the network will create a referral set with the referral set `id` as the referral code. Any future parties who [apply](#applying-a-referral-code) the referral code will be added to the referral set.

### Updating a referral set

There are two cases where a referrer may want to update their referral set:

- they want to designate their `referral_set` as a team
- their `referral_set` is already designated as a team and they want to update their `team_details`.

To update a referral set the party submit a signed `UpdateReferralSet` transaction. For the transaction to be valid, the party must be the referrer associated with the referral set. An `UpdateReferralSet` transaction must have the following fields.

- `id`: id of the referral set to update
- `is_team`: a boolean defining whether the party should made into a team visible on leaderboards
- `team_details`: an optional dictionary defining the team
  - `name`: optional string team name
  - `team_url`: optional string of a link to a team forum, discord, etc.
  - `avatar_url`: optional string of a link to an image to be used as the teams avatar
  - `closed`: optional boolean, defines whether a team is accepting new members

```protobuf
message UpdateReferralSet{
    id: "mYr3f3rra15et1d"
    is_team: True
    team_details: {
        name: "VegaRocks",
        team_url: "https://discord.com/channels/vegarocks"
        avatar_url: "https://vega-rocks/logo-360x360.jpg"
        closed: True,
}
```

If a referral set is currently designated as a team, a referrer should be able to "close" their team to any new members by setting the `closed` field to `True`. Note, closing a team is the same as closing a referral set and as such all `ApplyReferralCode` transactions applying the referral code associated with the closed referrals set should be rejected.

If a referral set is currently designated as a team, a party is able to effectively "disband" a team by updating their referral set and setting their `is_team` value to `False`. Note a team should only be "disbanded" and removed from leaderboards at the end of the current epoch after rewards have been distributed.

### Applying a referral code

To apply a referral code and become a referee, a party must fulfil the following criteria:

- party must not currently be a **referrer**

To become a referee, a referee must submit a signed `ApplyReferralCode` transaction with the following fields:

- `referral_code`: the referral code they wish to apply

```protobuf
message ApplyReferralCode{
    id: "mYr3f3rra1c0d3"
}
```

If a party is not currently a referee, they must immediately be added to the referral set and [benefit factors updated](#setting-benefit-factors) accordingly. If a party is already a referee, and submits another `ApplyReferralCode` transaction, they will be transferred to the new referral set at the start of the next epoch. Note, if the referee has submitted multiple transactions in an epoch, the referee will be associated with the set specified in the latest valid transaction.

### Party volumes

The network must now track the cumulative notional volume of taker trades for each party in an epoch, call this value `party_epoch_notional_taker_volume`. Note, trades generated by auction uncrossing are not counted. Each time a eligible trade is generated, the network should increment a parties `party_epoch_notional_taker_volume` by the quantum notional volume of the trade. For a spot market, the quantum is the quantum of the asset used to express the price (i.e. the [quote_asset](./0080-SPOT-product_builtin_spot.md/#1-product-parameters)).

```pseudo
party_epoch_notional_taker_volume = party_epoch_notional_taker_volume + (trade_price * trade_size * settlement_asset_quantum)
```

At the end of an epoch, the `party_epoch_notional_taker_volume` is stored by the network and each parties `party_epoch_notional_taker_volume` is reset to `0` ready for the next epoch.

### Referral set volumes

At the end of an epoch, for each referral set, a `referral_set_epoch_notional_taker_volume` is calculated by summing the `party_epoch_notional_taker_volume` of each party in the referral set (include both referrers and referees). The amount a party can contribute to their referral set is capped by the network parameter `referralProgram.maxPartyNotionalVolumeByQuantumPerEpoch`. Note this cap is not applied directly to `party_epoch_notional_taker_volume` in case the network parameter is updated during an epoch.

```pseudo
referral_set_epoch_notional_taker_volume = sum[min(party_epoch_notional_taker_volume, referralProgram.maxPartyNotionalVolumeByQuantumPerEpoch) for each party in team]
```

After the values are calculated, the `referral_set_epoch_notional_taker_volume` is stored by the network.

The network can then calculate the sets `referral_set_running_notional_taker_volume` by summing the sets `referral_set_epoch_notional_taker_volume` values over the last n epochs where n is the `window_length` set in the [governance proposal](#governance-proposals).

## Benefit mechanics

### Setting benefit factors

Whilst a referral program is `STATUS_ACTIVE`, at the start of an epoch (after pending `ApplyReferralCode` transactions have been processed) the network must set the `referral_reward_factor` and `referral_discount_factor` for each referee.

#### Setting the referral reward factor

The `referral_reward_factor` should be set by identifying the "highest" benefit tier where the following conditions are fulfilled.

- `referral_set_running_notional_taker_volume` is greater than or equal to the tiers `minimum_running_notional_taker_volume`.

The referees `referral_reward_factor` is then set to the `referral_reward_factor` defined in the selected benefit tier.

#### Setting the referral discount factor

The `referral_discount_factor` should be set by identifying the "highest" benefit tier where **BOTH** the following conditions are fulfilled.

- `referral_set_running_notional_taker_volume` is greater than or equal to the tiers `minimum_running_notional_taker_volume`.
- the referee has been a associated with the referral set for at least the tiers `minimum_epochs`.

The referees `referral_discount_factor` is then set to the `referral_discount_factor` defined in the selected benefit tier.

#### Example

```pseudo
Given:
    benefit_tiers: [
        {
            "minimum_running_notional_taker_volume": 10000,
            "minimum_epochs": 0,
            "referral_reward_factor": 0.001,
            "referral_discount_factor": 0.001,
        },
        {
            "minimum_running_notional_taker_volume": 20000,
            "minimum_epochs": 7,
            "referral_reward_factor": 0.005,
            "referral_discount_factor": 0.005,
        },
        {
            "minimum_running_notional_taker_volume": 30000,
            "minimum_epochs": 31,
            "referral_reward_factor": 0.010,
            "referral_discount_factor": 0.010,
        },
    ]

And:
    referral_set_running_notional_taker_volume=22353
    party_epochs_in_referral_set=4

Then:
    referral_reward_factor=0.005
    referral_discount_factor=0.001
```

These benefit factors are then fixed for the duration of the next epoch.

### Applying benefit factors

Referral program benefit factors are applied by modifying [the fees](./0029-FEES-fees.md) paid by a party (either during continuous trading or on auction exit).


## APIs

The Parties API should now return a list of all **parties** (which can be filtered by party `id`) with the following additional information:

- current `id` of the referral set the party is associated with
- current `epochs_in_referral_set`
- current `party_epoch_notional_taker_volume`
- current `referral_reward_factor`
- current `referral_discount_factor`
- for each asset, the total referral rewards generated by the parties taker fees
- for each asset, the total referral discounts applied to the parties taker fees

The ReferralSet API should now expose a list of all **referral sets** (which can be filtered by referral set `id`) with the following information:

- the sets founding **referrer**
- the sets **referees**
- current `referral_set_running_notional_taker_volume`
- current `referral_reward_factor` applied to referee taker fees
- current **maximum possible** `referral_discount_factor` applied to referee taker fees
- for each asset, the total referral rewards generated by all referee taker fees
- for each asset, the total referral discounts applied to all referee taker fees
- whether the referral set has been designated as a team
- any `team_details` if the referral set has been designated as a team.

The Trades API should now expose a list of all **trades** (which can be filtered by trade `id`) with the following additional information:

- Referral program rewards
  - `infrastructure_fee_referral_reward`
  - `liquidity_fee_referral_reward`
  - `maker_fee_referral_reward`
- Referral program discounts
  - `infrastructure_fee_referral_discount`
  - `liquidity_fee_referral_discount`
  - `maker_fee_referral_discount`
- Referral program totals
  - `total_referral_reward`
  - `total_referral_discount`

The Estimate Fees API should now calculate the following additional information:

- Expected referral program rewards
  - `infrastructure_fee_referral_reward`
  - `liquidity_fee_referral_reward`
  - `maker_fee_referral_reward`
- Expected referral program discounts
  - `infrastructure_fee_referral_discount`
  - `liquidity_fee_referral_discount`
  - `maker_fee_referral_discount`
- Expected referral program totals
  - `total_referral_reward`
  - `total_referral_discount`


## Acceptance Criteria

### Governance Proposals

1. If an `UpdateReferralProgram` proposal does not fulfil one or more of the following conditions, the proposal should be `STATUS_REJECTED`:
    - the `closing_timestamp` must be less than or equal to the proposals `enactment_time` (<a name="0083-RFPR-001" href="#0083-RFPR-001">0083-RFPR-001</a>).
    - the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `referralProgram.maxBenefitTiers` (<a name="0083-RFPR-002" href="#0083-RFPR-002">0083-RFPR-002</a>).
    - all `minimum_epochs_in_team` values must be an integer strictly greater than 0 (<a name="0083-RFPR-003" href="#0083-RFPR-003">0083-RFPR-003</a>).
    - all `referral_reward_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `referralProgram.maxReferralRewardFactor` (<a name="0083-RFPR-004" href="#0083-RFPR-004">0083-RFPR-004</a>).
    - all `referral_discount_factor` values must be greater than or equal to `0` and be less than or equal to the network parameter `referralProgram.maxReferralDiscountFactor` (<a name="0083-RFPR-005" href="#0083-RFPR-005">0083-RFPR-005</a>).
    - the `window_length` must be an integer strictly greater than zero (<a name="0083-RFPR-006" href="#0083-RFPR-006">0083-RFPR-006</a>).
1. A referral program should be started the first epoch change after the `enactment_datetime` is reached (<a name="0083-RFPR-007" href="#0083-RFPR-007">0083-RFPR-007</a>).
1. A referral program should be closed the first epoch change after the `closing_timestamp` is reached (<a name="0083-RFPR-008" href="#0083-RFPR-008">0083-RFPR-008</a>).
1. If a referral program is already active and a proposal `enactment_datetime` is reached, the referral program is updated at the next epoch change.
    - Propose program A with `enactment_timestamp` 1st Jan and `closing_timestamp` 31st Dec (<a name="0083-RFPR-009" href="#0083-RFPR-009">0083-RFPR-009</a>).
    - Proposal for program A accepted and begins first epoch after 1st Jan (<a name="0083-RFPR-010" href="#0083-RFPR-010">0083-RFPR-010</a>).
    - Propose program B with `enactment_timestamp` 1st June and `closing_timestamp` 31st Aug (<a name="0083-RFPR-011" href="#0083-RFPR-011">0083-RFPR-011</a>).
    - Proposal for program B accepted and overrides program A the first epoch after 1st June (<a name="0083-RFPR-012" href="#0083-RFPR-012">0083-RFPR-012</a>).
    - Program is closed first epoch after 31st Aug, there should be no active proposals (<a name="0083-RFPR-013" href="#0083-RFPR-013">0083-RFPR-013</a>).

### Referral set mechanics

#### Creating a referral set

1. If a party **is not** currently a referrer, the party can **create** a referral set, by submitting a signed `CreateReferralSet` transaction (<a name="0083-RFPR-014" href="#0083-RFPR-014">0083-RFPR-014</a>).
1. If one or more of the following conditions are not met, any `CreateReferralCode` transaction should be rejected.
    - party must not currently be a **referrer**.CreateReferralSet (<a name="0083-RFPR-015" href="#0083-RFPR-015">0083-RFPR-015</a>).
    - party must not currently be a **referee** (<a name="0083-RFPR-016" href="#0083-RFPR-016">0083-RFPR-016</a>).
    - party must be staking at least `referralProgram.minStakedVegaTokens` tokens (<a name="0083-RFPR-017" href="#0083-RFPR-017">0083-RFPR-017</a>).
1. If a referrer removes sufficient stake to not meet the required tokens, the referral set should not be eligible for the following referral benefits:
    - the referrer should not be rewarded for any referee taker fees (<a name="0083-RFPR-018" href="#0083-RFPR-018">0083-RFPR-018</a>).
    - all referees should not receive any discount on their taker fees (<a name="0083-RFPR-019" href="#0083-RFPR-019">0083-RFPR-019</a>).
1. If the referrer of a referral set currently not eligible for benefits re-stakes enough tokens, their team will become eligible for benefits from the start of the next epoch (<a name="0083-RFPR-020" href="#0083-RFPR-020">0083-RFPR-020</a>).
1. When creating a referral set a party should be able to designate it as a team. If they do, `team_details` and all nested fields are mandatory (<a name="0083-RFPR-021" href="#0083-RFPR-021">0083-RFPR-021</a>).

#### Updating a referral set

1. If a party is currently a referrer, the party can **update** a referral set by submitting a signed `UpdateReferralSet` transaction (<a name="0083-RFPR-022" href="#0083-RFPR-022">0083-RFPR-022</a>).
1. If a party submits an `UpdateReferralSet` transaction for a referral set they are not the referrer off, the transaction should be rejected (<a name="0083-RFPR-023" href="#0083-RFPR-023">0083-RFPR-023</a>).
1. When updating a referral set a party should be able to designate it as a team. If they do, `team_details` and all nested fields are mandatory (<a name="0083-RFPR-024" href="#0083-RFPR-024">0083-RFPR-024</a>).

#### Applying a referral code

1. If a party **is not** currently a **referee**, the party can immediately become associated with a referral set by submitting a signed `ApplyReferralCode` transaction (<a name="0083-RFPR-025" href="#0083-RFPR-025">0083-RFPR-025</a>).
1. If a party **is** currently a **referee**, the party can become associated with a new referral set (at the start of the next epoch) by submitting a signed `ApplyReferralCode` transaction (<a name="0083-RFPR-026" href="#0083-RFPR-026">0083-RFPR-026</a>).
1. If a party **is** currently a **referee** and submits multiple `ApplyReferralCode` transactions in an epoch, the latest valid `ApplyReferralCode` transaction will be applied (<a name="0083-RFPR-027" href="#0083-RFPR-027">0083-RFPR-027</a>).
1. If one or more of the following conditions are not met,  any `ApplyReferralCode` transaction should be rejected (<a name="0083-RFPR-028" href="#0083-RFPR-028">0083-RFPR-028</a>).
    - a party must not currently be a **referrer** (<a name="0083-RFPR-029" href="#0083-RFPR-029">0083-RFPR-029</a>).
1. If the `id` in the `ApplyReferralCode` transaction is for a referral set which is designated as a team and has set the `team` to closed (<a name="0083-RFPR-030" href="#0083-RFPR-030">0083-RFPR-030</a>).

#### Epoch and running volumes

1. Each trade should increment the taker parties `party_epoch_notional_taker_volume` by the volume of the trade (expressed in quantum units) (<a name="0083-RFPR-031" href="#0083-RFPR-031">0083-RFPR-031</a>).
1. A trade generated during auction uncrossing should not contribute to either parties `party_epoch_notional_taker_volume` (<a name="0083-RFPR-032" href="#0083-RFPR-032">0083-RFPR-032</a>).
1. At the end of the epoch, the `referral_set_epoch_notional_taker_volume` should be correctly calculated by summing each team members `party_epoch_notional_taker_volume` (<a name="0083-RFPR-033" href="#0083-RFPR-033">0083-RFPR-033</a>).
1. A party cannot contribute more than the current network parameter `referralProgram.maxPartyNotionalVolumeByQuantumPerEpoch` to their sets `referral_set_epoch_notional_taker_volume` (<a name="0083-RFPR-034" href="#0083-RFPR-034">0083-RFPR-034</a>).
1. A referral sets `referral_set_running_notional_taker_volume` is calculated as the sum of all `referral_set_epoch_notional_taker_volumes` over the last `epoch_window` epochs (<a name="0083-RFPR-035" href="#0083-RFPR-035">0083-RFPR-035</a>).

### Benefit Mechanics

#### Setting benefit factors

1. At the start of an epoch, each referees `referral_reward_factor` and `referral_discount_factor` is reevaluated and fixed for the epoch (<a name="0083-RFPR-036" href="#0083-RFPR-036">0083-RFPR-036</a>).
1. At the start of an epoch, a referees `referral_reward_factor` is set equal to the factor in the highest benefit tier they qualify for (<a name="0083-RFPR-037" href="#0083-RFPR-037">0083-RFPR-037</a>).
1. At the start of an epoch, a referees `referral_discount_factor` is set equal to the factor in the highest benefit tier they qualify for (<a name="0083-RFPR-038" href="#0083-RFPR-038">0083-RFPR-038</a>).
1. If when evaluating the tier to set the `referral_reward_factor`, a referee does not qualify for any tier, their `referral_reward_factor` is set to `0` (<a name="0083-RFPR-039" href="#0083-RFPR-039">0083-RFPR-039</a>).
1. If when evaluating the tier to set the `referral_discount_factor`, a referee does not qualify for any tier, their `referral_reward_factor` is set to `0` (<a name="0083-RFPR-040" href="#0083-RFPR-040">0083-RFPR-040</a>).
