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

A signature bundle is a hex string of appended 65 byte ECDSA signatures where each signer signed the same message hash usually containing the parameters of the function being called and a nonce that is used to prevent replay attacks.

Pseudo Example:  a smart contract has a withdraw event, that function requires ethereum address and amount to be withdrawn. Each Vega validator signer would sign `keccack256(address, amount)` which each result in a 65 byte hex string in the format `0x1230477...` the `0x` is removed (except for the first in the bundle) and appended to the end of the bundle of other validator signatures. 
This bundle is accepted by the multisig smart contract and broken into individual signatures and checked against the valid signer list. If the number of valid signatures if above the threshold %, this is a valid bundle.   

# Pseudo-code / Examples
The Multisig smart contract contains the following functions and events.

```javascript
contract MultisigControl {
    event SignerAdded(address new_signer);
    event SignerRemoved(address old_signer);
    event ThresholdSet(uint16 new_threshold);
    
    /*********ADMIN (note: this only is needed in order to simplify initial onboarding of nodes, once ownership is surrendered these will no longer be available)*/
    event SignerAdded_Admin(address new_signer);
    event SignerRemoved_Admin(address old_signer);
    event ThresholdSet_Admin(uint16 new_threshold);
    function add_signer_admin(address new_signer) public onlyOwner;
    function remove_signer_admin(address old_signer) public onlyOwner;
    function set_threshold_admin(uint16) public onlyOwner;
    /*********End ADMIN*/
    

    //Sets threshold of signatures that must be met before function is executed. Emits 'ThresholdSet' event
    function set_threshold(uint16 new_threshold, uint nonce, bytes memory signatures) public;
    
    //Adds new valid signer and adjusts signer count. Emits 'SignerAdded' event
    function add_signer(address new_signer, uint nonce, bytes memory signatures) public;

    //Removes currently valid signer and adjust signer count. Emits 'SignerRemoved' event
    function remove_signer(address old_signer, uint nonce, bytes memory signatures) public;
    
    //Verifies a signature bundle and returns true only if the threshold of valid signers is met, 
    //this is a function that any function controlled by Vega MUST call to be securely controlled by the Vega network  
    function verify_signatures(bytes memory signatures, bytes32 message_hash) public returns(bool);

    //Returns the message hash that is to be signed by a Vega validator node 
    function get_message_hash(bytes memory to_hash) public pure returns(bytes32);
    
    //Returns number of valid signers
    function get_valid_signer_count() public view returns(uint8);
    
    //Returns current threshold
    function get_current_threshold() public view returns(uint16);
    
    //Returns true if address provided is valid signer
    function is_valid_signer(address signer_address) public view returns(bool);
}
```  

# Acceptance Criteria
### MultisigControl Smart Contract 
* MultisigControl smart contract is deployed to Ethereum testnet (tbd - Ropsten?)
* Set Threshold
  * A valid signature bundle, threshold (in hundredths of %), and unused nonce can be passed to `set_threshold` function to set the approval threshold in hundredths of a percent (`TODO: check this mechanism/math`)
  * A successful call to `set_threshold` emits `ThresholdSet` event
  * Subsequent calls to `get_current_threshold()` returns updated threshold value
  * An invalid signature passed to `set_threshold` function is rejected 
  * A threshold passed to `set_threshold` outside of sane range is rejected
  * A nonce passed to `set_threshold` that has already been used is rejected
* Add Signer 
  * A valid signature bundle, non-signer ethereum address, and unused nonce can be passed to `add_signer` function to add an Ethereum address of a new signer to the list of approved signers
  * A successful call to `add_signer` increments signer count
  * A successful call to `add_signer` emits `SignerAdded` event
  * Subsequent calls to `is_valid_signer()` with added Ethereum address returns true until that signer is removed 
  * An invalid signature bundle, currently approved signer address, or used nonce passed to `add_signer` is rejected
* Remove Signer
  * A valid signature bundle, current signer Ethereum address, and unused nonce can be passed to `remove_signer` to remove a currently valid signer from the list of signers
  * A successful call to `remove_signer` decrements signer count
  * A successful call to `remove_signer` emits `SignerRemoved` event
  * Subsequent calls to `is_valid_signer()` with removed Ethereum address returns false unless that signer is re-added
  * An invalid signature bundle, non current signer Ethereum address, or used nonce passed to `remove_signer` is rejected
* Getters
  * `get_valid_signer_count()` returns current count of valid signers
  * `get_current_threshold()` returns current threshold
  * `is_valid_signer()` returns true is signer is valid
* Admin functions (note, these can be removed after testing as they only simplify onboarding/testing)
  * `set_threshold_admin` 
    * `set_threshold_admin` can be called by the smart contract owner address and will update the threshold
    * A successful call to `set_threshold_admin` emits `ThresholdSet_Admin` event
    * Subsequent calls to `get_current_threshold()` returns updated threshold value
    * A threshold passed to `set_threshold_admin` outside of sane range is rejected
    * A call to `set_threshold_admin` from any Ethereum address other than the smart contract owner is rejected 
  * `add_signer_admin`
    * `add_signer_admin` can be called with a non-current signer Ethereum address by the smart contract owner address and provided address will be added
    * A successful call to `add_signer_admin` emits `SignerAdded_Admin` event
    * Subsequent calls to `is_valid_signer()` with added Ethereum address returns true until that signer is removed 
    * A current signer address passed to `add_signer_admin` is rejected
    * A call to `add_signer_admin` from any Ethereum address other than the smart contract owner is rejected
  * `remove_signer_admin`
    * `remove_signer_admin` can be called with a current signer Ethereum address by the smart contract owner address and provided address will be removed
    * A successful call to `remove_signer_admin` emits `SignerRemoved_Admin` event
    * Subsequent calls to `is_valid_signer()` with removed Ethereum address returns false unless that signer is re-added 
    * An invalid signer address passed to `remove_signer_admin` is rejected
    * A call to `remove_signer_admin` from any Ethereum address other than the smart contract owner is rejected

### MultisigControl Consuming Smart Contract
* MultisigControl consuming smart contract (such as bridge) is deployed to Ethereum testnet (tbd - Ropsten?)
* Consuming smart contract calls `verify_signatures` with valid signature bundle and message hash is returned true if the valid signature count is over threshold % of total signers 
 