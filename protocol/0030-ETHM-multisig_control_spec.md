# Summary
“Whoever proposes an action aggregates and submits signatures and thus pays gas” - Danny

In order for the Vega network to authorize function execution on Ethereum smart contracts, a mechanism needs to be created to verify that this is the will of Vega while placing the burden of execution costs on the proposer of the function execution. To do this, we have created a multisig process that enables a proposer to aggregate and submit a number of Vega validator node signatures in order to execute any Vega controlled smart contract function.       

# Guide-level explanation
Vega controls and maintains a number of Ethereum smart contracts which have functions that can only be run once authorized by Vega consensus and are always requested by an interested party. 
For instance, for depositing of settlement instrument assets, such as Ether or DAI, Vega has launched a number of "bridge" smart contracts. These contracts contain functions that are controlled and thus only authorizable from Vega consensus. These functions include withdrawing and whitelisting assets.

As an example: once a user has requested a withdrawal and Vega consensus has agreed that the withdrawal should happen, the user will be presented with a number of signed orders from validator nodes that exceeds the threshold of signatures required. The user will then submit this "signature bundle" to the withdrawal function on the bridge smart contract along with the asset type and amount. 
This spec covers the format and recovery of proof that the Vega network has authorized the function to be run as it pertains to the smart contract mechanism.

# Reference-level explanation
## Signature Bundles
In order for a smart contract to be securely controlled by the Vega network, it must reference a previously launched and configured `MultisigControl` smart contract and call `verify_signatures` before executing a Vega controlled function.    

A signature bundle is a hex string of appended 65 byte ECDSA signatures where each signer signed the same message hash usually containing the parameters of the function being called, the current epoch data consisting of a list of signers and their corresponding weights, and a nonce that is used to prevent replay attacks.

Messages to be hashed then signed must be in the following format:
`keccak256(abi.encode(this_epoch_hash, message_hash, calling_contract))`

Where `message_hash` is passed in from the caller and is typically created in this format:
`abi.encode(target_function_param1, target_function_param2, target_function_param3, ... , msg.sender(if required), nonce, function_name_string)`

`this_epoch_hash` is defined as:
`keccak256(abi.encode(epoch_data))`
where epoch data looks like:
`epoch_data = "0x" + [signer_address_1, weight_1] + [2] + [3]...`

`calling_contract` is the contract that calls multisig, this protects against replays and collisions

NOTE: target_function_params do NOT include nonce or signatures
NOTE: the embedded encodings `encode(encode(...))`, this is required to verify what function/contract the function call goes to. There's a possible attack if MultisigControl doesn't explicitly verify that the msg.sender is the intended msg.sender. 

## Update Signers
As Vega validators change staking weight and cycle in or out, the function `update_signers(bytes32 new_epoch_hash, uint32 new_threshold, bytes calldata epoch_data, bytes calldata signatures)`

This will update the current `epoch_hash` that will be compared to the recovered `epoch_hash` from the `epoch_data` array passed into `verify_signatures`. This `epoch_hash` represents both the signer set and signer weights.

This will also update the threshold.

TODO: explain incentives to update signers

# Pseudo-code / Examples
The MultisigControl smart contract contains the following functions and events.

```go
contract MultisigControl {
   
    /***************************EVENTS****************************/
    event SignersUpdated(bytes32 new_epoch_hash, uint32 new_threshold);
    
    /*************************FUNCTIONS***************************/

    update_signers(bytes32 new_epoch_hash, uint32 new_threshold, bytes calldata epoch_data, bytes calldata signatures)

    function verify_signatures(
    bytes32  message_hash,
    bytes calldata epoch_data,
    bytes calldata signatures,
    uint256 epoch)
       
   function burn_final_hash(bytes32 final_hash)
    
    /****************************VIEWS*****************************/
    function get_epoch_details() public view returns(uint32 threshold, bytes32 epoch_hash);
        
    function is_final_hash_used(byte32 final_hash) public view returns(bool);
}
```  

# Acceptance Criteria
### MultisigControl Smart Contract 

### MultisigControl Consuming Smart Contract
 