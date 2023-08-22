# Volume Discount Program

The volume discount program provides tiered discounts on taker fees to traders. A trader accesses greater discounts by increasing their taker volume over a specified number of epochs.

## Network parameters

- `volumeDiscountProgram.maxBenefitTiers` - limits the maximum number of [benefit tiers](#governance-proposals) which can be specified as part of a volume discount program
- `volumeDiscountProgram.maxVolumeDiscountFactor` - limits the maximum volume discount factor which can be specified as part of a volume discount program

Note, if any of the above mentioned network parameters are updated whilst a volume discount program is active, the active program will not be affected in anyway even if the active program breaches the new network parameter value. The new network parameter value however will be checked on any future [volume discount program proposals](#governance-proposals).

If the community wish to update the volume discount program limits **and** apply these to the existing program, they can do so by first updating the network parameters and then submitting a proposal to update the program (adhering to the new limits).

## Governance proposals

Enabling or changing the terms of the volume discount program can be proposed via governance. As part of the proposal, the proposer specifies the following fields:

- `benefit_tiers`: a list of dictionaries with the following fields
  - `minimum_party_running_notional_taker_volume`: the required `party_running_notional_taker_volume` in quantum units for a party to access this tier
  - `volume_discount_factor`: the proportion of the referees taker fees to be rewarded to the referrer
- `closing_timestamp`: the timestamp after which when the current epoch ends, the programs status will become `STATE_CLOSED` and benefits will be disabled. If this field is empty, the program runs indefinitely.
- `window_length`:  the number of epochs over which to evaluate a parties notional running volume

```protobuf
message UpdateVolumeDiscountProgram{
    changes: UpdateReferralProgramConfiguration{
        benefit_tiers: [
            {
                "minimum_party_running_notional_taker_volume": 1000,
                "volume_discount_factor": 0.001,
            },
            {
                "minimum_party_running_notional_taker_volume": 20000,
                "volume_discount_factor": 0.002,
            },
            {
                "minimum_party_running_notional_taker_volume": 30000,
                "volume_discount_factor": 0.003,
            },
        ],
        closing_timestamp: 123456789,
        window_length: 7,
    }
}
```

When submitting a volume discount program proposal through governance the following conditions apply:

- a proposer cannot set an `closing_timestamp` less than the proposals `enactment_time`.
- the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `volumeDiscountProgram.maxBenefitTiers`.
- all `volume_discount_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `volumeDiscountProgram.maxVolumeDiscountFactor`.
- `window_length` must be an integer strictly greater than zero.

The volume discount program will start the epoch after the `enactment_timestamp` is reached.

## Volume discount program lifecycle

After a volume discount program [proposal](#governance-proposals) is validated and accepted by the network, the network volume discount program is created / updated and can be one of the following states. The current state of the network volume discount program should be exposed via an API.

| Status               | Benefits Enabled | Condition for entry                                       | Condition for exit                                                |
| -------------------- | ---------------- | --------------------------------------------------------- | ----------------------------------------------------------------- |
| `STATUS_INACTIVE`    | No               | No proposal ever submitted, or previous proposal ended    | New governance proposal submitted to the network                  |
| `STATUS_PROPOSED`    | No               | Governance proposal valid and accepted                    | Governance proposal voting period ends (or proposal is invalid)   |
| `STATUS_PENDING`     | No               | Governance vote passes                                    | End of epoch after network reaches proposal `enactment_timestamp` |
| `STATUS_ACTIVE`      | Yes              | Previously `STATUS_PENDING`                               | End of epoch after network reaches proposal `closing_timestamp`   |

## Benefit Mechanics

### Setting benefit factors

At the start of an epoch the network should calculate each parties `party_running_notional_taker_volume` by summing each parties `party_epoch_notional_volume` [values](./0082-RFPR-on_chain_referral_program.md#party-epoch-volumes) over the last n epochs where n is the `window_length` set in the volume discount program [governance proposal](#governance-proposals).

Each parties `volume_discount_factor` is then fixed to the value in the highest benefit tier they qualify for. A parties benefit tier is defined as the highest tier for which their `party_running_notional_taker_volume` is greater or equal to the tiers `minimum_party_running_notional_taker_volume`. If a party does not qualify for any tier, their `volume_discount_factor` is set to `0`.

```pseudo
Given:
    benefit_tiers=[
        {
            "minimum_party_running_notional_taker_volume": 10000,
            "volume_discount_factor": 0.001,
        },
        {
            "minimum_party_running_notional_taker_volume": 20000,
            "volume_discount_factor": 0.005,
        },
        {
            "minimum_party_running_notional_taker_volume": 30000,
            "volume_discount_factor": 0.010,
        },
    ]

And:
    party_running_notional_taker_volume=22353

Then:
    volume_discount_factor=0.005
```

This benefit factor is then fixed for the duration of the next epoch.

### Applying benefit factors

Volume discount program benefit factors are applied by modifying [the fees](./0029-FEES-fees.md) paid by a party (either during continuous trading or on auction exit).

## APIs

The Parties API should expose the following information:

- a list of all **parties** (by `id`) and the following metrics:
  - current `party_running_notional_taker_volume` (value at the start of the epoch)
  - current `volume_discount_factor` applied to fees
  - the total amount discounted for the party

The Trades API should now also expose the following additional information for every trade:

- Volume discount program discounts
  - `infrastructure_fee_volume_discount`
  - `liquidity_fee_volume_discount`
  - `maker_fee_volume_discount`

## Acceptance Criteria

### Governance Proposals

1. If an `UpdateVolumeDiscount` proposal does not fulfil one or more of the following conditions, the proposal should be `STATUS_REJECTED`:
    - the `closing_timestamp` must be less than or equal to the proposals `enactment_time` (<a name="0084-VDPR-001" href="#0084-VDPR-001">0084-VDPR-001</a>).
    - the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `volumeDiscountProgram.maxBenefitTiers` (<a name="0084-VDPR-002" href="#0084-VDPR-002">0084-VDPR-002</a>).
    - all `volume_discount_factor` values must be greater than or equal to `0` and less than or equal to the network parameter `volumeDiscountProgram.maxReferralRewardFactor` (<a name="0084-VDPR-003" href="#0084-VDPR-003">0084-VDPR-003</a>).
    - the `window_length` must be an integer strictly greater than zero (<a name="0084-VDPR-004" href="#0084-VDPR-004">0084-VDPR-004</a>).
1. A volume discount program should be started the first epoch change after the `enactment_datetime` is reached (<a name="0084-VDPR-005" href="#0084-VDPR-005">0084-VDPR-005</a>).
1. A volume discount program should be closed the first epoch change after the `closing_timestamp` is reached (<a name="0084-VDPR-006" href="#0084-VDPR-006">0084-VDPR-006</a>).
1. If a volume discount program is already active and a proposal `enactment_datetime` is reached, the volume discount program is updated at the next epoch change.
    - Propose program A with `enactment_timestamp` 1st Jan and `closing_timestamp` 31st Dec (<a name="0084-VDPR-007" href="#0084-VDPR-007">0084-VDPR-007</a>).
    - Proposal for program A accepted and begins first epoch after 1st Jan (<a name="0084-VDPR-008" href="#0084-VDPR-008">0084-VDPR-008</a>).
    - Propose program B with `enactment_timestamp` 1st June and `closing_timestamp` 31st Aug (<a name="0084-VDPR-009" href="#0084-VDPR-009">0084-VDPR-009</a>).
    - Proposal for program B accepted and overrides program A the first epoch after 1st June (<a name="0084-VDPR-010" href="#0084-VDPR-010">0084-VDPR-010</a>).
    - Program is closed first epoch after 31st Aug, there should be no active proposals (<a name="0084-VDPR-011" href="#0084-VDPR-011">0084-VDPR-011</a>).


### Setting benefit factors

1. At the start of an epoch, each parties `volume_discount_factor` is reevaluated and fixed for the epoch (<a name="0084-VDPR-012" href="#0084-VDPR-012">0084-VDPR-012</a>).
1. A parties `volume_discount_factor`  is set equal to the factors in the highest benefit tier they qualify for (<a name="0084-VDPR-013" href="#0084-VDPR-013">0084-VDPR-013</a>).
1. If a party does not qualify for the lowest tier, their `volume_discount_factor`is set to `0` (<a name="0084-VDPR-014" href="#0084-VDPR-014">0084-VDPR-014</a>).
