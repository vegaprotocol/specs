# Summary

This specification contains a set of tests/acceptance criteria that clients (wallets/bots) interacting with Vega are advised to test against to assure that they can authenticate properly, pass spam protection, process notifications, etc. 

1. The parameter `spam.pow.numberofTxPerBlock` is decreased.  Verify that:
    - The new parameter is communicated to and adapted by the wallet, i.e., if a user has too many transactions according to the new parameter, the wallet does not submit transactions with a too low PoW difficulty (either by submitting a PoW of higher difficulty, or by submitting the transactions later). (<a name="0011-NP-CLIE-001" href="#0011-NP-CLIE-001">0011-NP-CLIE-001</a>)           
2. The parameter `spam.pow.numberOfTxPerBlock` is increased. Verify that:
     - This is communicated to the wallet, and the wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. This means that a wallet that had has a number of transactions exceeding the previous limit, but not the current one, does not increase the PoW difficulty or delay the transactions (<a name="0011-NP-CLIE-002" href="#0011-NP-CLIE-002">0011-NP-CLIE-002</a>)  
3. The parameter `spam.pow.difficulty` is increased. Verify that:
    - This is communicated to all the wallet, and the wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. (<a name="0011-NP-CLIE-003" href="#0011-NP-CLIE-003">0011-NP-CLIE-003</a>)  
4. The parameter `spam.pow.difficulty` is decreased. Verify that
    - This is communicated to the wallet, and the wallet use these new parameters for each transaction tied to a block with a height higher than the one in which the change happened. (<a name="0011-NP-CLIE-004" href="#0011-NP-CLIE-004">0011-NP-CLIE-004</a>)  
5. The parameter `spam.pow.increaseDifficulty` is changed from `0` to `1`.  Verify that
    - This is communicated to the wallet, and wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. This requires the wallet to be subjected to a difficulty increase due to too many messages (<a name="0011-NP-CLIE-005" href="#0011-NP-CLIE-005">0011-NP-CLIE-005</a>)  
6. The parameter `spam.pow.increaseDifficulty` is changed from `1` to `0`.  Verify that
    - This is communicated to the wallet, and wallet uses the new parameter for each transaction tied to a block with a height higher than the one in which the change happened. This requires the wallet to be subjected to a difficulty increase due to too many messages (<a name="0011-NP-CLIE-006" href="#0011-NP-CLIE-006">0011-NP-CLIE-006</a>)  
