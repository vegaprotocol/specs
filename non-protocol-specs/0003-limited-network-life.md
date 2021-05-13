# Limited network life.

Vega networks will at least initially and perhaps always run for a limited time only. 
This spec covers the necessary features to ensure this works smoothly.

# Relevant network parameters
- `network_end_of_life_date` sets the date before which all markets are expected to settle and after which no deposits or trading / governance transactions will be accepted. 
- `num_blocks_between_checkpoints` sets the number of blocks between checkpoints


# Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protocol by starting again as it avoids the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of criticial code must remain in the system). 
This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurss.

# Overview
There are really two main features:
1. Create checkpoints with relevant (but minimal, basically balances) information every `num_blocks_between_checkpoints` 
1. Ability to add load a checkpoint file as part of genesis. At load time calc hash of the checkpoint file and send this through consensus to make sure we the new networks is agreeing on the state.  


# Creating a checkpoint
Information to store:
- All assets. 
- All markets and their configuration. Insurance pool balance for all markets.  
- On chain treasury balances.
- Balances for all parties per asset: sum of general, margin and LP bond accounts. 

Information we explicitly don't try to checkpoint:
- Positions
- Balances in the "signed for withdrawal" account. 

The checkpoint file should either be human-readable OR there should be a command line tool to convert into human readable form. 

# Restoring a checkpoint
Load genesis. Agree on hash of checkpoint file to be loaded via consensus. Restore the above information. 

# Taking limited network life into account 
- Market proposals would not be accepted for markets that would live past this date/time and new deposits would be prevented after end of life date.
That is we need `network_end_of_life_date > market_settlement > market_trading_terminated`. 
- Participants need access to funds after network ends. This will be facilitaded both (a) allowing the chain to run past the configured end time so people have time to withdraw; and (b) using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.
- (WIP / discussion point) A governance proposal to change `network_end_of_life_date` must check that `network_end_of_life_date > market_settlement > market_trading_terminated`. If this is not the case the proposal should be rejected. *Alternatively* only proposals which set `network_end_of_life_date` to increase are allowed.

# Acceptance criteria

[ ] Checkpoints are created every `num_blocks_between_checkpoints`. 
[ ] We can launch a network with any valid checkpoint file. 
[ ] Hash of the checkpoint file is agreed via consensus.