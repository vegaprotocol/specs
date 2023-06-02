# Select network and nodes

## Startup

- **Must** automatically select a node from the environments network config stored in the [networks repo](https://github.com/vegaprotocol/networks) ([0006-NETW-001](#0006-NETW-001))

## Network switcher

- **Must** see current network ([0006-NETW-002](#0006-NETW-002))
- **Must** be able to change network ([0006-NETW-003](#0006-NETW-003))

## Node health

- **Must** see node status
  - Operational if node is less than 3 blocks behind ([0006-NETW-004](#0006-NETW-004))
  - Warning if greater than 3 blocks behind ([0006-NETW-005](#0006-NETW-005))
  - Warning if vega time is 3 seconds behind current time ([0006-NETW-006](#0006-NETW-006))
  - Prominent error if vega time is 10 seconds behind current time ([0006-NETW-007](#0006-NETW-007))
- **Must** see current connected node ([0006-NETW-008](#0006-NETW-008))
- **Must** see current block height ([0006-NETW-009](#0006-NETW-009))
- **Must** see block height progressing ([0006-NETW-010](#0006-NETW-010))
- **Must** see link to status and incidents site ([0006-NETW-011](#0006-NETW-011))

## Node switcher

- **Must** be able to click on current node to open node switcher dialog ([0006-NETW-012](#0006-NETW-012))
- In the node dialog
  - **Must** must see all nodes provided by the [network config](https://github.com/vegaprotocol/networks) ([0006-NETW-013](#0006-NETW-013))
  - For each node
    - **Must** see the response time of the node ([0006-NETW-014](#0006-NETW-014))
    - **Must** see the current block height ([0006-NETW-015](#0006-NETW-015))
    - **Must** see if subscriptions are working for that node ([0006-NETW-016](#0006-NETW-016))
  - **Must** be able to select and connect to any node, regardless of response time, block height or subscription status ([0006-NETW-017](#0006-NETW-017))
  - **Must** be able to select 'other' to input a node address and connect to it ([0006-NETW-018](#0006-NETW-018))
  - **Must** have disabled connect button if 'other' is selected but no url has been entered ([0006-NETW-019](#0006-NETW-019))
  - **Must** have disabled connect button if selected node is the current node ([0006-NETW-020](#0006-NETW-020))
