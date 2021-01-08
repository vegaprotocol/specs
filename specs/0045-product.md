# Product

A Product in Vega is the entity that determines how buyers and sellers in a market make or lose money. It contains all the parameters and logic necessary to value a position, determine when lifecycle events (such as Trading Termination and Final Settlement at expiry) occur, and to calculate interim and final settlememnt cashflows. 


## Product parameters

A product may have many parameters if they are required to value and trade it, however every product will have at least one *Settlement asset* parameter as at a minimum the valuation function will need to know the asset being used.

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


## Settlement assets

The product must be able to return a list/set of all settlement assets that it uses. This is separate from the parameters that specify them so that the parameters can be named meaninfully for the product.

This is used so that Vega knows which assets will be required for margining. That is, there will be one margin account per settlement asset per position in a market. The valuation function (see below) will provide the value of a position in terms of each settlement asset. 

For example, a product such as a physically settled future (NB: a cash settled future only has one settlement asset) with two *settlement asset* parameters: `base_asset` and `quote_asset` would return `product.settlement assets == [base_asset, quote_asset]` as the settlement assets.


## Valuation function

Every product must specify a valuation function. This is often referred to in other specs as `product.value(price)`. It returns the value in terms of the settlement asset(s) of a position of size +1. It must provide a value for all settlement assets defined in the product parameters. For built-in cash settled Futures (and other cash settled products, e.g. cash settlend options) there is a single settlement asset only but this will not be true for other products.

Note that in future it is likely that the valuation function may also take a parameter for direction (long/short) and/or size, in order to work for more complex products. For now it only has to provide a value for size +1.

The valuation function has access to the state of the market including the current Vega time, product parameters, and any values received on data sources defined as product parameters. If does not have access to other markets' data unless these are defined as data source parameters.

See the [built-in Futures spec](./0016-builtin-future.md) for an example.


## Lifecycle triggers

Some products can expire and be settled or create interim settlement cashflows that are triggered by certain events such as the passage of time and/or the receipt of data from a data source (oracle, another Vega market, etc.).

Lifecycle events are triggered by receipt of data from a data source defined as a product parameter. Data sources can include internal Vega data feeds, including the time and data from other markets, as well as external (oracle) data source, see the [data sourcing framework spec]() [TODO: data sourcing spec link] for more details.

A lifecycle trigger looks like this, in pseudocode:

```
product.<data_source>(data) {
	// calculation logic with access to product params, data sources, market state
	settle(ASSET, amount)
	settle(ASSET, amount)
	...
	market.status = XXXX
}
```

where: 

- `product.<data_source>(data) { ... }` defines a function to executed when data is received from the `<data_source>` by Vega. The `<data_source>` must be one of the product parameters that defines a data source used by the product, and `data` will contain the received data.
- `settle(ASSET, amount)` means that a long position of size +1 will receive `amount` of `ASSET` (and a short position, size = -1) will similarly lose the same amount. `ASSET` must be one of the *settlement assets* defined on the product.
- `market.status = XXXX` means that the market status is changed. Currently the only valid status changes are to `SUSPENDED`, `TRADING_TERMINATED`, and `SETTLED` (see [./0043-market-lifecycle.md] for details of the statuses and their meaning). If a market is set to `SUSPENDED` this way, it can *only* exit this state via a governance vote to return it to normal trading or close it.

Generally the function might use conditional logic to apply tests to the data/market state and then if certain conditions are matched do one or both of emitting settlement cashflows and changing market status.

See the [built-in Futures spec](./0016-builtin-future.md) for an example. 


# Acceptance criteria

1. 