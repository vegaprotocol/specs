# Limits to make first mainnet deployments of Vega safer

Philosophy:
- limits on deposits: how much do we allow people to risk 
- limits on withdrawals: limits the danger that due to a bug in the system someone can drain all the asssets 

Questions: 
- should we create limits in `core` that can be circumvented with multiple accounts? Yes! It sends a message. 
- how do we compare across assets? Maximum deposit is a multiple of minimum stake per asset (already in asset in framework) or constant per asset - for the life of the vega chain, changeable via governance

What do we want to limit:
- maximum deposit per asset from any given Ethereum address and to any Vega address
- withdrawals amount and timing? e.g. withdrawals only allowed 1 week after last settlement?
- withdrawals over certain amount during a time period subject to Vega token holder vote? If a transaction isn't approved(*) within a time limit it will be automatically addressed to a new Ethereum address controlled by Vega token multisig - allowing DAO-like approach to distributing this.

(*) by default approved i.e. unless we have more than 50% votes against the withdrawal proceeds 

- do we need a lever to stop all withdrawls are automatically moved to DAO? 

- there is BIG RED BUTTON on the ethereum side which can move all locked assets to the DAO. From there they can be manually distributed subject to vote. The purpose is to deal with catastrophic failure of Vega chain or loss of validators or, or, or anything that could have gone wrong.

- work out how orderly withdrawal of funds happens at the end of life of Vega network (another spec?)

- insurance pool money after all settlement and Vega net shutdown will go into DAO.







