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
```
keccak256(abi.encode(
   bytes2("\x19\x00"), 
   bytes20(address(multisig_address)),
   this_signer_set_data_hash, 
   message_hash, 
   calling_contract, 
   chain_id))
```
This is also known as the "Final Hash"
* `bytes2("\x19\x00")` for clef compatability
* `bytes20(address(multisig_address))` to protect from replay attacks with old signatures
* `this_signer_set_data_hash` is defined as: `keccak256(abi.encode(signer_set_data))`
 where `signer_set_data` is an ABI encoded hex string in the following format:
`signer_set_data = "0x" + [signer_address_1, weight_1] + [2] + [3]...`
* `message_hash` is calculated in the calling function based on the needs of that function
* `calling_contract` is the contract that calls multisig, this protects against replays and collisions
* `chain_id` is the Ethereum chain ID that is baked into the protocol, mainnet is `0x1` or just `1`, [here is a list of EVM chains and their IDs](https://chainlist.wtf/)

If the signer set data hash matches the current signer set hash stored on the contracts, the signatures resolve to the appropriate signer address provided AND the total summed weights is greater than the current threshold, then the transaction is verified, otherwise this function will revert the EVM and stop the transaction. Once verified, the "final hash" is marked complete to prevent reusing the signature bundle.

## Update Signers
As Vega validators change staking weight and cycle in or out, the signer set will need to be updated using:
`update_signers(bytes32 new_signer_set_data_hash, uint32 new_threshold, uint256 tx_id, bytes calldata signer_set_data, bytes calldata signatures)`
* `new_signer_set_data_hash`: the new signer set hash against which incoming signature verification with be compared
* `new_threshold`: the weight threshold that must be met for a valid signature bundle
* `tx_id`: a Vega assigned unique identifier for this transaction

This will update the current `signer_set_data_hash` that will be compared to the calculated `signer_set_data_hash` from the `signer_set_data` array passed into `verify_signatures`. This `signer_set_data_hash` represents the signer set, signer weights, and the signer set nonce.

This function will also update the threshold if necessary.

This transaction emits the `Signers_Updated(bytes32 new_signer_set_data_hash, uint16 new_threshold)` event.

For details on how signer updating is incentivised [See Here](https://github.com/vegaprotocol/specs/blob/Multisig_v2_spec/protocol/0030-ETHM-multisig_control_spec.md#potential-incentivization)

### Signer Set Nonce
In order to protect against the weights and signers creating the same signer set data hash, every time an update occurs, the signer set must have a dummy signer with a generated fake address and zero weight. This acts as a nonce for the signer set.
This will prevent the signer set hash from ever reverting to a previous state, and thus resurrecting invalidated signature bundles.

The dummy signer address should be in the following format: `0x[8 byte current epoch number][4 bytes 0][8 byte timestamp]` so for instance on epoch 1 at timestamp 1673365824 it would be `0x0000000000000001000000000000000063BD8940`

All signers (and dummy signer) must be included in every call to `verify_signatures`. If a signer is not needed or chooses to not participate in that transaction set the signature to 65 empty bytes which will cause it to be skipped when doing the `ecrecover`.

## Burn Hash
If a transaction needs to be blocked or otherwise invalidated, Vega validators can run the function:
`burn_final_hash(bytes32 bad_final_hash, uint256 tx_id, bytes calldata signer_set_data, bytes calldata signatures)` 
This will invalidate the final hash and thus stop a transaction from going through.
* `bad_final_hash`: the "final hash" as described above, that is to be invalidated
* `tx_id`: a Vega assigned unique identifier for this transaction

# Pseudo-code / Examples
The MultisigControl smart contract contains the following functions and events.

```go
contract MultisigControl {
   
    /***************************EVENTS****************************/
    event Signers_Updated(bytes32 new_signer_set_data_hash, uint16 new_threshold);
    event Final_Hash_Burned(bytes32 bad_final_hash);

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

# Vega-side Integration
The change in structure will require a change in how validators are added and removed on the Vega-side. 
First, now weights of validators are accounted for on the smart contract, so during the update signer process the weights will need to be gathered and added to the function call. This new update method allows for multiple signers to be swapped in or out, and weights updated, with a single call. 
Second, before validators sign the command, they will need to verify the entire signer set and weights are what they expect to be, as well as verify that the signer set nonce (see section above) fits the expected format of `0x[8 byte current epoch number][4 bytes 0][8 byte timestamp]`
Worth noting is the threshold can be adjusted at the same time as a signer set update.

In order to have a full picture of what transactions have been claimed, Vega must monitor for all events that utilize the Multisig Control contract, this includes the following events:

* `Multisig_Control_Set(address indexed new_address, uint256 tx_id)`
* `Bridge_Address_Set(address indexed new_address, uint256 tx_id)`
* `Asset_Withdrawn(address indexed user_address, address indexed asset_source, uint256 amount, uint256 tx_id)`
* `Asset_Deposited(address indexed user_address, address indexed asset_source, uint256 amount, bytes32 vega_public_key)`
* `Asset_Deposit_Minimum_Set(address indexed asset_source,  uint256 new_minimum, uint256 tx_id)`
* `Asset_Listed(address indexed asset_source,  bytes32 indexed vega_asset_id, uint256 tx_id)`
* `Asset_Removed(address indexed asset_source,  uint256 tx_id)`
* `Signers_Updated(bytes32 new_signer_set_data_hash, uint16 new_threshold)`
* `Final_Hash_Burned(bytes32 bad_final_hash)`
* `Asset_Migrated(address indexed asset_source, uint amount)`


# Signed Transaction Invalidation
Any outstanding transactions that have been signed by validators, but not executed, will be invalidated once the signer set changes. This will happen automatically in the smart contract once the signer set change is executed as the signer set hash will not match any prior standing orders. 

Vega must account for this by using the `Asset_Withdrawn` events. Once verified to be unclaimed, a new signature bundle can be issued or the user can be credited with the outstanding balance.

# Assumptions
In order for outstanding Multisig orders to be invalidated the following MUST be true:
* Vega sees all relevant multisig events from ETH
* Vega sees them in order, or at least knows the order
* Vega does not reissue a multisig order until it has seen the Sigher Set Updated event AND it has processed all previous events from that and previous blocks
* Enough ETH blocks have passed to be assured of finality
* Vega MUST keep an ordered list of validator nodes and weights that, when hashed, matches the signer set hash stored in the multisig contract.
 
If those conditions are met, Vega knows if a multisig order has been executed or not, and can respond correctly.

# V1 to V2 Migration
This spec covers version 2 of Multisig Control.
Due to function signature changes, deploying v2 will require a full migration and update of the Multisig Control, ERC20 Bridge, and ERC20 asset pool. 

This will necessitate a temporary migration smart contract that takes the place of the Asset Pool's ERC20 bridge and thus gains control of the "withdrawal" function that it will use to deposit (or transfer) to the v2 bridge (or asset pool)

Migration steps:
1. Deploy the v2 multisig, bridge, and pool contracts
2. Halt the v1 ERC20 bridge, this emits the `Bridge_Stopped` event, after which we know no more withdrawals can be executed 
3. Deploy Migration Contract
4. Assign Migration Contract as the asset pool's ERC20 Bridge (a multisig transaction)
5. Run `migrate_asset` function for the entirety of each asset in the Asset Pool to either v2 bridge via deposit function or directly to the v2 asset pool, depending on how things need to be done on the Vega side
6. Account for executed withdrawals by using `Asset_Withdrawn` events and either reissue withdrawal bundles, or credit user on Vega with unclaimed invalidated withdrawals

## Migration Contract
This smart contract replaces the Bridge Logic smart contract when an asset pool migration needs to occur. It contains a single function that migrates a given amount of a given asset.

`function migrate_asset(address asset_source, uint amount)`

# Acceptance Criteria
### Vega-Side
* Every signer set and weight update MUST contain a random dummy signer as nonce. 
* The dummy signer MUST follow the format `0x[8 byte current epoch number][4 bytes 0][8 byte timestamp]`. 
* Every validator MUST verify that the epoch number and timestamp are correct.
* Every node must verify every Withdrawal event

### Multisig_Control Smart Contract 
* `verify_signatures` must take in a message hash, byte string of signer set data, and byte string of signatures and make the following checks:
   * all recovered addresses from signatures match their position in the signer set
   * signer set hash must match stored signer set hash
   * summed weights of addresses that signed must be greater than the stored threshold
* `verify_signatures` must not run if below threshold
* `verify_signatures` must not allow reuse of signature bundle
* `verify_signatures` must not allow use of burned final hash
* `verify_signatures` must not allow use of signature bundle issued by anything other than the current signer set
* `verify_signatures` must not allow any alterations of the signature bundle
* `verify_signatures` must not allow any alterations of the signer set
* `verify_signatures` must not allow any alterations of the message hash
* `burn_final_hash` must stop a final hash from being used with `verify_signature`
* `burn_final_hash` must use Multisig Control
* `update_signers` must update the signer set hash
* `update_signers` must invalidate previously valid multisig transaction
* `update_signers` must use Multisig Control
* `update_signers` must update threshold
* `is_final_hash_used` must return false for unused final hash
* `is_final_hash_used` must return true for burned final hash
* `is_final_hash_used` must return true for used final hash
* `get_signer_set_data_details` must show signer set data hash and current threshold

### Multisig_Control Consuming Smart Contract
* Every Multisig_Control protected function must call `verify_signatures` on Multisig_Control passing in the appropriate parameters
* Every Multisig_Control protected function must implement some uniqueness in their message_hash 
