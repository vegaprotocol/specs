# Functionality

A *Mark Price* is used in the [mark-to-market settlement](./0003-mark-to-market-settlement.md).  A change in the *Mark Price* prompts the mark-to-market settlement to run.


Possible algorithms:
 1. The algorithm for calculating the *Mark Price* may be set to the last trade that a single order results in.  For example, consider if the mark price was previously $900. If a buy order is placed for +100 that results in 3 trades; 50 @ $1000, 25 @ $1100 and 25 @ $1200, the mark price only changes once to a new value of $1200.   

In the future a more comprehensive algorithm will direct how the *Mark Price* is calculated.  The methodology for calculating the *Mark Price* is specified at the "market" level.
