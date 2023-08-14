# Batch market instructions

This spec adds a transaction type that allows a user of the protocol to submit multiple market instructions (e.g. `SubmitOrder`, `CancelOrder`, `AmendOrder`) in a single transaction.

## Rationale

This feature is required because:

- Some traders (notably market makers) need to regularly place and maintain the price and size of multiple orders in order to operate effectively.
- To prevent liveness attacks (spam), access to block space (correctly) incurs a cost per transaction, but this has the effect of making placing/updating multiple orders excessively expensive compared to the computational cost to the network, and compared to the complexity of other single transaction operations.
- Requiring a separate transaction per market instruction places an additional load on the validators as every transaction requires an additional signature verification and must go through consensus.
- Requiring a separate transaction per market instruction increases the complexity of clients (e.g. trading algorithms), which need to both submit the transactions (and perform increasingly difficult client side proof-of-work to do so), and manage the unpredictably ordered and asynchronous results, which may be interleaved with the processing of other transactions.

Overall, building the ability to handle batches of market instructions in a single transaction will decrease the complexity of client integrations and reduce the computational and network load on both validators and clients. It will also make Vega's functionality and APIs closer to parity with those of traditional centralised exchanges.

## Functionality

### New transaction: Batch Instruction

- There will be a new transaction type called a Batch Instruction.
- This transaction must be signed by a single valid Vega key, which should have the required resources to execute all instructions in the transaction (if it does not some instructions will fail in later steps, as they would if executed as standalone transactions).
- All instructions in the transaction will be performed as if individually signed by this key.
- Client side proof of work will be required once for the entire batch instruction, *not* once per instruction within the batch. This means that it will always be more efficient to batch multiple instructions.
- The batch contains three lists of instructions to be performed. Any of these lists may be empty but at least one of the lists must be non-empty (contain at least one instruction):
  - **Cancellations**: this is a list (repeated field) of Cancel Order instructions
  - **Amendments**: this is a list (repeated field) of Amend Order instructions
  - **Submissions**: this is a list (repeated field) of Submit Order instructions
- The total number of instructions across all three lists (i.e. sum of the lengths of the lists) must be less than or equal to the current value of the network parameter `network.spam_protection.max.batch.size`.

### Processing a batch

- A batch is considered a single transaction, with a single transaction ID and a single timestamp applying to all instructions within it. Each instruction should be given a sub-identifier and index allowing it to be placed sequentially in the transaction (e.g. by consumers of the event stream). These identifiers must be sufficient for a user to determine which instruction within a batch any result (order updates, trades, errors, etc.) relates to.
- The batches must be processed in the order **all cancellations, then all amendments, then all submissions**. This is to prevent gaming the system, and to prevent any order being modified by more than one action in the batch.
- When processing each list, the instructions within the list must be processed in the order they appear in the list (i.e. in the order prescribed by the submitter). (Notwithstanding that each list is processed in its entirety before moving onto the next list, in the order specified above).
- All instructions within each list must be validated as normal **at the time that the instruction is processed**. That is, instructions cannot be pre-validated as a batch. If a prior instruction, would create a state that would cause a later instruction to fail validation, the later instruction must fail validation (and vice verse). If validation fails, that instruction must be skipped and the subsequent instructions must still be processed. Any validation or other errors should be returned, as well as a reference to the instruction to which they relate, in the response.
- Any errors encountered in processing an instruction after it passes validation must cause it to be skipped, and the errors, as well as the instruction to which they relate, must be available in the result of the transaction.
- In addition to the usual validation and other errors that can occur in processing an instruction, the following also apply:
  - Any second or subsequent Amend Order instruction for the same order ID within a single Batch Instruction transaction is an error

### Auction behaviour

- Processing each instruction within a batch must behave the same way regarding auction triggers as if it were a standalone transaction:
  - Entry to or exit from auctions must happen immediately **before continuing processing the rest of the batch** if that is what would happen were the transactions in the batch submitted individually outside of a batch.
  - Under some circumstances many or all of the remaining instructions in the batch may fail validation / not be accepted or may behave differently when processed. This is normal and expected, and handling such failures is covered in the section "Processing a batch", above.
  - Triggers, etc. that are only evaluated after some other condition is met, such as the completion of processing for all concurrently delivered  transactions with the same timestamp, should continue to obey these rules. That is, the evaluation of such triggers should not occur part way through processing a batch, which is considered to be a single transaction, with a single timestamp.
- The batch is still treated as a single transaction and executed atomically, regardless of state changes such as entering an auction.
After entering or exiting an auction mid-batch, the full batch must be processed as described above, even if every remaining instruction fails validation, before processing any other transactions.

## Acceptance criteria

- Given a market with a party having two orders, A and B, a batch transaction to cancel A, amend B to B' and place a limit order which does not immediately execute C should result in a market with orders B' and C. (<a name="0074-BTCH-001" href="#0074-BTCH-001">0074-BTCH-001</a>). For product spot: (<a name="0074-BTCH-012" href="#0074-BTCH-012">0074-BTCH-012</a>)
- Any batch transaction containing more than one amend to the same order ID should attempt to execute the first as normal but all further amends should error without being executed. (<a name="0074-BTCH-002" href="#0074-BTCH-002">0074-BTCH-002</a>)
- An error in any instruction should be logged and returned to the caller but later instructions should still be attempted. (<a name="0074-BTCH-003" href="#0074-BTCH-003">0074-BTCH-003</a>)
- If an instruction causes the market to enter a Price Monitoring Auction the market should enter the auction immediately before continuing with later instructions. (<a name="0074-BTCH-005" href="#0074-BTCH-005">0074-BTCH-005</a>). For product spot: (<a name="0074-BTCH-015" href="#0074-BTCH-015">0074-BTCH-015</a>)
- An instruction which is valid at the start of the batch execution but becomes invalid before it is executed should fail. (<a name="0074-BTCH-006" href="#0074-BTCH-006">0074-BTCH-006</a>). For product spot: (<a name="0074-BTCH-016" href="#0074-BTCH-016">0074-BTCH-016</a>) In particular:
  - A batch consisting of two limit order placements C1 and C2 where the party has enough balance to place either of them individually but not both should place C1 but reject C2.
  - A batch transaction containing aggressive limit order C1 which moves the market into price monitoring auction and a C2 which is marked `GFN` (good for normal) should execute C1 but reject C2.
- A batch transaction with more instructions than `network.spam_protection.max_batch_size` should fail. (<a name="0074-BTCH-007" href="#0074-BTCH-007">0074-BTCH-007</a>)
- Instructions in the batch should be executed in the order Cancellations -> Amendments -> Creations.  (<a name="0074-BTCH-008" href="#0074-BTCH-008">0074-BTCH-008</a>)
- Funds released by cancellations or amendments within the batch should be immediately available for later instructions (<a name="0074-BTCH-009" href="#0074-BTCH-009">0074-BTCH-009</a>). For product spot: (<a name="0074-BTCH-019" href="#0074-BTCH-019">0074-BTCH-019</a>)
- If an instruction within a batch causes another party to become distressed, position resolution should be attempted before further instructions within the batch are executed (<a name="0074-BTCH-010" href="#0074-BTCH-010">0074-BTCH-010</a>)
- Instructions within the same category within a batch should be executed in the order they are received. For example, if two Cancellations instructions are submitted in a batch: [C1, C2], then C1 should be executed before C2. (<a name="0074-BTCH-011" href="#0074-BTCH-011">0074-BTCH-011</a>)
