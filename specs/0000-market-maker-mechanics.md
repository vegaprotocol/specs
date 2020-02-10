# Market maker mechanics

## Acceptance Criteria

- Transaction types:
    - [ ] Applying to become a market maker: {applicant: participantID, bondAmount: {amt: Number, asset: Asset}, market: Market}
    - [ ] Applying to cease market making: {applicant: participantID, market: Market}

- Becoming a market maker:
    - [ ] A network transaction exists that acts as an application for a participant to become a market maker for a specified market.
    - [ ] The market maker application transaction includes: identity of participant, size of staked bond (including specification of asset), 
    - [ ] The application is accepted by the network if both of following are true:
       - [ ] The participant has sufficient collateral in their general account to meet the size of staked bond, specified in their transaction.
       - [ ] The market is accepting new market makers???

- Optionally ceasing to be a market maker:
    - [ ] A network transaction exists that acts as an application for a participant to cease being a market maker for a specified market.

- Forcibly ceasing to be a market maker:
    - [ ] If a market maker has their full bond slashed, the will automatically cease to be a market maker

- Market maker bond account:
	- [ ] Each active market maker of a market has a bond account for that market.
    - [ ] When a market maker is approved, the size of their staked bond is immediately transferred from their general account  to their bond account.
    - [ ] Only the network may withdraw collateral from this account.
    - [ ] Collateral withdrawn from this account may only  be transferred to either:
      - [ ] The insurance pool of the market (in event of slashing)
      - [ ] The market maker's general account (in event of market maker ceasing market making on this market)


- Market maker obligation during continuous trading:
	- [ ] Each market maker has a _market making obligation_ specified by the network at a point in time ?????
    - [ ] The _market making obligation_ requirement is specified in terms of a proportionate share of the _Firm Liquidity Measure_ calculated as the ratio of the market maker's bond size / total bond size of the market.
    - [ ] A market maker is obligated to achieve their market making obligation by placing orders on the order book, and having sufficient margin in their general account to meet the usual margin obligations.


- Market maker obligation during auction (including market commencement auction):
	- [ ] Market makers are not required to place orders during an auction period.
	- [ ] At conclusion of auction period call period, market makers obligations are reinstated.

- Market maker bond slashing:
	- [ ] The degree to which a market maker has met their obligation in a rolling time period (specified by a network parameter, initially set to 24 hours) is calculated as an average of their (attained outcome - obligation).
    - [ ] A market maker's bond is  slashed by ???  amount for every 

- Market fees:
	- [ ] The fee amount is calculated by the network ??? NEW SPEC ??? 
    - [ ] Fees are incurred at the point of trade by price takers of a trade (in continuous trading) and by all participants of an auction. This includes market maker trades and excludes trades by the network during a close out.????
    - [ ] Fees are held by the network until the _Fee Allocation Event_ of the market.

- Market maker rewards:
	- [ ] A market maker is rewarded during the _Fee Allocation Event_.
    - [ ] The share of fees that a market maker receives at the _Fee Allocation Event_ equals: 




## Summary


## Explanation





## Scenarios / tests