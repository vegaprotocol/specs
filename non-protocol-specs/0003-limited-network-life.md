# Limited network life.

Vega networks will at least initially and perhaps always run for a limited time only. 
This spec covers the necessary features to ensure this works smoothly.

# Relevant network parameters
- `network_end_of_life_date` sets the date before which all markets are expected to settle and after which no deposits or trading / governance transactions will be accepted. 

# Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protoocl by starting again as it avoids the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of criticial code must remain in the system). This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurss.


# Considerations (WIP/DRAFT)…

- Balances signed and stored at checkpoints in such a way that they can be restored to accounts even if the chain is lost. 
That is, if the chain dies or ends at a pre-announced time, every participant can be given access in the next iteration of the chain to the total balance they had before. 
Not required to keep separate margin and bond account balances or position/trade information. 
At time of checkpoint creation the total of general + margin + bond balances will be saved. 
The balances would be correct as at the checkpoint time, including what was in margin accounts at that time (i.e. mark to market gains/losses would be corret as at that time, too). 
Insurance pool and on-chain treasury balances must be saved during checkpoint process so they can be restored. As there will be no markets, all market level insurance pools would be swept back to the network wide asset-level insurance pools. Consideration will be needed for "swapping" the chain that's looking at the bridge contracts containing the actual funds and for ensuring that all assets configured with balances are also configured for the next iteration of the chain.
Also special consideration needs to be given to balances that have been "locked for withdrawal" (so a party may have a signed blob for withdrawing from bridge contract to Ethereum or other blockchain address). 

- Allow setting a genesis param / network param for network end of life date/time. 
Market proposals would not be accepted for markets that would live past this date/time and new deposits would be prevented after end of life date.
That is we need `network_end_of_life_date > market_settlement > market_trading_terminated`. 

- Participants need access to funds after network ends. This can be handled by both (a) allowing the chain to run past the configured end time so people have time to withdraw; and (b) using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.

- (WIP / discussion point) A governance proposal to change `network_end_of_life_date` must check that `network_end_of_life_date > market_settlement > market_trading_terminated`. If this is not the case the proposal should be rejected. *Alternatively* only proposals which set `network_end_of_life_date` to increase are allowed.

- (WIP / discussion point) should the balances checkpoint becomes genesis of a new chain or should these be somehow submitted as a transaction via consensus so that the nodes start with an agreed state? 
