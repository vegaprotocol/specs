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
In order for a smart contract to be securely controlled by the Vega network, it must reference a previously launched and configured `Multisig_Control` smart contract and call `verify_signatures` before executing a Vega controlled function.    

A signature bundle is a hex string of appended 65 byte ECDSA signatures where each signer signed the same message hash usually containing the parameters of the function being called, the current signer set data consisting of a list of signers and their corresponding weights, and a nonce that is used to prevent replay attacks.

## Signer Set Data
Signer Set Data is the set of signer addresses and their associated weight. Once hashed, the signer set data hash must match the current signer set data hash stored on the smart contract. This hash can be updated by calling `update_signers` (see below). The entire set of addresses and weights needs to be sent with every verified transaction and will be invalid once the signer set (or weights) change.

## Verify Signatures
The core of Multisig Control is the function: 
`function verify_signatures(bytes32  message_hash, bytes calldata signer_set_data, bytes calldata signatures)`

Where `message_hash` is passed in from the caller and is typically created in this format:
`abi.encode(target_function_param1, target_function_param2, target_function_param3, ... , tx_id_nonce, function_name_string)`

Validators sign a hash in the following format:
`keccak256(abi.encode(this_signer_set_data_hash, message_hash, calling_contract))`
This is also known as the "Final Hash"

`this_signer_set_data_hash` is defined as:
`keccak256(abi.encode(signer_set_data))`
where `signer_set_data` is an ABI encoded hex string in the following format:
`signer_set_data = "0x" + [signer_address_1, weight_1] + [2] + [3]...`

`calling_contract` is the contract that calls multisig, this protects against replays and collisions

If the signer set data hash matches the current signer set, the signatures resolve to the appropriate signer address provided AND the total summed weights is greater than the current threshold, then the transaction is verified, otherwise this function will revert the EVM and stop the transaction. Once verified, the "final hash" is marked complete to prevent reusing the signature bundle.

### Signer Set Nonce
In order to protect against the weights and signers creating the same signer set data hash, every time an update occurs, the signer set must have a dummy signer with a generated fake address and zero weight. This acts as a nonce for the signer set.
The dummy signer address should be in the following format: `0x[8 byte current epoch number][4 bytes 0][8 byte timestamp]` so for instance on epoch 1 at timestamp 1673365824 it would be `0x0000000000000001000000000000000063BD8940`

All signers (and dummy signer) must be included in every call to `verify_signatures`. If a signer is not needed or chooses to not participate in that transaction set the signature to 65 empty bytes which will cause it to be skipped when doing the `ecrecover`.

## Update Signers
As Vega validators change staking weight and cycle in or out, the function `update_signers(bytes32 new_signer_set_data_hash, uint32 new_threshold, bytes calldata signer_set_data, bytes calldata signatures)`

This will update the current `signer_set_data_hash` that will be compared to the recovered `signer_set_data_hash` from the `signer_set_data` array passed into `verify_signatures`. This `signer_set_data_hash` represents both the signer set and signer weights.

This will also update the threshold if necessary.

For details on how signer updating is incentivised [See Here](https://github.com/vegaprotocol/specs/blob/Multisig_v2_spec/protocol/0030-ETHM-multisig_control_spec.md)

### Signer Set Nonce
In order to protect against the weights and signers creating the same signer set data hash, every time an update occurs, the signer set must have a dummy signer with a generated fake address and zero weight. This acts as a nonce for the signer set.
The dummy signer address should be in the following format: `0x[8 byte current epoch number][4 bytes 0][8 byte timestamp]` so for instance on epoch 1 at timestamp 1673365824 it would be `0x0000000000000001000000000000000063BD8940`

## Burn Hash
If a transaction needs to be blocked or otherwise invalidated, Vega validators can run the function:
`burn_final_hash(bytes32 bad_final_hash, uint256 tx_id,bytes calldata signer_set_data,bytes calldata signatures)` 
This will invalidate the final hash and thus stop a transaction from going through.

# Pseudo-code / Examples
The MultisigControl smart contract contains the following functions and events.

```go
contract MultisigControl {
   
    /***************************EVENTS****************************/
    event SignersUpdated(bytes32 new_signer_set_data_hash, uint16 new_threshold);
    
    /*************************FUNCTIONS***************************/
    function update_signers(
        bytes32 new_signer_set_data_hash, 
        uint16 new_threshold, 
        uint256 tx_id,
        bytes calldata signer_set_data, 
        bytes calldata signatures)

    function verify_signatures(
        bytes32  message_hash,
        bytes calldata signer_set_data,
        bytes calldata signatures)
       
   function burn_final_hash(
        bytes32 final_hash, 
        uint256 tx_id,
        bytes calldata signer_set_data,
        bytes calldata signatures)
    
    /****************************VIEWS*****************************/
    function get_signer_set_data_details() public view returns(uint16 threshold, bytes32 signer_set_data_hash);
        
    function is_final_hash_used(bytes32 final_hash) public view returns(bool);
}
```  

# V1 to V2 Migration
This spec covers version 2 of Multisig Control.
Due to function signature changes, deploying v2 will require a full migration and update of the Multisig Control, ERC20 Bridge, and ERC20 asset pool. 

This will neccesitate a temporary migration smart contract that takes the place of the Asset Pool's ERC20 bridge and thus gains control of the "withdrawal" function that it will use to deposit (or transfer) to the v2 bridge (or asset pool)

Migration steps:
1. Deploy the v2 multisig, bridge, and pool contracts
2. Halt the v1 ERC20 bridge
3. Burn any outstanding withdrawals
4. Assign Migration Contract as the asset pool's ERC20 Bridge
5. Run migrate function for the entirety of each asset in the Asset Pool to either v2 bridge via deposit function or directly to the v2 asset pool, depending on how things need to be done on the Vega side

# Acceptance Criteria
### Vega-Side
* Every signer set and weight update MUST contain a random dummy signer as nonce. 
* The dummy signer MUST follow the format `0x[8 byte current epoch number][4 bytes 0][8 byte timestamp]`. 
* Every validator MUST verify that the epoch number and timestamp are correct.

### MultisigControl Smart Contract 

### MultisigControl Consuming Smart Contract
 