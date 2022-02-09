# Issue: Transaction resubmit

In the bridge protocol flow, Vega validators create a signature bundle for a client that the client then submitts to the bridge to execute a withdrawal. 
This raises the issue that (a) a client may lose the signature bundle and require a new one (or the old one found), and (b) that if there is no time limit for the withdrawal,
the validator set/weights may have changed by the time of submission to the point that that bundle is unavailable.
This gets especially difficult through network restarts, as all data that still may be required at a later stage needs to be ecxplicitely checkppinted.

To prevent replay attacks, each bundle has a nonce; if the signature bundle is used, that nonce is stored in the smart contract and rejected from now on.

(a) is seen as a UI/Tooling issue and is less relevant here; it is still required though that the bundle is stored somewhere

The vega solution to the changed weights is that the new validators can re-sign a new bundle. This requires them to somehow verify that the old
bundle is valid. The new bundle then contains two nonces, the original and a new one, and invalidates them both is used.

Question: If the new bundle is resigned, do we then have a bundle with three nonces, or only the first one and a new one (the latter should be sufficient).

To authenticate a bundle, the original solution was for validators to store the old verification keys, and thus be able to verify the old bundle. 
This is insufficient, as it would allow an old set of validators (that may no longer be active on Vega) to create 'old' bundles and have them resigned
by the active validators.

##Solutions

#Timeouts:
Bundles would be valid for only a limited amount of time, and then expire; in this case, the amount is restored on the Vega chain, and
these old bundles are never resigned. 
This approach would require the Vega network  to watch the ETH Chain (and other bridges), so it knows which bundles have been used and which ones have not.
This is considered too complex. 

Workaround (not discussed yet): Restauration is done only at a specific point in time (e.g., an epoch end). At this time, Vega queries the bridge for a list of all used 
nonces, and then restores balances of transactions that are timed out and do not have a used up nonce. 

#Hashchain
Someone (datanodes/validators/...) keeps a list of all bundles in a hashchain/merkle-tree like datastructure. If a cleint wants a bundle restored, this
datastructure is used to verify that the transaction did in fact happen.

Though this solution has it's own complexity and does require storage of all bundles forever (somewhere), it is currently seen as the best option we have.

Mitigations: If the data structure is designed properly, some data can be purged using the nonce-data from the smart contract.
