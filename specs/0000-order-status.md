Feature name: order-status
Start date: 2020-01-08

# Acceptance Criteria
- Status table below is replicated and each is tested by at least one scenario

# Summary
Orders have a status field. This specification details a set of situations and the expected status for an order.

# Reference-level explanation

## Fill or Or Kill
| Pricing Method | Time In Force | Filled | Resulting status |
|----------------|---------------|--------|------------------|
| Market         |      FOK      |   No   |      Stopped     |
| Market         |      FOK      |   Yes  |      Filled      |
| Limit          |      FOK      |   No   |      Stopped     |
| Limit          |      FOK      |   Yes  |      Filled      |


## Immediate Or Cancel
| Pricing Method | Time In Force | Filled  | Resulting status |
|----------------|---------------|---------|------------------|
| Market         |      IOC      |    No   |      Stopped     |
| Market         |      IOC      | Partial |      Partially Filled      |
| Market         |      IOC      |   Yes   |  Filled |
| Limit          |      IOC      |    No   |      Stopped     |
| Limit          |      IOC      | Partial |  Filled |
| Limit          |      IOC      |   Yes   |      Partially Filled      |


## Good ’Til Time
Note: The last row in the table below is added for clarity rather than being a legitimate situation. If the order filled, it is marked as FILLED and it is removed from the book, so it can’t expire after filling. 

| Time In Force | Filled  | Expired | Cancelled by user | Stopped by system | Resulting status |
|---------------|---------|---------|-------------------|-------------------|------------------|
|      GTT      |    No   |    No   |         No        |         No        |      Active      |
|      GTT      |    No   |   Yes   |         No        |         No        |      Stopped     |
|      GTT      |    No   |    No   |        Yes        |         No        |     Cancelled    |
|      GTT      |    No   |    No   |         No        |        Yes        |      Stopped     |
|      GTT      | Partial |    No   |         No        |         No        |      Active      |
|      GTT      | Partial |   Yes   |         No        |         No        | Partially Filled |
|      GTT      | Partial |    No   |        Yes        |         No        |     Cancelled    |
|      GTT      | Partial |    No   |         No        |        Yes        |      Stopped     |
|      GTT      |   Yes   |    No   |         No        |         No        |      Filled      |
|      GTT      |   Yes   |   Yes   |         No        |         No        |      Filled      |