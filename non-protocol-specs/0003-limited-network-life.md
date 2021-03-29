# Limited network life.

Vega networks will at least initially and perhaps always not last forever. This spec covers the necessary features to ensure this works smoothly.


# Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protoocl by starting again as it avoid the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of criticial code must remain in the system). This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurss.


# Considerations (WIP/DRAFT)…

- Balances signed and stored at checkpoints in such a way that they can be restored to accounts even if the chain is lost. That is, if the chain dies or ends at a pre-announced time, every participant can be given access in the next iterastion of the chain to the total balance they had before. Not required to keep margin accounts, etc. or position/trade information - all amounts would be swept back to general, but the balances would be correct as at the checkpoint time, including what was in margin accounts at that time (i.e. mark to market gains/losses would be corret as at that time, too). Insurance pool and on-chain treasury balances must be restored. As there will be no markets, all market level insurance pools would be swept back to the network wide asset-level insurance pools. Consideration will be needed for "swapping" the chain that's looking at the bridge contracts containing the actual funds and for ensuring that all assets configured with balances are also configured for the next iteration of the chain.

- Allow setting a genesis param / network param for network end of life date/time. Market proposals would not be accepted for markets that would live past this date/time and new deposits would be prevented.

- Participants need access to funds after network ends. This can be handled by both (a) allowing the chain to run past the configured end time so people have time to withdraw; and (b) using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.