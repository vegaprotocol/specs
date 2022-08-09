# Batch market instructions

This spec adds a transaction type that allows a user of the protocol to submit multiple market instructions (e.g. SubmitOrder, CancelOrder, AmendOrder) in a single transaction.


# Rationale

This feature is required because:

- Some traders (notably market makers) need to regularly place and maintain the price and size of multiple orders in order to operate effectively.

- To prevent liveness attacks (spam), access to block space (correctly) incurs a cost per transaction, but this has the effect of making placing/updateing multiple orders excessively expensive compared to the computational cost to the network, and compared to the complexity of other single transaction operations.

- Requiring a separate transaction per market instruction places an additional load on the validators as every transaction requires an additional signature verification and must go through consensus.

- Requiring a separate transaction per market instruction increases the complexity of clients (e.g. trading algorithms), which need to both submit the transactions (and perform increasingly difficult client side proof-of-work to do so), and manage the unpredictably ordered and asynchronous results, which may be interleaved with the processing of other transactions.

Overall, building the ability to handle batches of market instructions in a single transaction will decrease the complexity of client integrations and reduce the computational and network load on both validators and clients. It will also make Vega's functionality and APIs closer to parity with those of traditional centralised exchanges.


# Functionality

1. There will be a new transaction type called a Batch Instruction.

1. This transaction must be signed by a single valid Vega key, which should have the required resources to execute all instructions in the transaction (if it does not some instructions will fail in later steps, as they would if executed as standalone transactions). 

1. All instructions in the transaction will be performed as if individually signed by this key.

1. Client side proof of work will be required once for the entire batch instruction, *not* once per instruction within the batch. This means that it will always be more efficient to batch multiple instructions.

1. The batch contains three lists of instructions to be performed. Any of these lists may be empty but at least one of the lists must be non-empty (contain at least one instruction):

   1. **Cancellations**: this is a list (repeated field) of Cancel Order instructions

   1. **Amendments**: this is a list (repeated field) of Amend Order instructions

   1. **Submissions**: this is a list (repeated field) of Submit Order instructions

1. The total number of instructions across all three lists (i.e. sum of the lengths of the lists) must be less than or equal to the current value of the network parameter `network.spam_protection.max_batch_size`.

1. The batches must be processed in the order **all cancellations, then all amendments, then all submissions**. This is to prevent gaming the system, and to prevent any order being modified by more than one action in the batch.

1. When processing each list, the instructions within the list must be processed in the order they appear in the list (i.e. in the order prescribed by the submitter). (Notwithstanding that each list is processed in its entirety before moving onto the next list, in the order specified above). 

1. All instructions within each list must be validated as normal **at the time that the instruction is processed**. That is, instructions cannot be pre-validatted as a batch. If a prior instruction, would create a state that would cause a later instruction to fail validation, the later instruction must fail validation (and vice verse). If validation fails, that instruction must be skipped and the subsequent instructions must still be processed. Any validation or other errors should be returned, as well as a reference to the instruction to which they relate, in the response.

1. Any errors encountered in processing an instruction after it passes validation must cause it to be skipped, and the errors, as well as the instruction to which they relate, must be available in the result of the transaction.

1. In addition to the usual validation and other errors that can occur in processing an instruction, the following also apply:

   - Any second or subsequent Amend Order instruction for the same order ID within a single Batch Instruction transaction is an error


# Acceptance criteria

TBD WIP
