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
- **Oracle Staleness Tolerance** The maximum time between the oracles last reported price and the current time for that price to be used.
- **Oracle Offset Factor**: The final acceptable price should be the **Price Oracle** value weighted by this factor (e.g. `1.05` to allow for 5% slippage on the purchase)
- **Auction Schedule**: A time based oracle for when auctions will occur
- **Auction Length**: How long an auction
- **Auction Volume Snapshot Schedule**: A time based oracle for when an observation will be taken of the balance of the source account. This will emit an event notifying of the balance planned to exchange, along with storing this value. When an auction occurs, the latest reading for this value will be used for the volume to trade, rather than the full balance of the account.
- **Minimum Auction Size**: Minimum number of the source token to be exchanged (specified in asset decimals). If less than this are available in the account at the last snapshot before auction, no auction will occur and the balance will roll over to the next scheduled auction.
- **Maximum Auction Size**: Maximum number of the source token to be exchanged (specified in asset decimals). If more than this are available in the account at the last snapshot before auction, this maximum value will be used instead, and the remainder will be rolled over to the next scheduled auction.
- **Expiry**: Timestamp in Unix seconds, when the automated purchase is stopped. If an auction is in action it will be removed when the auction is finished.

Each program will be given a unique ID which should be the same as the proposal ID.

### Handling conflicting auctions

To prevent overlapping PAP auction on a single market and prevent protocol orders self-trading. A market will be restricted to supporting a single PAP program. Therefore, if a market currently is supporting an active PAP program, if another proposal specifies this market it will be rejected on enactment. This should happen regardless of whether different source tokens are specified.

Note, once a program is expired or cancelled, a user will be free to propose a new program for that market.

### Creating the network order

## Mechanics

The lifecycle of the auction process should be:

 1. Each time **Auction Volume Snapshot Schedule** ticks, a snapshot of the balance in the relevant account is taken and stored as an externally accessible value for the volume which would be traded at an auction. To support multiple PAP programs sourcing tokens from the same account, when a snapshot is taken, those tokens should be earmarked so any snapshots from other PAP programs will not be able to appropriate the same funds.
 2. When **Auction Schedule** ticks, an auction is triggered for **Auction Length** time period, at this point the network will place an order following the mechanics described in [Creating the network order](#creating-the-network-order). The order placed on the market should be a GFA order, which will trade as much as possible on auction exit and then be removed.
 3. Any remaining balance in the account should be carried over to the next scheduled auction.
 4. Any traded balance should be send to the account specified in **Account Type To**. Note that these sales do not change ownership, and so the destination key does not require specification (all accounts are network-owned).

Note, if a PAP cancellation proposal is enacted in between a snapshot being taken and the auction ending, the final auction should still occur before the program is cancelled.

### Determining order side

Note as the source token can either be the quote or base asset of the specified market, whether the network is placing a buy or sell order on the market must be inferred from the specified asset, i.e.

- if the source token ID matches the markets quote asset, then the network should place a buy limit order.
- if the source token ID matches the markets base asset, then the network should place a sell limit order.

If the source token matches neither the quote or base asset of the specified market then the proposal is invalid and should be rejected.

### Determining order price

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

### Determining order size

If the network is placing a sell order (i.e. the source token is the base asset) the size of the order is simply the number of tokens to be exchanged. Any fees incurred will simply be taken from the amount of quote asset due to the network from the exchange.

If the network is placing a buy order (i.e. the source token is the quote asset) the network must calculate the number of tokens it can afford to buy given the amount of the source token it has available to swap and account for any fees incurred on auction exit as these are locked in the parties holding account whilst the trade is active (see [spot](./0080-SPOT-product_builtin_spot.md#7-trading) spec).

$$
S = \frac{b}{s\cdot\left(1+0.5\cdot\left(f_l+f_i+f_b+f_t\right)\right)}
$$

where:

- $S$ is the size of the order (the amount of the base asset to be bought)
- $s$ is the price of the order
- $b$ is the amount of the quote asset earmarked to be swapped in the previous snapshot
- $f_l$ is the current liquidity fee factor
- $f_i$ is the current infrastructure fee factor
- $f_b$ is the current buyback fee factor
- $f_t$ is the current treasury fee factor

> [!WARNING]
> If the fee factors are increased mid auction after the network has calculated its order size, the protocol may be unable to cover the incurred fees on auction uncrossing. In this case normal spot mechanics will be applied and the order will be stopped. Earmarked funds will be returned to the relevant source account and made available for the next PAP auction.


## Acceptance Criteria

### Governance

#### Source tokens and markets

- A proposal specifying a market which is a futures market should be rejected. (<a name="0097-PAPU-001" href="#0097-PAPU-001">0097-PAPU-001</a>).
- A proposal specifying a market which is a perpetual market should be rejected. (<a name="0097-PAPU-002" href="#0097-PAPU-002">0097-PAPU-002</a>).
- A proposal specifying a source token which is neither the base asset or quote asset of the specified spot market should be rejected. (<a name="0097-PAPU-003" href="#0097-PAPU-003">0097-PAPU-003</a>).
- A proposal specifying a market closed spot market should be rejected. (<a name="0097-PAPU-004" href="#0097-PAPU-004">0097-PAPU-004</a>).

To ensure a market can only ever support one **active** PAP program:

- Given a market with an active PAP program specifying the markets quote asset as the source token; if another proposal is created specifying that market, it should be rejected regardless of whether the source token specified was the markets quote or base asset. (<a name="0097-PAPU-005" href="#0097-PAPU-005">0097-PAPU-005</a>).
- Given a market with an active PAP program specifying the markets base asset as the source token; if another proposal is created specifying that market, it should be rejected regardless of whether the source token specified was the markets quote or base asset. (<a name="0097-PAPU-006" href="#0097-PAPU-006">0097-PAPU-006</a>).
- Given an active PAP program is cancelled. A user should be able to propose a PAP program specifying that same market. (<a name="0097-PAPU-007" href="#0097-PAPU-007">0097-PAPU-007</a>).

#### Account types

- A user should be able to create A PAP program specifying one of the following account types as the from account type (any other account type should be rejected).
- `ACCOUNT_TYPE_BUY_BACK_FEES` (<a name="0097-PAPU-008" href="#0097-PAPU-008">0097-PAPU-008</a>).

- A user should be able to create A PAP program specifying one of the following account types as the to account type (any other account type should be rejected).
- `ACCOUNT_TYPE_GLOBAL_INSURANCE` (<a name="0097-PAPU-010" href="#0097-PAPU-010">0097-PAPU-010</a>).
- `ACCOUNT_TYPE_GLOBAL_REWARD` (<a name="0097-PAPU-011" href="#0097-PAPU-011">0097-PAPU-011</a>).
- `ACCOUNT_TYPE_NETWORK_TREASURY` (<a name="0097-PAPU-012" href="#0097-PAPU-012">0097-PAPU-012</a>).
- `ACCOUNT_TYPE_BUY_BACK_FEES` (<a name="0097-PAPU-013" href="#0097-PAPU-013">0097-PAPU-013</a>).

- A user should be able to create more than one PAP program funded from the same buyback account providing different markets are specified. (<a name="0097-PAPU-014" href="#0097-PAPU-014">0097-PAPU-014</a>).

#### Oracles

- A proposal specifying an oracle offset factor less than or equal to zero should be rejected. (<a name="0097-PAPU-015" href="#0097-PAPU-015">0097-PAPU-015</a>).
- A user should be able to create a PAP program specifying a source token which is the quote asset of a market with an oracle offset factor greater than 1 (resulting in automated buy orders at a price above the oracle price). (<a name="0097-PAPU-016" href="#0097-PAPU-016">0097-PAPU-016</a>).
- A user should be able to create a PAP program specifying a source token which is the quote asset of a market with an oracle offset factor less than 1 (resulting in automated buy orders at a price above the oracle price). (<a name="0097-PAPU-017" href="#0097-PAPU-017">0097-PAPU-017</a>).
- A user should be able to create a PAP program specifying a source token which is the base asset of a market with an oracle offset factor greater than 1 (resulting in automated sell orders at a price above the oracle price). (<a name="0097-PAPU-018" href="#0097-PAPU-018">0097-PAPU-018</a>).
- A user should be able to create a PAP program specifying a source token which is the base asset of a market with an oracle offset factor less than 1 (resulting in automated sell buy orders at a price above the oracle price). (<a name="0097-PAPU-019" href="#0097-PAPU-019">0097-PAPU-019</a>).

#### Market updates

- If the spot market specified in the PAP program is closed, then the PAP program should be cancelled. (<a name="0097-PAPU-020" href="#0097-PAPU-020">0097-PAPU-020</a>).

### Expiry and cancellations

- Given the program currently has no funds earmarked for an auction, if a program's expiry timestamp is reached, the program will be cancelled and no further auctions will take place. (<a name="0097-PAPU-021" href="#0097-PAPU-021">0097-PAPU-021</a>).
- Given the program currently has earmarked funds for an auction but is not yet in the auction, if a program's expiry timestamp is reached, the program will be cancelled, the earmarked funds released and no further auctions will take place. (<a name="0097-PAPU-022" href="#0097-PAPU-022">0097-PAPU-022</a>).
- Given the program is currently in an automated auction, if a program's expiry timestamp is reached, the program will only be cancelled when the current auction uncrosses at which point no further auctions will take place. (<a name="0097-PAPU-023" href="#0097-PAPU-023">0097-PAPU-023</a>).

### Snapshots

- Once the volume snapshot of a program is triggered, if the balance of the from account is below the minimum auction size specified in the program, then no funds are earmarked for the next auction. (<a name="0097-PAPU-024" href="#0097-PAPU-024">0097-PAPU-024</a>).
- Once the volume snapshot of a program is triggered, if the balance of the from account is above the maximum auction size specified in the program, then the maximum auction size is earmarked for the next auction. (<a name="0097-PAPU-025" href="#0097-PAPU-025">0097-PAPU-025</a>).

- If a volume snapshot is triggered and then before the next auction, another volume snapshot is triggered, the program should release all funds previously earmarked before re-calculating how many tokens to earmark for it's next auction. (<a name="0097-PAPU-026" href="#0097-PAPU-026">0097-PAPU-026</a>).

- Given a network with two PAP programs, `A` and `B`, funded from the same account with a balance of `1000`. If the snapshot of program A is triggered and is allocated `750` tokens for it's next auction, once the snapshot of program B is triggered it will only be allocated `250` tokens for it's next auction. This happens regardless of whether the auction of program B is triggered before the auction of program A. (<a name="0097-PAPU-027" href="#0097-PAPU-027">0097-PAPU-027</a>).
- Given a network with two PAP programs, `A` and `B`, funded from the same account with a balance of `1000`. If the snapshot of program A is triggered and is allocated `1000` tokens for it's next auction, once the snapshot of program B is triggered it will be allocated `0` tokens and it's next auction will be skipped. This happens regardless of whether the auction of program B is triggered before the auction of program A. (<a name="0097-PAPU-028" href="#0097-PAPU-028">0097-PAPU-028</a>).

### Auctions

- Given the market is currently in continuous trading, once an auction trigger occurs, the market should be put into an auction with an auction end time equal to the current time plus the program auction length. (<a name="0097-PAPU-029" href="#0097-PAPU-029">0097-PAPU-029</a>).
- Given the market is currently in a monitoring auction, once an auction trigger occurs, if the current auction end time is greater than the current time plus the program auction length, the auction end time is unchanged.  (<a name="0097-PAPU-030" href="#0097-PAPU-030">0097-PAPU-030</a>).
- Given the market is currently in a monitoring auction, once an auction trigger occurs, if the current auction end time is less than the current time plus the program auction length, the auction end time is extended to the current time plus the program auction length. (<a name="0097-PAPU-031" href="#0097-PAPU-031">0097-PAPU-031</a>).
- Given the market is currently suspended, once an auction trigger occurs, the market remains suspended and the auction is skipped. (<a name="0097-PAPU-032" href="#0097-PAPU-032">0097-PAPU-032</a>).

- Given an auction trigger occurs, if the price oracle has not yet reported a valid price, then the auction is skipped. (<a name="0097-PAPU-033" href="#0097-PAPU-033">0097-PAPU-033</a>).
- Given an auction trigger occurs, if the price oracle has reported a valid price but the value is stale, then the auction is skipped. (<a name="0097-PAPU-034" href="#0097-PAPU-034">0097-PAPU-034</a>).

- Given the end of an auction is reached and the book is not crossed, the market will remain in auction un till an uncrossing price can be determined. (<a name="0097-PAPU-035" href="#0097-PAPU-035">0097-PAPU-035</a>).
- Given the end of an auction is reached and the book is crossed, if the uncrossing price would break an active price monitoring trigger, the auction is extended by the relevant length. (<a name="0097-PAPU-036" href="#0097-PAPU-036">0097-PAPU-036</a>).
- Given the end of an auction is reached and the book is crossed, if the uncrossing price would not break an active price monitoring trigger, the auction is ended. (<a name="0097-PAPU-037" href="#0097-PAPU-037">0097-PAPU-037</a>).

### Protocol Automated Orders

- Given the program specifies a source asset matching the base asset of the market, it will place a sell order at the start of the auction. (<a name="0097-PAPU-038" href="#0097-PAPU-038">0097-PAPU-038</a>).
- Given the program specifies a source asset matching the quote asset of the market, it will place a buy order at the start of the auction. (<a name="0097-PAPU-039" href="#0097-PAPU-039">0097-PAPU-039</a>).

- The price of the order will equal the product of the oracle price and the programs oracle offset factor. (<a name="0097-PAPU-040" href="#0097-PAPU-040">0097-PAPU-040</a>).

- Given the program specifies a source asset matching the base asset of the market, the size of the order will match the number of tokens earmarked for the auction during the latest snapshot. (<a name="0097-PAPU-041" href="#0097-PAPU-041">0097-PAPU-041</a>).
- Given the program specifies a source asset matching the quote asset of the market, the size of the order will use the number of tokens earmarked for the auction during the latest snapshot to calculate the correct order size given the order price and current fee factors. (<a name="0097-PAPU-042" href="#0097-PAPU-042">0097-PAPU-042</a>).
- If the fee factors change during an auction resulting in the network being unable to cover the fees on auction uncrossing. The order will be stopped and the auction will end without the network exchanging any tokens. (<a name="0097-PAPU-043" href="#0097-PAPU-043">0097-PAPU-043</a>).

- If an automated purchase order is not filled on auction uncrossing, the order is removed from the book automatically (as it is a GFA order) and all earmarked funds returned to the relevant source account. (<a name="0097-PAPU-044" href="#0097-PAPU-044">0097-PAPU-044</a>).
- If an automated purchase order is only partially filled on auction uncrossing, the order is removed from the book automatically (as it is a GFA order), any swapped tokens transferred to the correct to account, and the remaining earmarked funds returned to the relevant source account. (<a name="0097-PAPU-045" href="#0097-PAPU-045">0097-PAPU-045</a>).
- If an automated purchase order is fully filled on auction uncrossing, all swapped tokens are transferred to the correct to account. (<a name="0097-PAPU-046" href="#0097-PAPU-046">0097-PAPU-046</a>).
