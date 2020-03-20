Feature name: order-status

Start date: 2020-01-08

# Acceptance Criteria
- Status table below is replicated and each is tested by at least one scenario

# Summary
Orders have a status field. This specification details a set of situations and the expected status for an order.

# Reference-level explanation
For the definition of each Time In Force option, see [the Order Types spec](./0014-order-types.md#time-in-force-validity)

## All order types
* Orders can have a status of REJECTED if there is insufficient margin to place the order
* [Order Pricing methods](./0014-order-types.md#order-pricing-methods) are not listed below as they don't change the status outcome
* `Stopped` and `Cancelled` are used to determine whether an order was closed as a result of a user action (`Cancelled`) or by the system (`Stopped`) as a result of, for example, insufficient margin (see [Position Resolution](./0012-position-resoluton.md#position-resolution-algorithm))

## Fill or Or Kill
| Time In Force | Filled | Resulting status |
|---------------|--------|------------------|
|      FOK      |   No   |      Stopped     |
|      FOK      |   Yes  |      Filled      |


## Immediate Or Cancel
| Time In Force | Filled  | Resulting status |
|---------------|---------|------------------|
|      IOC      |    No   |      Stopped     |
|      IOC      | Partial |      Partially Filled      |
|      IOC      |   Yes   |  Filled |


## Good ’Til Cancelled
| Time In Force | Filled  | Cancelled by user | Stopped by system | Resulting status |
|---------------|---------|-------------------|-------------------|------------------|
|      GTC      |    No   |         No        |         No        |      Active      |
|      GTC      |    No   |         No        |        Yes        |      Stopped     |
|      GTC      |    No   |        Yes        |         No        |     Cancelled    |
|      GTC      | Partial |         No        |         No        |      Active      |
|      GTC      | Partial |        Yes        |         No        |     Cancelled    |
|      GTC      | Partial |         No        |        Yes        |      Stopped     |
|      GTC      |   Yes   |         No        |         No        |      Filled      |

## Good ’Til Time
Note: The last row in the table below is added for clarity rather than being a legitimate situation. If the order filled, it is marked as FILLED and it is removed from the book, so it can’t expire after filling. 

| Time In Force | Filled  | Expired | Cancelled by user | Stopped by system | Resulting status |
|---------------|---------|---------|-------------------|-------------------|------------------|
|      GTT      |    No   |    No   |         No        |         No        |      Active      |
|      GTT      |    No   |   Yes   |         No        |         No        |      Expired     |
|      GTT      |    No   |    No   |        Yes        |         No        |     Cancelled    |
|      GTT      |    No   |    No   |         No        |        Yes        |      Stopped     |
|      GTT      | Partial |    No   |         No        |         No        |      Active      |
|      GTT      | Partial |   Yes   |         No        |         No        |      Expired     |
|      GTT      | Partial |    No   |        Yes        |         No        |     Cancelled    |
|      GTT      | Partial |    No   |         No        |        Yes        |      Stopped     |
|      GTT      |   Yes   |    No   |         No        |         No        |      Filled      |
|      GTT      |   Yes   |   Yes   |         No        |         No        |      Filled      |
