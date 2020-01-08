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
| Market         |      IOC      | Partial |      Filled      |
| Market         |      IOC      |   Yes   | Partially Filled |
| Limit          |      IOC      |    No   |      Stopped     |
| Limit          |      IOC      | Partial | Partially Filled |
| Limit          |      IOC      |   Yes   |      Filled      |