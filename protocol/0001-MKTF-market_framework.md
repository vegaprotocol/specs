# Market framework

## Summary

The market framework is a set of concepts that define the markets available on a Vega network in terms of the product and instrument being traded on each, the trading mode and related parameters, and the risk model being used for margin calculations.

The market framework is described in Section 3 of the [whitepaper](https://vega.xyz/papers/vega-protocol-whitepaper.pdf).

## Guide-level explanation

The trading core will create order books, risk engines, etc. and accept orders and other instructions based on the data held within the market framework. Changes to the market framework entities on a running Vega instance will always be made via [governance transactions](./0028-GOVE-governance.md).

## Reference-level explanation

The market framework is essentially a set of data structures that configure and control almost all of the behaviour of a Vega network (the main exceptions being per-instance network and node configuration, and [network-wide parameters](./0054-NETP-network_parameters.md) that apply to all markets). These data structures are described in the sections below.

### Market

The market data structure collects all of the information required for Vega to operate a market. The component structures tradable instrument, instrument, and product may not exist in a Vega network at all unless defined and used by one (or more, in the case of products) markets. [Risk models](./0018-RSKM-quant_risk_models.ipynb) are a set of instances of a risk model data structure that are external to the market framework and provided by the risk model implementation. They are part of the Vega codebase and in the current version of the protocol, new risk models are not created by governance or configuration on a running Vega node. All structures in the market framework should be fully and unambiguously defined by their parameters.

Data:

- **Identifier:** this should unambiguously identify a market
- **Status:** Proposed | Pending | Cancelled | Active | Suspended | Closed | Trading Terminated | Settled (see [market lifecycle spec](./0043-MKTL-market_lifecycle.md))
- **Tradable instrument:** an instance of or reference to a tradable instrument.
- **Mark price methodology:** reference to which [mark price](./0009-MRKP-mark_price.md) calculation methodology will be used.
- **Mark price methodology parameters:**
  - Algorithm 1 / Last Traded Price: initial mark price
- **Price monitoring parameters**: a list of parameters, each specifying one price monitoring auction trigger and the associated auction duration.
- **Market activation time**: Read only, set by system when market opens. The date/time at which the opening auction uncrossed and the market first entered it's normal trading mode (empty if this had not happened)
- **Quoted Decimal places**: number of decimals places for quote unit, e.g. if quote unit is USD and decimal places is 2 then prices are quoted in integer numbers of cents. Only non-negative integer values are allowed.
- **Position Decimal Places**: number of decimal places for orders and positions, i.e. if this is 2 then the smallest increment that can be traded is 0.01, for example 0.01 BTC in a `BTSUSD` market.
  - If this is negative e.g. -3 this means that the smallest order and position is of size 1000.
  - Accepted values are `-6,...,-1,0,1,2,...,6`.
- **Tick size**: the minimum change in quote price for the market. Order prices and offsets for pegged orders must be given as an exact multiple of the tick size. For example if the tick size is 0.02 USD. then a price of 100.02 USD is acceptable and a price of 100.03 USD is not. The tick size of a market can be updated through governance. Note, the tick size should be specified in terms of the market decimals, e.g. for a scaled tick size of `0.02` (USDT) in a market using `5` decimal places, the tick size would be set to `2000`.
- **Liquidation strategy**: A field specifying the liquidation strategy for the market. Please refer to [0012-POSR-position_resolution](./0012-POSR-position_resolution.md#managing-networks-position) for supported strategies.
- **Transaction Prioritisation**: A boolean, whether to enable [transaction prioritisation](./0092-TRTO-trading_transaction_ordering.md).
- **Empty AMM Price Levels**: An integer greater than or equal to zero which defines the maximum number of price levels permitted in an AMM range which would quote zero volume. This value should default to 100.

Note: it is agreed that initially the integer representation of the full precision of both order and positions can be required to fit into an int64, so this means that the largest position/order size possible reduces by a factor of ten for every extra decimal place used. This also means that, for instance, it would not be possible to create a `BTCUSD` market that allows order/position sizes equivalent to 1 sat.

Note that Vega has hard limit maximum of `MAX_DECIMAL_PLACES_FOR_POSITIONS_AND_ORDERS` as a "compile-time" parameter. Typical value be `MAX_DECIMAL_PLACES_FOR_POSITIONS_AND_ORDERS`=6. See [0052-FPOS - Fractional Orders & Positions](./0052-FPOS-fractional_orders_positions.md) for more detail.

### Trading mode - continuous trading

Parameters:

- None currently

### Trading mode - Auctions

Parameters:

- **Call period end:** when the call period ends (date/time), may be empty if indefinite

A market can be in [Auction Mode](./0026-AUCT-auctions.md) for a number of reasons:

- At market creation, markets will start in an [opening auction](./0026-AUCT-auctions.md#opening-auctions-at-creation-of-the-market), as a price discovery mechanism
- A market can be a [Frequent Batch Auction](./0026-AUCT-auctions.md#frequent-batch-auction), rather than continuous trading
- Due to [price monitoring](./0032-PRIM-price_monitoring.md) triggering a price discovery auction.

How markets operate during auction mode is a separate specification: [0026 - Auctions](./0026-AUCT-auctions.md)

## Tradable instrument

A tradable instrument is a combination of an instrument and a risk model. An instrument can only be traded when paired with a risk model, however regardless of the risk model, two identical instruments are expected to be fungible (see below).

Data:

- **Instrument:** an instance of or reference to a fully specified instrument.
- **Risk model:** a reference to a risk model *that is valid for the instrument* (Note: risk models may therefore be expected to expose a mechanism by which to test whether or not it can calculate risk/margins for a given instrument)

## Instrument

Uniquely and unambiguously describes something that can be traded on Vega, two identical instruments should be fungible, potentially (in the future, when multiple markets per instrument are allowed) even across markets. At least initially Vega will allow a maximum of one market per instrument, but the design should allow for this to be relaxed in the future when additional trading modes are added.

Instruments are the data structure that provides most of the metadata that allows for market discovery in addition to providing a concrete instance of a product to be traded. An instrument may also be described as a 'contract' (among other things) in trading literature and press.

Data:

- **Identifier:** a string/binary ID that uniquely identifies an instrument across all instruments now and in the future. Perhaps a hash of all the defining data references and parameters. These should be generated by Vega.
- **Code:** a short(shortish...) code that does not necessarily uniquely identify an instrument, but is meaningful and relatively easy to type, e.g. `FX:BTCUSD/DEC18`, `NYSE:ACN`, ... (these will be supplied by humans either through config or as part of the market spec being voted on using the governance protocol.)
- **Name:** full and fairly descriptive name for the instrument.
- **Metadata fields:** A series of arbitrary strings that can be used in clients
- **Product:** a reference to or instance of a fully specified product, including all required product parameters for that product.
- **Community Tags:** A list of string community tags assigning the market to certain categories. Each of these is a free text field of a network parameter defined maximum length. These are managed through a separate proposal type and cannot be set at market creation or changed in a normal market update proposal.

## Product

Products define the behaviour of a position throughout the trade lifecycle. They do this by taking a predefined set of product parameters as inputs and emitting a stream of *lifecycle events* which enable Vega to margin, trade and settle the product.

Products will be of two types:

- **Built-ins:** products that are hard coded as part of Vega ([built in futures](./0016-PFUT-product_builtin_future.md) are currently the only product supported).
- **Smart Products:** products that are defined in Vega's Smart Product language (future functionality)

Product lifecycle events:

- **Cash/asset flows:** these are consumed by the settlement engine and describe a movement of a number of some asset from (`-ve` value) or to (`+ve` value) the holder of a (long position), with the size of the flow specify the quantity of the asset per unit of long volume.
- **Trading Terminated:** this event moves a market to 'Trading Terminated' state, means that further trading is not possible (see [market lifecycle spec](./0043-MKTL-market_lifecycle.md)).
- **Settlement:** this event triggers final settlement of positions and release of margin, e.g. once settlement data is received from a data source/oracle and final settlement cashflows are calculated (see [market lifecycle spec](../protocol/0043-MKTL-market_lifecycle.md)).

Products must expose certain data to Vega WHEN they are instantiated as an instrument by providing parameters:

- **Settlement assets:** one or more assets that can be involved in settlement
- **Margin assets:** one or more assets that may be required as margin (usually the same set as settlement assets, but not always)
- **Price / quote units:** the unit in which prices (e.g. on the order book are quoted), usually but not always one of the settlement assets. Usually but not always (e.g. for bonds traded on yield, units = % return or options traded on implied volatility, units = % annualised vol) an asset (currency, commodity, etc.)

Products need to re-evaluate their logic when any of their inputs change e.g. oracle publishes a value, change in time, parameter changed etc., so Vega will need to somehow notify of that update.

Data:

- **Product name/code/reference/instance:** to be obtained either via a specific string identifying a builtin, e.g. 'Future', 'Option' or in future smart product code OR a reference to a product (e.g. a hash of the compiled smart product) where an existing product is being reused. Stored as a reference to a built-in product instance or a 'compiled' bytecode/AST instance for the smart product language.
- **Product specific parameters** which can be single values or streams (e.g. events from an oracle), e.g. for a future:

  - Settlement and margin asset
  - Oracle / settlement price data reference
  - Minimum order size
  - *Note: the specific parameters for a product are defined by the product and will vary between products, so the system needs to be flexible in this regard.*

Note: product definition for futures is out of scope for this ticket.

## Price monitoring parameters**

[Price monitoring (spec)](./0032-PRIM-price_monitoring.md) parameters specify an array of price monitoring triggers and the associated auction durations. Each parameter contains the following fields:

- `horizon` - price projection horizon expressed as a year fraction over which price is to be projected by the risk model and compared to the actual market moves during that period. Must be positive.
- `probability` - probability level used in price monitoring. Must be in the (0,1) range.
- `auctionExtension` - auction duration (or extension in case market is already in auction mode) per breach of the `horizon`, `probability` trigger pair specified above. Must be greater than 0.

An arbitrary limit of 4 price parameters can be set per market. This prevents building up a confusing set of price monitoring rules on a market. 4 was chosen as a practical limit, but could be increased should the need arise.

----

## Pseudo-code / examples

### Market framework data structures

```rust

struct Market {
	id: String,
	trading_mode: TradingMode,
	tradable_instrument: TradableInstrument,
}

struct TradableInstrument {
	instrument: Instrument,
	risk_model: RiskModel,
}

struct Instrument {
	id: String,
	code: String,
	name: String,
	metadata: InstrumentMetadata,
	product: Product,
}

struct InstrumentMetadata {
  tags: Vec<String>,
}

enum Product {
  // Oracle will include both info on how trading terminates and settlement data 
  // settlement_asset is asset id
  Future { oracle: Oracle, settlement_asset: String },
  // EuropeanOption {},
  // SmartProduct {},
}

enum Oracle {
  EthereumEvent { contract_id: String, event: String } // totally guessed at these :-)
  // ... more oracle types here...
}

enum RiskModel {
  BuiltinFutures { historic_volatility: f64 } // parameters here subject to change and may not be correct now
}
```

## Example of a market in the above structure

**Note:** all the naming conventions, IDs, etc. here are made up and just examples of the kind of thing that might happen and some fields are missing 🤷‍♀️.

```rust
Market {
    id: "BTC/DEC18",
    status: "Active",
    tradable_instrument: TradableInstrument {
        instrument: Instrument {
            id: "Crypto/BTCUSD/Futures/Dec19", // maybe a concatenation of all the data or maybe a hash/digest
            code: "FX:BTCUSD/DEC19",
            name: "December 2019 BTC vs USD future",
            metadata: InstrumentMetadata {
                tags: [
                    "asset_class:fx/crypto",
                    "product:futures",
                    "underlying:BTC/USD",
                    "fx/base: BTC",
                    "fx/quote: USD"
                ]
            },
            product: Future {
                settlementPriceSource: {
                  sourceType: "signedMessage",
                  sourcePubkeys: ["YOUR_PUBKEY_HERE"],
                  field: "price",
                  dataType: "decimal",
                  filters: [
                      { "field": "feed_id", "equals": "BTCUSD/EOD" },
                      { "field": "mark_time", "equals": "31/12/20" }
                  ]
                }
                settlement_asset: "Ethereum/Ether"
            }
        },
        risk_model: BuiltinFutures {
            historic_volatility: 0.15
        }
    }
}
```

## Successor market

If a market proposal, see [governance](./0028-GOVE-governance.md), designates an existing market as a *parent market* then it must have the same *product*, *settlement asset(s)* and *margin asset(s)*.
It may propose new risk model and parameters, price monitoring parameters, tick size, position and market decimal places.
It must provide oracle definitions, both for trading terminated and for settlement data.
Each market can have exactly one market as a *successor* market.

1. if there already is a market (possibly pending i.e. in opening auction, see [lifecycle spec](./0043-MKTL-market_lifecycle.md)) naming a parent market which is referenced in the proposal then the proposal is rejected.
1. if there are two proposals naming the same parent market then whichever one gets into the pending state first (i.e. passes governance vote) becomes the successor of the named parent; the other proposal is cancelled with reason "parent market not available".


## Acceptance criteria

- Details of a market's instrument must be available for each market through the API (<a name="0001-MKTF-001" href="#0001-MKTF-001">0001-MKTF-001</a>)
- Details of a market's product must be available for each market through the API (<a name="0001-MKTF-002" href="#0001-MKTF-002">0001-MKTF-002</a>)
- Details of a market's tradable instrument must be available for each market through the API (<a name="0001-MKTF-003" href="#0001-MKTF-003">0001-MKTF-003</a>)
- Market framework can report position decimal places <a name="0001-MKTF-004" href="#0001-MKTF-004">0001-MKTF-004</a>
- It is possible to designate a market as perpetual; this is visible via APIs in market data.
  - GRPC <a name="0001-MKTF-005" href="#0001-MKTF-005">0001-MKTF-005</a>
  - REST <a name="0001-MKTF-011" href="#0001-MKTF-011">0001-MKTF-011</a>
  - GraphQL <a name="0001-MKTF-012" href="#0001-MKTF-012">0001-MKTF-012</a>
- A market may have a "parent" market; the parent market is visible via APIs in the form of the `marketID` of the parent market. <a name="0001-MKTF-006" href="#0001-MKTF-006">0001-MKTF-006</a>
- A market may have a "successor" market; the parent market is visible via APIs in the form of the `marketID` (or `proposalID`) of the successor market. <a name="0001-MKTF-007" href="#0001-MKTF-007">0001-MKTF-007</a>
- A parent and successor markets must have the same:
  - product <a name="0001-MKTF-008" href="#0001-MKTF-008">0001-MKTF-008</a>
  - settlement asset(s) <a name="0001-MKTF-009" href="#0001-MKTF-009">0001-MKTF-009</a>
  - margin asset(s). <a name="0001-MKTF-010" href="#0001-MKTF-010">0001-MKTF-010</a>
