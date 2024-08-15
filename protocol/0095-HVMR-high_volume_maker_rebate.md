# High Volume Maker Rebate

The high volume maker rebate program is a network-wide community governed set of parameters to provide an additional reward to market makers on the network who are involved in a significant fraction of all trading on the network. When enabled, eligible market makers receive an additional fraction of trading fees from trades in which they are involved on top of any standard received maker fee (and would receive this even were the default maker fee removed).

## Configuration

The configuration of the High Volume Maker rebate is performed very similarly to that of the [volume discount program](./0084-VDPR-volume_discount_program.md):
Enabling or changing the terms of the program can be proposed via governance. As part of the proposal, the proposer specifies the following fields:

- `benefit_tiers`: a list of dictionaries with the following fields
  - `minimum_party_maker_volume_fraction`: the required `party_maker_volume_fraction` for a party to access this tier
  - `additional_maker_rebate`: the additional rebate factor (in percentage of `trade_value_for_fee_purposes`) a party at this tier will receive when they are the maker side of a trade
- `end_of_program_timestamp`: the timestamp after which when the current epoch ends, the program will become inactive and benefits will be disabled. If this field is empty, the program runs indefinitely.
- `window_length`:  the number of epochs over which to measure a party's cumulative maker volume.


## Calculation

For each party, the network must track the maker volume they created in each epoch.

At the start of an epoch the network should calculate each parties `party_maker_volume_fraction` by calculating what proportion of the maker volume over the last $m$ epochs a party made up (where m is the `window_length` set configured in the program), i.e.

$$\text{partyMakerVolumeFraction}_j = \frac{\sum_{i=1}^{m} V_{i,j}}{\sum_{i=1}^{m} \sum_{k=1}^{n} V_{i,k}}$$

where:

- ${V_i}_j$ is the maker volume of party `j` in epoch `i`


Each parties `additional_maker_rebate` is then fixed to the value in the highest tier they qualify for. A parties tier is defined as the highest tier for which their `party_maker_volume_fraction` is greater or equal to the tiers `minimum_party_maker_volume_fraction`. If a party does not qualify for any tier, their `additional_maker_rebate` is set to `0`.

```pseudo
Given:
    benefit_tiers=[
        {
            "minimum_party_maker_volume_fraction": 0.1,
            "additional_maker_rebate": 0.01,
        },
        {
            "minimum_party_maker_volume_fraction": 0.2,
            "additional_maker_rebate": 0.02,

        },
        {
            "minimum_party_maker_volume_fraction": 0.3,
            "additional_maker_rebate": 0.03,

        },
    ]

And:
    party_maker_volume_fraction=0.23

Then:
    additional_maker_rebate=0.02
```

This `additional_maker_rebate` factor is then fixed for the duration of the next epoch.

## Application

As variable fees for the taker depending upon with whom they are trading would not be a good experience, the additional maker rebate should be taken from a weighted combination of the network treasury and network buyback components of the total fee. The exact calculations are laid out in [0029-FEES](./0029-FEES-fees.md) but are broadly:

   1. `high_volume_maker_fee = high_volume_factor * trade_value_for_fee_purposes`
   1. `treasury_fee = treasury_fee * (1 - high_volume_maker_fee / (treasury_fee + buyback_fee))`
   1. `buyback_fee = treasury_fee * (1 - buyback_fee / (treasury_fee + buyback_fee))`

As the rebate is funded through the buyback and treasure fee, the effective rebate is capped to a maximum rebate factor which is the sum of the treasury and buy back factors, i.e.

$$\text{effectiveAdditionalMakerRebate} = \min{(\text{additionalMakerRebate}, \text{market.fee.factors.treasuryFee} + \text{market.fee.factors.buybackFee})}$$

As a parties $effectiveAdditionalMakerRebate$ is dependent on the network parameters defining the factors, if the fee factors are updated through governance during an epoch, calculation of the effective rebate should be re-triggered a parties current $additionalMakerRebate$ and the updated factors. Note in this case, the network should not recalculate which tier and $additionalMakerRebate$ a party qualifies for as this is only done on epoch boundaries.

Any APIs which report a parties rebate factor should adhere to this cap and return the $effectiveAdditionalMakerRebate$.

## Acceptance Criteria

### Governance Proposals

1. If an `UpdateVolumeRebateProgram` proposal does not fulfil one or more of the following conditions, the proposal should be `STATUS_REJECTED`:
    - the `end_of_program_timestamp` must be less than or equal to the proposals `enactment_time` (<a name="0095-HVMR-001" href="#0095-HVMR-001">0095-HVMR-001</a>).
    - the number of tiers in `benefit_tiers` must be less than or equal to the network parameter `volumeRebateProgram.maxBenefitTiers` (<a name="0095-HVMR-002" href="#0095-HVMR-002">0095-HVMR-002</a>).
    - all `minimum_party_maker_volume_fraction` values must be a float strictly greater than 0 (<a name="0095-HVMR-003" href="#0095-HVMR-003">0095-HVMR-003</a>).
    - the `window_length` must be an integer strictly greater than zero (<a name="0095-HVMR-004" href="#0095-HVMR-004">0095-HVMR-004</a>).
1. A volume rebate program should be started the first epoch change after the `enactment_datetime` is reached (<a name="0095-HVMR-005" href="#0095-HVMR-005">0095-HVMR-005</a>).
1. A volume rebate program should be closed the first epoch change after the `end_of_program_timestamp` is reached (<a name="0095-HVMR-006" href="#0095-HVMR-006">0095-HVMR-006</a>).
1. If a volume rebate program is already active and a proposal `enactment_datetime` is reached, the volume rebate program is updated at the next epoch change.
    - Propose program A with `enactment_timestamp` ET1 and `end_of_program_timestamp` CT1 (<a name="0095-HVMR-007" href="#0095-HVMR-007">0095-HVMR-007</a>).
    - Proposal for program A accepted and begins first epoch after ET1 (<a name="0095-HVMR-008" href="#0095-HVMR-008">0095-HVMR-008</a>).
    - Propose program B with `enactment_timestamp` ET2 (ET2 > ET1 && ET2 < CT1) and `end_of_program_timestamp` CT1 (CT1 < CT2) (<a name="0095-HVMR-009" href="#0095-HVMR-009">0095-HVMR-009</a>).
    - Proposal for program B accepted and overrides program A the first epoch after ET2 (<a name="0095-HVMR-010" href="#0095-HVMR-010">0095-HVMR-010</a>).
    - Program is closed first epoch after CT2, there should be no active proposals (<a name="0095-HVMR-011" href="#0095-HVMR-011">0095-HVMR-011</a>).
1. Updating any of the following network parameters whilst there is an active volume rebate program will not modify or cancel the active program in any way. The updated parameters will however be used to validate future volume rebate program proposals.
    - `volumeRebateProgram.maxBenefitTiers` (<a name="0095-HVMR-012" href="#0095-HVMR-012">0095-HVMR-012</a>).

### Maker volume fraction

#### Contributing trades

1. Each trade in which a party is the "maker" **should** contribute towards the parties maker volume fraction (<a name="0095-HVMR-013" href="#0095-HVMR-013">0095-HVMR-013</a>). For product spot (<a name="0095-HVMR-014" href="#0095-HVMR-014">0095-HVMR-014</a>).
1. Each trade in which a party is the "taker" **should not** contribute towards the parties maker volume fraction (<a name="0095-HVMR-015" href="#0095-HVMR-015">0095-HVMR-015</a>). For product spot (<a name="0095-HVMR-016" href="#0095-HVMR-016">0095-HVMR-016</a>).
1. A trade generated during auction uncrossing should not contribute to either parties maker volume fraction (<a name="0095-HVMR-017" href="#0095-HVMR-017">0095-HVMR-017</a>). For product spot (<a name="0095-HVMR-018" href="#0095-HVMR-018">0095-HVMR-018</a>).

#### Evaluating contributions across windows

1. Given a rebate program with a window length greater than zero. If a party generated an equal amount of volume in the current epoch to a party who created volume in a previous epoch in the window, then they should both have a maker volume fraction of `0.5`. (<a name="0095-HVMR-019" href="#0095-HVMR-019">0095-HVMR-019</a>). For product spot (<a name="0095-HVMR-020" href="#0095-HVMR-020">0095-HVMR-020</a>).
1. Given a rebate program with a window length greater than zero. If a party generated an equal amount of volume in the current epoch to a party who created volume in a previous epoch which is no longer in the window, they the party should have a maker volume fraction of `1` (and the other party will have a fraction of `0`). (<a name="0095-HVMR-021" href="#0095-HVMR-021">0095-HVMR-021</a>). For product spot (<a name="0095-HVMR-022" href="#0095-HVMR-022">0095-HVMR-022</a>).

#### Evaluating contributions across markets

1. Given two parties making markets in two separate derivative markets using settlement assets with different quantum values, if the parties generated equal volume (e.g. 10,000 USD) then they should both have a maker volume fraction of `0.5`. (<a name="0095-HVMR-023" href="#0095-HVMR-023">0095-HVMR-023</a>).
1. Given two parties making markets in two separate spot markets using quote assets with different quantum values, if the parties generated equal volume (e.g. 10,000 USD) then they should both have a maker volume fraction of `0.5`. (<a name="0095-HVMR-024" href="#0095-HVMR-024">0095-HVMR-024</a>).
1. Given two parties making markets in a separate derivative and spot market using a settlement and quote asset with different quantum values respectively, if the parties generated equal volume (e.g. 10,000 USD) then they should both have a maker volume fraction of `0.5`. (<a name="0095-HVMR-025" href="#0095-HVMR-025">0095-HVMR-025</a>).

### Setting rebate factors

1. At the start of an epoch, each parties `additional_rebate_factor` is reevaluated and fixed for the epoch (<a name="0095-HVMR-026" href="#0095-HVMR-026">0095-HVMR-026</a>).
1. A parties `additional_rebate_factor`  is set equal to the factors in the highest benefit tier they qualify for (<a name="0095-HVMR-027" href="#0095-HVMR-027">0095-HVMR-027</a>).
1. If a party does not qualify for the lowest tier, their `additional_rebate_factor`is set to `0` (<a name="0095-HVMR-028" href="#0095-HVMR-028">0095-HVMR-028</a>).

#### Capping the effective rebate factor

1. If a party qualifies for a tier where the `additional_rebate_factor` is greater than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be capped to a maximum and set to (`buyback_fee_factor` + `treasury_fee_factor`). In this case no treasury or buyback fees should be collected by the network for trades involving this party. (<a name="0095-HVMR-029" href="#0095-HVMR-029">0095-HVMR-029</a>).

1. If the `buyback_fee_factor` is increased through a proposal in the middle of an epoch such that a parties `additional_rebate_factor` is greater than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be set to the new maximum (`buyback_fee_factor` + `treasury_fee_factor`). (<a name="0095-HVMR-030" href="#0095-HVMR-030">0095-HVMR-030</a>).
1. If the `treasury_fee_factor` is increased through a proposal in the middle of an epoch such that a parties `additional_rebate_factor` is greater than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be set to the new maximum (`buyback_fee_factor` + `treasury_fee_factor`). (<a name="0095-HVMR-031" href="#0095-HVMR-031">0095-HVMR-031</a>).
1. If the `buyback_fee_factor` and `treasury_fee_factor` are both increased through a batch proposal in the middle of an epoch such that a parties `additional_rebate_factor` is greater than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be set to the new maximum (`buyback_fee_factor` + `treasury_fee_factor`). (<a name="0095-HVMR-032" href="#0095-HVMR-032">0095-HVMR-032</a>).

1. If the `buyback_fee_factor` is reduced through a proposal in the middle of an epoch such that a parties `additional_rebate_factor` is less than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be set to their current `additional_rebate_factor`. (<a name="0095-HVMR-033" href="#0095-HVMR-033">0095-HVMR-033</a>).
1. If the `treasury_fee_factor` is reduced through a proposal in the middle of an epoch such that a parties `additional_rebate_factor` is greater than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be set to their current `additional_rebate_factor`. (<a name="0095-HVMR-034" href="#0095-HVMR-034">0095-HVMR-034</a>).
1. If the `buyback_fee_factor` and `treasury_fee_factor` are both reduced through a batch proposal in the middle of an epoch such that a parties current `additional_rebate_factor` is greater than (`buyback_fee_factor` + `treasury_fee_factor`), their `effective_additional_rebate_factor` should be set to their current `additional_rebate_factor`. (<a name="0095-HVMR-035" href="#0095-HVMR-035">0095-HVMR-035</a>).
