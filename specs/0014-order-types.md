Feature name: order types and validity
Start date: YYYY-MM-DD
Whitepaper section: 

# Summary
Different order types are permitted depending on the price determination method of a market. For _continuous trading_, **limit orders** and **market orders** are examples of an order type. Each order type has different _validity_ conditions including the order's lifespan (time in force), "birthing" conditions i.e. events which trigger the existence of the order; and conditional pricing conditions (e.g. pegged orders).


# Guide-level explanation
Explain the specification as if it was already included and you are explaining it to another developer working on Vega. This generally means:
- Introducing new named concepts
- Explaining the features, providing some simple high level examples
- If applicable, provide migration guidance

Order types would be things like LIMIT order which we support already, and MARKET, PEGGED, STOP, STOP LIMIT, etc.

Time in Force validity types on an order: {ENE, FOK, GTT, GTC}.

# Reference-level explanation

## Limit orders
A limit order is an order to buy or sell a contract at a specified price or better. 


## Market orders
A market order is a buy or sell order to be executed immediately at the current market prices. As long as there are willing sellers and buyers, market orders are filled.

Market orders may have FOK or ENE time in force. Default should be ENE. 


## Time in Force

| Time in Force        | Abbreviation           | Description  |
| ------------- |:-------------:| -----:|
| Execute and eliminate      | ENE | The order is matched on the order book to the extent that it can be matched immediately. The order then expires (i.e. unfilled volume doesn't remain active on the order book) |
| Fill or kill      | FOK      |   The order is matched on the order book if and only if it can be fulfilled completely for the full volume size of the order. If this condition is not met, the order is cancelled (i.e. doesn't sit on the order book) |
| Good til time | GTT      |    The order is valid until the specified time, after which point the order is invalid |
| Good til cancel | GTC      |    The order remains valid until it is completely filled or cancelled by the trader who submitted it. |

## Conditional Orders

### Stop orders

### Pegged orders


# Pseudo-code / Examples

# Test cases
