# Data display

This is a definition of some common data types and the rules about the display them. These are referenced in other acceptenace criteria to avoid repetition.

## Size

>aka contracts, volume, amount.

This is set per-market and represent the number of contracts that are being brought or sold.

`Market.positionDecimalPlaces` tells us where to put the decimal when displaying the number. Size can be a whole number if `Market.positionDecimalPlaces` = 0, or a [fractional order](../protocol/0052-FPOS-fractional_orders_positions.md) if > 0.
It **should** always be displayed to the full number of decimal places. however, there may be exceptions, e.g. when visualizing on a depth chart, where the precision is not required.

## Quote price

> aka. price, quote, level.

This is set per-market and represent the "price" of an asset. It can have a 1-1 relationship with the settlement asset but it is also possible that products will have different payoff methods, which is one of the reasons we don't just use settlement asset (another being in the future some markets could have multiple settlement assets).

`Market.decimalPlaces` tells us where to put the decimal when displaying the number. It can be a whole number if `Market.decimalPlaces` = 0, but will not have more decimal places than the [settlement asset](#asset-balances) of a market.

`Market...quoteName` is used to tell us what to display next to the quote price. For example the `quoteName` could be `USD` but the settlement asset = `DAI`. The Market framework allows for other types of quote (e.g. %, cm and ETC). When looking at a single market it may not be necessary to show the quote name each time you show the price.

`Market....tickSize` tells us the steps between quote prices.

## Asset balances

> aka Collateral, account balance, Profit and loss, PnL fees, transfers.

The is set per Asset and represents the amount of an asset that is held in the bridge. 

`Asset.decimals` tells us where to put the decimal place. Ethereum assets often have 18 decimal places, but can have less.

## Market
Markets do not have names, technically it is the instrument within a market that has the name. Theoretically the same instrument can be traded in multiple markets. if/when this happens a user needs to be able to disambiguate between markets. Each market does have a unique ID, Note: this is a hash of the definition of the market, so if the market has a [change enacted](./1007-PMAC-propose_market_change.md) it'll get a new ID.
Instruments have both a Name and Code, see [market framework](../protocol/0001-MKTF-market_framework.md) for how these are used. Generally the Code can save space once a user is familiar with the market. The Name is more descriptive and should be the default when discovering markets. It remains to be seen how the community will use these exactly.