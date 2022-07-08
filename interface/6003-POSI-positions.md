# Positions
A position is often thought of as the open volume/size that you have on a market. When I place an order and it is filled I will have a position.
On Vega, orders that are not yet filled require margin, the unfilled orders you have on a market can also be thought of as your position. For this reason a "position" on Vega can be thought of as where you have open volume and/or unfilled orders. Or in other terms if you have a non-zero margin account for a given market.
Exchanges often have a notion of closed positions. These are where you did once have open volume or orders but now you do not. In some cases an exchange will count each opening and "netting off" as its own position

TODO Deal with the fact that We do not have closed positions right now.

When looking at a list of positions a user...
- see the market 
- See open volumne
- see unfilled volume
- see unrealised profit list
- See a margin balance
- Follow a prompt to close a position 
