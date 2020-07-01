Feature name: Bitcoin Bridge
Start date: 2020-07-01
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests


Bitcoin Bridge


Vega Pool Wallet
To start, all valid validators will submit their BTC public key to their Vega node. These keys will be used to generate a standard BTC multisig wallet with a ⅔ +1 threshold. This created wallet will be the BTC asset pool for deposits and withdrawals of BTC to/from Vega. I’m calling this the Vega pool wallet

Deposit
For deposits, users will create a custom transaction that contains the BTC being deposited and the user’s Vega public key. This transaction will be sent to the multisig Vega pool wallet. The Event Queue will watch for any transactions to the Vega pool wallet address and will retrieve the submitted public key and amount deposited. This will be wrapped as an event and put through Vega consensus. Once mined on Vega, the user’s Vega account will be credited with the deposited BTC.

Withdraw
In order to withdraw BTC from Vega, a user will request a withdrawal from a vega node. This request will cause validators to verify that the funds are available for withdrawal and sign a withdrawal transaction. The user, through tools in the console (presumably), will take the threshold of ⅔+1 signatures and submit the withdrawal transaction to receive their funds. Since BTC is the currency that pays the transaction fees, the fees come directly out of the withdrawal transaction meaning that the user pays the transaction fee. Once mined and paid out, the Event Queue will wrap the transaction as an event and submit it to Vega consensus.

Adding a Validator
Once a new Vega validator comes online, withdrawals will need to be halted for a set amount of time (need to decide on timeframe). The new validator will submit their BTC public key to their node and a new multisig wallet will be generated. This will be the new Vega pool wallet and will be immediately available for deposits. Once enough time has passed to allow outstanding deposits and withdrawals to be submitted against the old Vega pool wallet, a transfer transaction will be created by a ⅔+1 threshold of current validators. This transaction will move all of the remaining BTC from the old Vega pool wallet to the new Vega pool wallet. Once that transaction is mined, withdrawals will be available again, now with the new validator being able to sign them.

Removing a Validator
Removing a validator is the same process as adding one. The only difference is that they (presumably) wouldn’t be part of the signatures that move the BTC (though they could).


(TODO: everything past here)
# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.

# Summary
One paragraph explanation of this specification

# Guide-level explanation
Explain the specification as if it was already included and you are explaining it to another developer working on Vega. This generally means:
- Introducing new named concepts
- Explaining the features, providing some simple high level examples
- If applicable, provide migration guidance

# Reference-level explanation
This is the main portion of the specification. Break it up as required.

# Pseudo-code / Examples
If you have some data types, or sample code to show interactions, put it here

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.
