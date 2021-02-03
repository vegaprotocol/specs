# Limits to make first mainnet deployments of Vega safer

### Philosophy:
- limits on deposits: reduce how much do we allow people to risk initially 
- limits on withdrawals: reduce the probability that due to a bug in the system someone can drain all the asssets 

### Questions: 
- should we create limits that can be circumvented with Sybil accounts? Yes! It sends a message. 
- how do we compare across assets? Maximum deposit is a multiple of minimum stake per asset (already in asset in framework) or constant per asset - for the life of the vega chain, changeable via governance

### Deposit limits
- maximum deposit per asset from any given Ethereum address and to any Vega address. The limits per asset should be configurable via governance. Limits should be part of whitelisting a new asset. 

### Withdrawal limits
- withdrawals over certain amount during a defined time period will be delayed (e.g. 72 hours). During that delay period the Vega validators can blacklist the bundle to prevent a suspicious withdrawal by signing a multi-sig transaction (this could be done manually by agreement between validators or via governance action on Vega blockchain).

- there is BIG RED BUTTON available to the validators that stops the bridge from processing deposits / withdrawals (and a smaller green button which can resume this by re-signing the original or a new bridge contract).  

- orderly withdrawal of funds at the end of life of Vega network is in (link to TODO limited network life spec). This will cover insurance pool money too.








