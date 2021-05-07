# Feature name: API Node
## Start date: 2021-05-07

## Summary

An API node is a read only service that connects to a stream node (non-validator node) and gives users the ability to query the state of the network.The user can request information from the API nodes using GraphQL, gRPC and REST. The user can query the API node for one off snapshots of data or request a subscription of live data.


## Guide-level explanation

An API node is a stand alone executable that connects to the eventbus stream of a stream node (also called a non-validator node). It constructs any data objects from the incoming data required to provide information to the client such as user positions and market depth. It allows users to make one off requests for data such as information about a market or a particular order. It also allows subscriptions to be started in which the API node sends update messages to the client as events occur in the core. The API node is started at the same time as the stream node so that all events can be captured. This is required for stage 1 so that the API node sees all the event messgaes and can have a complete picture of the validator node state. The steam node has a small buffer of events (several blocks/seconds) that it keeps to allow the API node to connect after the stream node comes up so that the API dataset is consistent with the core.

## Reference-level explanation

The API node will be developed in two stages, the first stage requires us to move the existing API code into a separate executable so that it can be built, run and tested independently of the (non-)validator nodes. The second stage is taking each data type and optimising how we create, handle and store the information. As well as adding features such as restarting the node and allowing other API nodes to retrieve a snapshot of state so that they can start up at any point in the lifetime of a Vega network.

### Stage 1
A new executable will be developed in it’s own repository that connects to a newly started stream node and requests all event bus messages. It will pass those messages onto the appropriate handlers and they will build up any data structures required to represent the information. The node will allow incoming requests from clients as well as subscriptions for setting up persistent connects that updates are sent down. This node will continue to use the Badger database to store its data as it did prior to this change. The only requests that will be handled by the (non-)validator nodes will be requests for event streams.

### Stage 2
The API node may consist of one or more executables that subscribe to some or all of the event stream messages from a stream node. Each executable could handle one set of data (such as orders or market depth) and use the best technology available to store and server up that data. For example the order API node could store all the historic orders in a Postgres database so that the users can query back to the start of the Vega market. Or the market depth API node could store things only in memory as no historic data is required, just the most up to date snapshot of the market. There could be a middleware layer between the stream node and API nodes that caches the event bus data and allows the API nodes to query older events to allow the nodes to be stopped temporarily or for new API nodes to be started to handle increased loads. A simple template would be made available for users to build their own API nodes so that they could handle the information in a bespoke way suited to the rest of their trading system.


## Acceptance Criteria
### Stage 1
* The API node must be a separate executable in it's own source code repository
* No API related code must be left in the Core Node
* The API node must be started within a few seconds of a newly started stream node
* The API node must be able to handle brief network outages and disconnects
* All API functionality currently in the Core node must be available from the API node
* All information available from the API node must be retrievable via all of the 3 connections types (gRPC, GraphQL and REST)
* The validator node will only accept requests for event bus subscriptions. All other API requests will be invalid.
* The event bus stream is only available from the stream node and not the validator or API node
* All information that is emitted from the stream node is processed by the API node (no data is lost)

### Stage 2 (for further discussion)
* The API Node will be split into different services to allow data types to be handled more optimally using better suited tools and technologies.
* Full historic data will be collected and made available via the API
* The API Nodes can be started at any point after the stream node is up.
* Each API Node will keep snapshots of their data so that in the case of a crash they can restart and only require very recent data to get back to the correct running state
* A more heavy duty middleware will be used to cache the eventbus stream from the stream node to allow API nodes to start up at any point and to remove the requirement for the stream core to handle caching of data. It only needs to forward on each event bus message to the middleware as it receives it (options like kafka or rabbitMQ should be evaluated)
* Badger will be removed and replaced with specific best of class storage per datatype
