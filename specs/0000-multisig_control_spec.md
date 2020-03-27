Feature name: Multisig Smart Contract Control
Start date: 2020-03-27
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests


# Summary
“Whoever proposes an action aggregates and submits signatures and thus pays gas” - Danny

In order for the Vega network to authorize function execution on Ethereum smart contracts, a mechanism needs to be created to verify that this is the will of Vega while placing the burden of execution costs on the proposer of the function execution. To do this, we have created a multisig process that enables a proposer to aggregate and submit a number of Vega validator node signatures in order to execute any Vega controlled smart contract function.       


# Guide-level explanation
Vega controls and maintains a number of Ethereum smart contracts which have functions that can only be ran once authorized by Vega consensus and are always requested by an interested party. 
For instance, for depositing of settlement instrument assets, such as Ether or DAI, Vega has launched a number of "bridge" smart contracts. These contracts contain functions that are controlled and thus only authorizable from Vega consensus. These functions include withdrawing and whitelisting assets.

As an example: once a user has requested a withdrawal and Vega consensus has agreed that the withdrawal should happen, the user will be presented with a number of signed orders from validator nodes that exceeds the threshold of signatures required. The user will then submit this "signature bundle" to the withdrawal function on the bridge smart contract along with the asset type and amount. 
This spec covers the format and recovery of proof that the Vega network has authorized the function to be run as it pertains to the smart contract mechanism.         

# Reference-level explanation
In order for a smart contract to be securely controlled by the Vega network, it must reference a previously launched and configured `MultisigControl` smart contract and call `verify_signatures` before executing a Vega controlled function.    



# Pseudo-code / Examples
The Multisig smart contract contains the following functions and events.

```javascript
contract MultisigControl {
    event SignerAdded(address new_signer);
    event SignerRemoved(address old_signer);
    event ThresholdSet(uint new_threshold);
    
    /*********ADMIN (note: this only is needed in order to simplify initial onboarding of nodes, once ownership is surrendered these will no longer be available)*/
    event SignerAdded_Admin(address new_signer);
    event SignerRemoved_Admin(address old_signer);
    function add_signer_admin(address new_signer) public onlyOwner;
    function remove_signer_admin(address old_signer) public onlyOwner
    /*********End ADMIN*/
    

    //Sets threshold of signatures that must be met before function is executed. Emits 'ThresholdSet' event
    function set_threshold(uint8 new_threshold, uint nonce, bytes memory signatures) public;
    
    //Adds new valid signer and adjusts signer count. Emits 'SignerAdded' event
    function add_signer(address new_signer, uint nonce, bytes memory signatures) public;

    //Removes currently valid signer and adjust signer count. Emits 'SignerRemoved' event
    function remove_signer(address old_signer, uint nonce, bytes memory signatures) public;
    
    //Verifies a signature bundle and returns true only if the threshold of valid signers is met, 
    //this is a function that any function controlled by Vega MUST call to be securely controlled by the Vega network  
    function verify_signatures(bytes memory signatures, bytes32 message_hash) public returns(bool);

    //Returns the message hash that is to be signed by a Vega validator node 
    function get_message_hash(bytes memory to_hash) public pure returns(bytes32);
    
}
```  

# Acceptance Criteria
Check list of statements that need to met for the feature to be considered correctly implemented.

# Test cases
Some plain text walkthroughs of some scenarios that would prove that the implementation correctly follows this specification.