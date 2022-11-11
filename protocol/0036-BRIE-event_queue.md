# Summary
Latency and throughput is of paramount importance to Vega validator nodes, so monitoring various 3rd party (and notably low transaction speed) blockchains and crypto-assets isn’t possible.
To counter this problem we have created an event queue management system.
This event queue allows the standardisation and propagation of transactions from 3rd party asset chains in the Vega event message format.

# Guide-level explanation
Events and transactions are gathered and processed by the Event Queue from a given 3rd party blockchain, and only the ones subscribed to by Vega nodes will be propagated through consensus and then validated by the validator nodes.
The Event Queue continually scans local or hosted external blockchain nodes to discover on-chain events that are applicable to Vega.
Found external blockchain events are then sent to Vega validator nodes.
This makes the event queue works as a buffer between the slow/complicated world of various blockchains, and the high throughput, low latency of Vega core.

# Reference-level explanation
* Vega validators each verify each event against local external blockchain nodes as the event is gossiped
* Consensus agrees and writes event into the Vega chain

# Acceptance Criteria

## Event Queue
* An ethereum event has been observed (with sufficient number of blocks passed) by 1 out of 5 of nodes. It is not yet used as fact by vega chain. (<a name="0036-BRIE-001" href="#0036-BRIE-001">0036-BRIE-001</a>)
* An ethereum event has been observed by  (with sufficient number of block passed) by 4 out of 5 nodes (assuming that the voting majority threshold is 80%). It is now used as a fact by vega chain. (<a name="0036-BRIE-002" href="#0036-BRIE-002">0036-BRIE-002</a>)
