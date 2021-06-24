# Technical notes

Due to the various parameters, we have a setting where an inconsistent view of the settings
can cause trouble - if one validator things a transaction is valid and another one does not, 
this disagreement could stop the entire blockchain.
While this should not happen, it can. One example would be that different implementations use
slightly different rounding rules, or even processors with different float units coming to 
different results. 
My proposal here is a bit of a hack; if t+1 (or f+1 in tendermint speak) blocks in a row get 
rejected due to invalid proposals with anything that could be explained through parameter 
inconsistencies, the chain goes into a backup mode where parameter changes are only allowed 
every n-1 th block, where n is the number of validators (thus, every delegation-related 
transaction needs ot wait in mempool until the next block-number is divisible by n-1; using n-1 
assures that the responsibility for these blocks still rotates between the validators). 
Thus, even if the inconsistency blocks delegation related commands, the primary operation of 
the chain can still go on. 

In mainnet alpha this is sufficient as the chain dies relatively quickly anyhow. In later
versions, we'd need a simple resync protocol (e.g., all validators put on the block what
they think the parameters are; the majority of the first n-t blocks wins).
