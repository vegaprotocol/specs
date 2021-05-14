# Network Treasury

The Network Treasury is a set of accounts (up to 1 per asset supported by the network via ther asset framework) that are funded by parties, deposits, or by direct transfers (e.g. a portion of fees, or from insurance pools at market closure). The funds in the network treasury are spent either by direct governance action (transfer) or by mechanisms controlled by governance, such as a periodic transfer into a reward pot. There is no requirement or expectation of symmetry between funds flowing into the Network Treasury. For example, the treasury account may be seeded by funds held by the team or investors, or through the issuance of tokens at various irregular points in time, and these funds may then be allocated to incentives/rewards, grants, etc. on a different schedule.

## Theory of operation

### Funding

#### Funding by transfer

A transfer may specify the network treasury as the destination of the transfer. The funds, if available would be transferred instantly and irrevocably to the network treasury account for the asset in question (which would be created if it doesn’t exist).

- Transfer from protocol mechanics: there may be a protocol feature such as the charging or fees or handling of expired insurance pool balances that specifies the Netwok Treasury in a transfer.

- Transfer by governance: XXX

- Transfer transaction: a transaction submitted to the network may request to transfer funds from an account controlled by the owner’s private key (i.e. an asset general account) to the Network Treasury.

#### Funding by deposit

A deposit via a Vega bridge may directly specify the Network Treasury as the destination for the deposited funds. The deposited funds would then appear in the Network Treasury account

### Allocation 

#### Direct allocation by governance

TODO: vote to send fixed amount, one off

#### Periodic automated allocation 

TODO: % of treasury allocated every X