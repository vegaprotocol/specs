# Vega Key Rotation 

This is a safety related feature specifically for validators. 

The aim is that a validator with key A can submit a transaction saying that their validator stake and delegated stake should be moved to key B. The transaction to do this has to be signed with both keys. 

Question: if this is done live, what happens on the Ethereum side? Answer: nothing, core to keep a mapping forever but Ethereum staking bridge doesn't need to know.  

Question: what happens at startup? Vega core replays all Ethereum events from the creation of the staking bridge contract. The bridge contract will still claim that the validator staked their validator tokens to key A. The mapping mentioned above will then have to be utilised to move their validator stake to key B. The delegeted amounts will come from limited network life (or other) checkpoint already pointing the delegation amounts to key B. 

MVP for Sweetwater this will only be supported at network restart with the mapping announced in the genesis block only. 