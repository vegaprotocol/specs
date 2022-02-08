# Feature name: DataNode
## Start date: 2021-05-07

## Summary

A DataNode is a read only service that connects to a stream node (non-validator node) and gives users the ability to query the state of the network. The user can request information from the DataNodes using GraphQL, gRPC and REST. The user can query the DataNode for one off snapshots of data or request a subscription of live data.

## Glossary
### DataNode
This executable which is responsible for accepting an event stream from a validator or non validator node and client requests from which it can distribute the resulting data. It supports REST, GraphQL and gRPC. It also supports the SubmitTransaction API which it forwards to the same node which it subscribes to the event stream from.
### Validator Node
A core node that is part of the tendermint consensus system and processes all incoming messages to produce an event stream. It exposes:
* gRPC SubmitTransaction API
* gRPC event stream
* REST statistics, health and metrics
### Non Validator Node (Streaming Node)
The same as the validator node except it does not contribute to the tendermint consensus but it has the same API and event stream production.

## Guide-level explanation

A DataNode is a stand alone executable that connects to the event-bus stream of a stream node (also called a non-validator node). It constructs any data objects from the incoming data required to provide information to the client such as user positions and market depth. It allows users to make one off requests for data such as information about a market or a particular order. It also allows subscriptions to be started in which the DataNode sends update messages to the client as events occur in the core. The DataNode is started at the same time as the stream node so that all events can be captured. This is required for stage 1 so that the DataNode sees all the event messages and can have a complete picture of the validator node state. The steam node has a small buffer of events (several blocks/seconds) that it keeps to allow the DataNode to connect after the stream node comes up so that the API dataset is consistent with the core.

## Reference-level explanation

The DataNode will be developed in two stages, the first stage requires us to move the existing API code into a separate executable so that it can be built, run and tested independently of the (non-)validator nodes. The second stage is taking each data type and optimising how we create, handle and store the information. As well as adding features such as restarting the node and allowing other DataNodes to retrieve a snapshot of state so that they can start up at any point in the lifetime of a Vega network.

The DataNode will consume the events sent through the event-bus stream. Messages on this stream may arrive in non id order. It is the responsibility of the DataNode to process the messages in the correct order and to verify that all the messages have arrived and none have gone missing.

### Blockchain statistics
Clients are currently able to request blockchain information via a gRPC API. As the DataNode will not have direct access to the blockchain it will need to subscribe to the gRPC stream of a Validator/Non-Validator node and then relay that information into interested clients. While the blockchain stats are only available via gRPC, the DataNode will be able to distribute the data in all three supported formats (gRPC, REST and GraphQL)

### Stage 1
A new executable will be developed in it’s own repository that connects to a newly started stream node and requests all event bus messages. It will pass those messages onto the appropriate handlers and they will build up any data structures required to represent the information. The node will allow incoming requests from clients as well as subscriptions for setting up persistent connects that updates are sent down. This node will continue to use the Badger database to store its data as it did prior to this change. The only requests that will be handled by the (non-)validator nodes will be requests for event streams.

### Stage 2
The DataNode may consist of one or more executables that subscribe to some or all of the event stream messages from a stream node. Each executable could handle one set of data (such as orders or market depth) and use the best technology available to store and server up that data. For example the order DataNode could store all the historic orders in a Postgres database so that the users can query back to the start of the Vega market. Or the market depth DataNode could store things only in memory as no historic data is required, just the most up to date snapshot of the market. There could be a middleware layer between the stream node and DataNodes that caches the event bus data and allows the DataNodes to query older events to allow the nodes to be stopped temporarily or for new DataNodes to be started to handle increased loads. A simple template would be made available for users to build their own DataNodes so that they could handle the information in a bespoke way suited to the rest of their trading system.

### Versioning
We may develop the Validator Node code and the DataNode code independently which could result in one having a different version of the event-bus API than the other. We should add some validation at startup time to prevent mismatches occurring.

## Acceptance Criteria
### Stage 1: [💧 Sweetwater](../milestones/2.5-Sweetwater.md)
* The DataNode must be a separate executable in it's own source code repository. (<a name="0004-NP-APIN-001" href="#0004-NP-APIN-001">0004-NP-APIN-001</a>) 
* No API related code must be left in the Core Node. (<a name="0004-NP-APIN-002" href="#0004-NP-APIN-002">0004-NP-APIN-002</a>) 
* The DataNode must be started within a few seconds of a newly started stream node. (<a name="0004-NP-APIN-003" href="#0004-NP-APIN-003">0004-NP-APIN-003</a>) 
* The DataNode must be able to handle brief network outages and disconnects (<a name="0004-NP-APIN-004" href="#0004-NP-APIN-004">0004-NP-APIN-004</a>) 
* All API functionality currently in the Core node must be available from the DataNode (<a name="0004-NP-APIN-005" href="#0004-NP-APIN-005">0004-NP-APIN-005</a>) 
* All information available from the DataNode must be retrievable via all of the 3 connections types (gRPC, GraphQL and REST) (<a name="0004-NP-APIN-006" href="#0004-NP-APIN-006">0004-NP-APIN-006</a>)  
* The validator node will only accept requests for event bus subscriptions. All other API requests will be invalid. (<a name="0004-NP-APIN-007" href="#0004-NP-APIN-007">0004-NP-APIN-007</a>)  
* The event bus stream is only available from the stream node and not the validator or DataNode (<a name="0004-NP-APIN-008" href="#0004-NP-APIN-008">0004-NP-APIN-008</a>)  
* All information that is emitted from the stream node is processed by the DataNode (no data is lost) (<a name="0004-NP-APIN-009" href="#0004-NP-APIN-009">0004-NP-APIN-009</a>)  
* If a DataNode loses connection to a streaming node if will attempt to reconnect and if the cached data received from the streaming node is enough to continue working it can resume being a DataNode. (<a name="0004-NP-APIN-010" href="#0004-NP-APIN-010">0004-NP-APIN-010</a>)  
* If the DataNode loses connection to a streaming node and it is unable to reconnect in time to see all the missing data, it will shutdown. (<a name="0004-NP-APIN-011" href="#0004-NP-APIN-011">0004-NP-APIN-011</a>)  
* A DataNode will be able to detect a frozen streaming node by the lack of block time updates and will shutdown. (<a name="0004-NP-APIN-012" href="#0004-NP-APIN-012">0004-NP-APIN-012</a>)  

### Stage 2 (for further discussion)
* The DataNode will be split into different services to allow data types to be handled more optimally using better suited tools and technologies.
* Full historic data will be collected and made available via the API
* The DataNodes can be started at any point after the stream node is up.
* Each DataNode will keep snapshots of their data so that in the case of a crash they can restart and only require very recent data to get back to the correct running state
* A more heavy duty middleware will be used to cache the event-bus stream from the stream node to allow DataNodes to start up at any point and to remove the requirement for the stream core to handle caching of data. It only needs to forward on each event bus message to the middleware as it receives it (options like kafka or rabbitMQ should be evaluated)
* Badger will be removed and replaced with specific best of class storage per datatype
