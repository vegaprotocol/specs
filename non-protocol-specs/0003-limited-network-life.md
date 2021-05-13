# Limited network life.

Vega networks will at least initially and perhaps always run for a limited time only. 
This spec covers the necessary features to ensure this works smoothly.

# Relevant network parameters
- `markets_freeze_date` sets the date before which all markets are expected to settle and after which no deposits or trading / governance transactions will be accepted. This can be +infinity or another way of indicating "never". 
- `chain_end_of_life_date` This must be `> markets_freeze_date`. At this time the chain will be shutdown.  
- `time_elapsed_between_checkpoints` sets the time elapsed between checkpoints


# Background

Networks will have a finite lifetime because:

- It is efficient to upgrade the protocol by starting again as it avoids the need to deal with multiple versions of the code (upgrades to a running chain need to respect and be able to recalculate the pre-upgrade deterministic state for earlier blocks, so all versions of criticial code must remain in the system). 
This is especially important early on when rapid iteration is desirable, as the assumption that new chains can be started for new features simplifies things considerably.

- Trading at 1000s of tx/sec generates a lot of data. Given that most instruments are non-perpetual (they expire), this gives the ability to create new markets on a new chain and naturally let the old one come to an end rather than dragging around its history forever.

- Bugs, security breaches, or other issues during alpha could either take out the chain OR make it desirable to halt block production. It's important to consider what happens next if this occurs.

# Overview
There are really two main features:
1. Create checkpoints with relevant (but minimal, basically balances) information every `time_elapsed_between_checkpoints` 
1. Ability to add load a checkpoint file as part of genesis. At load time calc hash of the checkpoint file and send this through consensus to make sure we the new networks is agreeing on the state.  


# Creating a checkpoint
Information to store:
- All asset definitions. Insurance pool balance from the markets will be summed up per asset and balance per asset stored. 
- On chain treasury balances.
- Balances for all parties per asset: sum of general, margin and LP bond accounts. 
- `chain_end_of_life_date`

Information we explicitly don't try to checkpoint:
- Positions
- Balances in the "signed for withdrawal" account. 

When a checkpoint is created, each validator should calculate its has and submit this is a transaction to the chain(*). 
The checkpoint file should either be human-readable OR there should be a command line tool to convert into human readable form. 

(*) This is so that non-validating parties can trust the hash being restored represnts truly the balances. 

# Restoring a checkpoint
The hash of the state file to be restored must me specified in genesis. 
Any validator will submit a transaction containing the checkpoint file. Nodes calculate the hash, if it doesn't match what's in genesis it's ignored otherwise the state is restored. This transaction can only be accepted once per life of the chain. 

# Taking limited network life into account 
- Market proposals would not be accepted for markets that would live past this date/time and new deposits would be prevented after end of life date.
That is we need `markets_freeze_date > market_settlement > market_trading_terminated`. 
- Participants need access to funds after network ends. This will be facilitaded both (a) the chain will run past the configured `market_trading_terminated` until `chain_end_of_life_date` so that people have time to withdraw; and (b) using restoration of balances to allow participants to withdraw or continue to trade with funds during the next iteration of the chain.
- A governance proposal to change `markets_freeze_date` and `chain_end_of_life_date` must check that `chain_end_of_life_date > markets_freeze_date > market_settlement > market_trading_terminated`. If this is not the case the proposal should be rejected(*).

(*) A cororollary to this is that if the token holders want to shorten the network life then they may have to propose changes to all markets to bring the settlement to an earlier date. 

# Acceptance criteria

[ ] Checkpoints are created every `time_elapsed_between_checkpoints` period of time passes. 
[ ] We can launch a network with any valid checkpoint file. 
[ ] Hash of the checkpoint file is agreed via consensus.
