# Protocol Automated Purchases

In order to allow the protocol to better manage collected fees a framework for regular, fully automated exchanges of one token for another on the protocol's spot markets should be implemented. In order to allow the protocol to receive a fair rate for the token exchange, and taking into account that not all spot markets will have deep liquidity, this should be handled through use of a scheduled auction.

This auction should have several defining features:

 - It should be triggerable on a defined schedule
 - An event should be emitted at a known time in advance of the auction announcing the amount to be exchanged
 - The price at which the protocol is willing to exchange should be configurable as some offset to a predefined set of oracle inputs

## Automated Purchase Configuration

An automated purchase program is configured through a number of parameters:

 - **Token From**: The source token which will be sold
 - **Account Type From**: The account type for the network from which the tokens will be sourced
 - **Account Type To**: The account type for the network to which the purchased tokens will be sent
 - **Market ID**: The market which will be used to enact the purchase/sale
 - **Price Oracle**: The oracle which will define an approximate acceptable price for the transaction
 - **Oracle Offset Factor**: The final acceptable price should be the **Price Oracle** value weighted by this factor (e.g. `1.05` to allow for 5% slippage on the purcase)
 - **Auction Schedule**: A time based oracle for when auctions will occur
 - **Auction Length**: How long an auction 
 - **Auction Volume Snapshot Schedule**: A time based oracle for when an observation will be taken of the balance of the source account. This will emit an event notifying of the balance planned to exchange, along with storing this value. When an auction occurs, the latest reading for this value will be used for the volume to trade, rather than the full balance of the account.
 - **Minimum Auction Size**: Minimum number of tokens to be sold (specified in asset decimals). If less than this are available in the account at the last snapshot before auction, no auction will occur and the balance will roll over to the next scheduled auction.
 - **Maximum Auction Size**: Maximum number of tokens to be sold (specified in asset decimals). If more than this are available in the account at the last snapshot before auction, this maximum value will be used instead, and the remainder will be rolled over to the next scheduled auction.


### Lifecycle

The lifecycle of the auction process should be:

 1. Each time **Auction Volume Snapshot Schedule** ticks, a snapshot of the balance in the relevant account is taken and stored as an externally accessible value for the volume which would be traded at an auction
 2. When **Auction Schedule** ticks, an auction is triggered for **Auction Length** time period, in which a volume will be placed on the book equivalent to that measured in the last snapshot, and at a price taken from the latest **Price Oracle** value multiplied by the **Oracle Offset Factor**. The side of the market should be inferred automatically from the token being sold. The order placed on the market should be a GFA order, which will trade as much as possible on auction exit and then be removed.
 3. Any remaining balance in the account should be carried over to the next scheduled auction.
 4. Any traded balance should be send to the account specified in **Account Type To**. Note that these sales do not change ownership, and so the destination key does not require specification (all accounts are network-owned).

