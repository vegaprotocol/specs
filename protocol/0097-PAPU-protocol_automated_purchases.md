# Protocol Automated Purchases

In order to allow the protocol to better manage collected fees a framework for regular, fully automated exchanges of one token for another on the protocol's spot markets should be implemented. In order to allow the protocol to receive a fair rate for the token exchange, and taking into account that not all spot markets will have deep liquidity, this should be handled through use of a scheduled auction.

This auction should have several defining features:

- It should be triggered on a defined schedule
- An event should be emitted at a known time in advance of the auction announcing the amount to be exchanged
- The price at which the protocol is willing to exchange should be configurable as some offset to a predefined set of oracle inputs

## Protocol Automated Purchase Configuration

A Protocol Automated Purchase (PAP) program can be proposed through governance and configured through a number of parameters:

- **Token From**: The source token which will be exchanged
- **Account Type From**: The account type for the network from which the tokens will be sourced
- **Account Type To**: The account type for the network to which the purchased tokens will be sent
- **Market ID**: The market which will be used to enact the exchange
- **Price Oracle**: The oracle which will define an approximate acceptable price for the transaction
- **Oracle Offset Factor**: The final acceptable price should be the **Price Oracle** value weighted by this factor (e.g. `1.05` to allow for 5% slippage on the purchase)
- **Auction Schedule**: A time based oracle for when auctions will occur
- **Auction Length**: How long an auction 
- **Auction Volume Snapshot Schedule**: A time based oracle for when an observation will be taken of the balance of the source account. This will emit an event notifying of the balance planned to exchange, along with storing this value. When an auction occurs, the latest reading for this value will be used for the volume to trade, rather than the full balance of the account.
- **Minimum Auction Size**: Minimum number of the source token to be exchanged (specified in asset decimals). If less than this are available in the account at the last snapshot before auction, no auction will occur and the balance will roll over to the next scheduled auction.
- **Maximum Auction Size**: Maximum number of the source token to be exchanged (specified in asset decimals). If more than this are available in the account at the last snapshot before auction, this maximum value will be used instead, and the remainder will be rolled over to the next scheduled auction.

Each program should be given a unique ID which should be the same as the proposal ID.

A separate proposal will exist for cancelling an active program.

## Mechanics

The lifecycle of the auction process should be:

 1. Each time **Auction Volume Snapshot Schedule** ticks, a snapshot of the balance in the relevant account is taken and stored as an externally accessible value for the volume which would be traded at an auction. To support multiple PAP programs sourcing tokens from the same account, when a snapshot is taken, those tokens should be earmarked so any snapshots from other PAP programs will not be able to appropriate the same funds.
 2. When **Auction Schedule** ticks, an auction is triggered for **Auction Length** time period, at this point the network will place an order following the mechanics described in [Creating the network order](#creating-the-network-order). The order placed on the market should be a GFA order, which will trade as much as possible on auction exit and then be removed.
 3. Any remaining balance in the account should be carried over to the next scheduled auction.
 4. Any traded balance should be send to the account specified in **Account Type To**. Note that these sales do not change ownership, and so the destination key does not require specification (all accounts are network-owned).

Note, if a PAP cancellation proposal is enacted in between a snapshot being taken and the auction ending, the final auction should still occur before the program is cancelled.

### Creating the network order

#### Determining order side

Note as the source token can either be the quote or base asset of the specified market, whether the network is placing a buy or sell order on the market must be inferred from the specified asset, i.e.

- if the source token ID matches the markets quote asset, then the network should place a buy limit order.
- if the source token ID matches the markets base asset, then the network should place a sell limit order.

If the source token matches neither the quote or base asset of the specified market then the proposal is invalid and should be rejected.

#### Determining order price

The price of the order is simply:


$$
s = s_o \cdot f
$$

where:

- $s$ is the order price
- $s_o$ is the latest oracle price
- $f$ is the offset factor specified in the order

For maximum flexibility, the network **will not** account for the side of the order when applying the offset. Therefore, to increase the attractiveness of the networks order it is recommended when creating a proposal.

- to specify an offset factor $>1$, if the source token is the quote asset (resulting in a buy order)
- to specify an offset factor $<1$, if the source token is the base asset (resulting in a sell order)

#### Determining order size

If the network is placing a sell order (i.e. the source token is the base asset) the size of the order is simply the number of tokens to be exchanged. Any fees incurred will simply be taken from the amount of quote asset due to the network from the exchange.

If the network is placing a buy order (i.e. the source token is the quote asset) the network must calculate the number of tokens it can afford to buy given the amount of the source token it has available to swap and account for any fees incurred on auction exit as these are locked in the parties holding account whilst the trade is active (see [spot](./0080-SPOT-product_builtin_spot.md#7-trading) spec).

$$
S = \frac{b}{s\cdot\left(1+0.5\cdot\left(f_m+f_i+f_b+f_t\right)\right)}
$$

where:

- $S$ is the size of the order (the amount of the base asset to be bought)
- $s$ is the price of the order
- $b$ is the amount of the quote asset earmarked to be swapped in the previous snapshot
- $f_m$ is the current maker fee factor
- $f_i$ is the current infrastructure fee factor
- $f_b$ is the current buyback fee factor
- $f_t$ is the current treasury fee factor

> [!WARNING]
> If the fee factors are updated mid auction, the worst-case fees are updated also. The network must therefore recalculate the size of their buy order and amend their existing GFA order.

### Handling conflicting auctions

To support as many use cases as possible, the network allows multiple PAP programs per source account and per market. As such, PAP programs may simultaneously appropriate tokens from the same source account and triggered PAP auctions on a single market may overlap.

To support overlapping auctions requesting funds from the same source account:

- as part of the snapshot, tokens to be exchanged **must** be earmarked so multiple PAP programs cannot appropriate the same tokens.

To support overlapping auctions on the same market, if a PAP auction is already active when another is triggered, the network must:

- set the end time of the current auction to the latest end time specified by each triggered program - extending the current auction if necessary.
- submit the necessary GFA order - the network can therefore have more than one order per auction.

> [!WARNING]
> As the network allows PAP programs to trigger coinciding PAP auctions where the network can place both a buy and sell order, in certain configurations these orders may cross. In this case the orders should simply be stopped on auction exit resulting in no exchange of tokens.

## Acceptance Criteria
