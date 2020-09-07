Feature name: market-framework
Start date: 2019-02-11 

# Summary
The market framework is a set of concepts that define the markets available on a Vega network in terms of the product and instrument being traded on each, the trading mode and related parameters, and the risk model being used for margin calculations.

The market framework is described in Section 3 of the [Whitepaper](../product/wikis/Whitepaper).

# Guide-level explanation
A the trading core will create order books, risk engines, etc. and accept orders and other instructions based on the data held within the market framework. Depending on the deployment context for the trading core, the market framework will be created and manipulated in different ways:

- In the first Nicenet release and some private/permissioned Vega networks, the framework instances will be set up using configuration files.
- In later test network releases, the public Mainnet, and other private/permissioned networks, entities in the framework will be created by governance transactions.
- In scenario testing tools, etc. the framework may be created by both configuration and governance transactions.
- Changes to the market framework entities on a running Vega instance will always be made via governance transactions.

Out of scope for this ticket: 

- the governance protocol and design of governance transactions is out of scope for this market framework design;
- risk models and risk engine;
- trading modes and trading mode parameters;
- products, smart products, and the first built-in product(s) to be built (futures, options)
- APIs through which clients can query and update market framework data  

# Reference-level explanation
This is the main portion of the specification. Break it up as required.


The market framework is essentially a set of data structures that configure and control almost all of the behaviour of a Vega network (the main exceptions being per-instance network and node configuration, and network-wide parameters that apply to all markets). These data structures are described in the sections below.


## Market

The market data structure collects all of the information required for Vega to operate a market. The component structures tradable instrument, instrument, and product may not exist in a Vega network at all unless defined and used by one (or more, in the case of products) markets. Risk models are a set of instances of a risk model data structure that are external to the market framework and provided by the risk model implementation (out of scope for this section, although for Nicenet there will initially be only one, for futures), they are part of the Vega codebase and in the current version of the protocol, new risk models are not created by governance or configuration on a running Vega node. All structures in the market framework should be fully and unambiguously defined by their parameters. That is, two instances of a structure with precisely the same parameters are equivalent and identical, and should probably be de-duplicated on this basis within the implementation.

Data:
  - **Identifier:** this should unambiguously identify a market
  - **Trading mode:** this (I see it as something akin to an enum type/struct, see example below) defines the trading mode (e.g. continuous trading, auction, req — see Whitepaper section 5.1) and any required configuration for the trading mode (note that Nicenet will support only *continuous trading* and does not necessarily require any configurable parameters for the trading mode, although it may turn out to be advantageous to include some as the implementation is fleshed out). Note also that each trading mode in future will have very different sets of applicable parameters.
  - **Tradable instrument:** an instance of or reference to a tradable instrument.
  - **Mark price methodology:** reference to which [mark price](./0009-mark-price.md) calculation methodology will be used.
  - **Mark price methodology parameters:**
    - Algorithm 1 / Last Traded Price: initial mark price

### Trading mode - continuous trading

Params:
  - **Tick size** (size of an increment in price in terms of the quote currency)
  - **Decimal places**, number of decimals places for price quotes, e.g. if quote currency is USD and decimal places is 2 then prices are quoted in integer numbers of cents.

## Tradable instrument

A tradable instrument is a combination of an instrument and a risk model. An instrument can only be traded when paired with a risk model, however regardless of the risk model, two identical instruments are expected to be fungible (see below). 

Data:

 - **Instrument:** an instance of or reference to a fully specified instrument.
 - **Risk model:** a reference to a risk model *that is valid for the instrument* (NB: risk models may therefore be expected to expose a mechanism by which to test whether or not it can calculate risk/margins for a given instrument)


## Instrument

Uniquely and unambiguously describes something that can be traded on Vega, two identical instruments should be fungible, potentially (in future, when multiple markets per instrument are allowed) even across markets. At least initially Vega will allow a maximum of one market per instrument, but the design should allow for this to be relaxed in future when additional trading modes are added.

Instruments are the data structure that provides most of the metadata that allows for market discovery in addition to providing a concrete instance of a product to be traded. An instrument may also be described as a 'contract' (among other things) in trading literature and press.

Data:

 - **Identifier:** a string/binary ID that uniquely identifies an instrument across all instruments now and in the future. Perhaps a hash of all the defining data references and parameters. These should be generated by Vega.
 - **Code:** a short(ish...) code that does not necessarily uniquely identify an instrument, but is meaningful and relatively easy to type, e.g. FX:BTCUSD/DEC18, NYSE:ACN, ... (these will be supplied by humans either through config or as part of the market spec being voted on using the governance protocol.)
 - **Name:** full and fairly descriptive name for the instrument.
 - **Metadata fields:** see #85.
 - **Product:** a reference to or instance of a fully specified product, including all required product parameters for that product.


## Product

Products define the behaviour of a position throughout the trade life cycle. They do this by taking a pre-defined set of product parameters as inputs and emitting a stream of *lifecycle events* which enable Vega to margin, trade and settle the product.

Products will be of two types:

- **Built-ins:** products that are hard coded as part of Vega (built in futures and then options will be our first products).
- **Smart Products:** products that are defined in Vega's Smart Product language (future functionality, not part of Nicenet or the first Testnet or Mainnet releases.)

Product life cycle events:

- **Cash/asset flows:** these are consumed by the settlement engine and describe a movement of a number of some asset from (-ve value) or to (+ve value) the holder of a (long position), with the size of the flow specify the quantity of the asset per unit of long volume.
- **Maturity:** this event moves an instrument from 'active' to 'inactive' state, means that further trading is not possible, and triggers final settlement of positions and release of margin.

Products must expose certain data to Vega WHEN they are instantiated as an instrument by providing parameters:
- **Settlement assets:** one or more (for Nicenet it'll be one) assets that can be involved in settlement
- **Margin assets:** one or more (for Nicenet it'll be one) assets that may be required as margin (usually the same set as settlement assets, but not always)
- **Price / quote units:** the unit in which prices (e.g. on the order book are quoted), usually but not always one of the settlement assets. Usually but not always (e.g. for bonds traded on yield, units = % return or options traded on implied volatility, units = % annualised vol) an asset (currency, commodity, etc.)
- **Status:** e.g. Active | Matured (these are the only statuses I can think of for now)

Products need to re-evaluate their logic when any of their inputs change e.g. oracle publishes a value, change in time, parameter changed etc., so Vega will need to somehow notify of that update.

Data: 
- **Product name/code/reference/instance:** to be obtained either via a specific string identifying a builtin, e.g. 'Future', 'Option' or in future smart product code OR a reference to a product (e.g. a hash of the compiled smart product) where an existing product is being reused. Stored as a reference to a built-in product instance or a 'compiled' bytecode/AST instance for the smart product language.
- **Product specific parameters** which can be single values or streams (e.g. events from an oracle), e.g. for a future:
  - Settlement, pricing, and margin asset
  - Maturity date
  - Oracle reference
  - 'Contract' size
  - *Note: the specific parameters for a product are defined by the product and will vary between products, so the system needs to be flexible in this regard.* 

Note: product definition for futures is out of scope for this ticket.


----

# Pseudo-code / examples


## Market framework data structures

**Note:** commented out lines are not needed for Nicenet.

```rust

struct Market {
	id: String,
	trading_mode: TradingMode,
	tradable_instrument: TradableInstrument,
}

enum TradingMode {
	ContinuousTrading { }, // in reality there will (eventually) be params here
	// DiscreteTrading { period: Duration, ... },
	// Auction { end_datetime: DateTime, ... },
	// RFQ { ... },
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

// Note: this is not finalised, see https://gitlab.com/vega-protocol/product/issues/85
struct InstrumentMetadata {
	tags: Vec<String>,
}

enum Product {
        // maturity should be some sort of DateTime, asset is however we refer to crypto-assets (collateral) on Vega 
	Future { maturity: String, oracle: Oracle, asset: String },
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

**Note:** all the naming conventions, IDs, etc. here are made up and just examples of the kind of thing that might happen.

```rust
Market {
    id: "BTC/DEC18",
    trading_mode: ContinuousTrading,
    tradable_instrument: TradableInstrument {
        instrument: Instrument {
            id: "Crypto/BTCUSD/Futures/Dec19", // maybe a concatenation of all the data or maybe a hash/digest
            code: "FX:BTCUSD/DEC19",
            name: "December 2019 BTC vs USD future",
            metadata: InstrumentMetadata {
                tags: [
                    "asset_class:fx/crypto",
                    "product:futures"
                ]
            },
            product: Future {
                maturity: "2019-12-31",
                oracle: EthereumEvent {
                    contract_id: "0x0B484706fdAF3A4F24b2266446B1cb6d648E3cC1",
                    event: "price_changed"
                },
                asset: "Ethereum/Ether"
            }
        },
        risk_model: BuiltinFutures {
            historic_volatility: 0.15
        }
    }
}
```
