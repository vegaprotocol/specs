# Liquidity demand estimate

## Definitions / Glossary of terms used
- **Open interest**: the volume of all open positions in a given market (ie order book)

The liquidity demand estimate is a calculated quantity, utilised by various mechanisms in the core.

### Current definition
liquidity demand estimate = maximum (open interest) measured over a time window, `t_window`,  where the length of time window is the `max(t-t_window,0)`. Here `t` is current time with `t=0` being the end of market opening auction.  

Example:
1. If t = 1, and the open interest history is [1, 4, 3, 6], then liquidity demand estimate = 6
2. If t = 1, and the open interest history is [1, 4, 3, 6], then liquidity demand estimate = 6
3. If t = 1, and the open interest history is [1, 4, 3, 6], then liquidity demand estimate = 6
4. If t = 1, and the open interest history is [1, 4, 3, 6], then liquidity demand estimate = 6

### Note on future definitions


### APIs


### Acceptance Criteria
