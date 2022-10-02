# Data display

This is a definition of some common data types and the rules about the displaying them. These are referenced in other acceptance criteria to avoid repetition.

## Size

>aka contracts, volume, amount.

This is set per-market and represent the number of contracts that are being brought or sold.

`Market.positionDecimalPlaces` tells us where to put the decimal when displaying the number. Size can be a whole number if `Market.positionDecimalPlaces` = 0, or a [fractional order](../protocol/0052-FPOS-fractional_orders_positions.md) if > 0.
It **should** always be displayed to the full number of decimal places. however, there may be exceptions, e.g. when visualizing on a depth chart, where the precision is not required.
Size can also be prefixed with a + or negative to imply direction/side + for long (aka buy) and - for short (aka sell)  

## Direction / side

Generally with derivatives (as apposed to spot or cash markets) one talks about going Long as apposed to Buying, Short as apposed to Selling.
## Quote price

> aka. price, quote, level, limit price

This is set per-market and represent the "price" of an asset. It can have a 1-1 relationship with the settlement asset but it is also possible that products will have different payoff methods, which is one of the reasons we don't just use settlement asset, another being in the future some markets could have multiple settlement assets, another being that we don't want 18DP quotes.

`Market.decimalPlaces` tells us where to put the decimal when displaying the number. It can be a whole number if `Market.decimalPlaces` = 0, but will not have more decimal places than the [settlement asset](#asset-balances) of a market.

`Market...quoteName` is used to tell us what to display next to the quote price. For example the `quoteName` could be `USD` but the settlement asset = `DAI`. The Market framework allows for other types of quote (e.g. %, cm and ETC). When looking at a single market it may not be necessary to show the quote name each time you show the price.


## Asset balances

> aka Collateral, account balance, Profit and loss, PnL fees, transfers.

The is set per Asset and represents the amount of an asset that is held in the bridge. 

`Asset.decimals` tells the UIs where to put the decimal place. Ethereum assets often have 18 decimal places, but can have less. Forms where you deposit, withdraw or transfer assets must show all decimal places. It may be appropriate to truncate at a certain number of DP in many cases (e.g. `0.01` instead of `0.012345678912345678` event though `0.001 wBTC` may be worth as much as than `0.01 ETH`). At the moment Vega does not have a source of information that allows conversion of currencies or way of knowing that the significant value of an asset is.

## Market

Markets do not have names, technically it is the instrument within a market that has the name. Theoretically the same instrument can be traded in multiple markets. if/when this happens a user needs to be able to disambiguate between markets. Each market does have a unique ID, Note: this is a hash of the definition of the market when it was created.
Instruments have both a Name and Code, see [market framework](../protocol/0001-MKTF-market_framework.md) for how these are used. Generally the Code can save space once a user is familiar with the market. The Name is more descriptive and should be the default when discovering markets. It remains to be seen how the community will use these exactly.
Markets can have several statuses and it may be sensible when listing markets to highlight their status. e.g. if a market is usually in continuous trading mode, but is currently in an auction due to low liquidity. The market name field could be augmented to show the status (add an icon etc).

## Public keys

> aka Party

When looking at a public key it is important that the user can get the full public key but it is often appropriate just to show an abbreviated form. The first 6 and last 6 characters are preferable, with an indication that it is truncated e.g. `56d1e6739deac3c5c1ddc6fee876b3217e504a161b5b00fda96b40ed3e8f89b8` as `56d1e6...8f89b8` or just `8f89b8` if enough of a convention has been established. In cases where the key being shows comes from your connected wallet it should also show the name (aka alias) of the key. 
Vega public keys are hexadecimal, but the convention is to display them without the preceding `0x` as this is what the Vega API returns.

## Transaction hash

> aka Transaction ID, txn, tx

The transaction [hash](https://www.investopedia.com/terms/h/hash.asp) acts as an identifier for a transaction network. It is hexadecimal and should be displayed with the preceding `0x`.

## Order type

There are different [types of orders](../protocol/0014-ORDT-order_types.md). 

- Limit
- Market
- Stop-market *- not currently supported*
- Stop-limit *- not currently supported*

## Time in force

Different order types can have different time in force options, these allow control over how these are executed.

The labels fot these should be shown in full where possible (particularly in context of a order ticket), But can be abbreviated if spaces is short.

  - Good till canceled `GTC`
  - Good till time `GTT` 
  - Fill or kill `FOK` 
  - Immediate or cancel `IOC`
  - Good for normal trading only `GFN` 
  - Good for auction only `GFA` 

## Order origin

Some limit orders originate not from a "normal" limit order, but are created by the system for the users when they submitted a pegged order shape or a liquidity provision shape.