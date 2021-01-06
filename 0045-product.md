# Product

A Product in Vega is the entity that determines how buyers and sellers in a market make or lose money. It contains all the parameters and logic necessary to value a position, determine when lifecycle events (such as Trading Termination and Final Settlement at expiry) occur, and to calculate interim and final settlememnt cashflows. 


## Product parameters

A product may have many parameters if they are required to value and trade it, however every product will have at least one parameter as at a minimum the valuation function will need to know the asset being used.

Every piece of data that is not provided by the Vega core and is not part of the [Market Framework](./0001-market-framework.md) definition of the market or instrument must be a product parameter as the various functions described below do not have any other source of data.


### Types of Product parameter

Product parameters my be one of two types:

* **Explicit value:** for example a number (0.1, 500, ...), date, duration, string, list of values, etc. that is specified when the Product is created along with the Instrument and Market.

* **Data source reference:** this is a reference as defined in the [Data Sourcing Framework]() [TODO: reference once merged] for a value or stream of values which will be used by the Product logic.

* **Settlement asset:** settlement asset parameters may either be one of more single asset references [TODO: link asset framework], e.g. ("base_asset" and "quote_asset" or "settlement_asset" if there's just one), or in the case of a more advanced product could be a single parameter that holds a list of assets, which may or may not have a required length.


### Changing product parameters

Any *explicit value* or *data source reference* product parameter that is defined may be changed through on-chain governance proposals.

*Settlement asset* product parameters are immutable and not able to be modified through governance. If there is an issue with the settlement asset or its definition on a market, the market would need to be Closed via governance and a new market created, as Vega has no defined way to migrate margins from one asset to another for a live market. 


### Validating product parameters

The Product definition must also provide validation logic for each *explicit value* product parameter that's provided. For settlement asset and data source reference product parameters, the validation is performed by the asset and data sourcing frameworks respectively.

Validation of values can occur in two phases:

1. Generic "stateless" logic that can be checked before a transaction is accepted by Vega (for examples `funding_rate < 1`). These validations can be used to reject a transaction before it is considered for inclusion by the network (e.g. pre-consensus) and are preferred wherever possible as a result.

1. Logic that requires access to the Vega state which includes, for example, the current date/time, market data from another Vega market, or values from a data source reference. These validations occur once a transaction is confirmed and could cause an market proposal to fail even though it is accepted by the network and processed.



Products have

Params inc. assets for settlement, references to data sources required for valuation or to generate lifecycle events, and other parameters that drive the behaviour of the product (e.g. coupon amount if it was a bond, settlement frequency or funding rate for a perp.)

Valuation function (used by X)

Lifecycle events and settlement events

How do products emit settlement asset data


# Acceptance critera

1. 