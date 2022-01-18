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

A signature bundle is a hex string of appended 65 byte ECDSA signatures where each signer signed the same message hash usually containing the parameters of the function being called and a nonce that is used to prevent replay attacks.

Messages to be hashed then signed must be in the following format:
`abi.encode( abi.encode(target_function_param1, target_function_param2, target_function_param3, ... , msg.sender(if required), nonce, function_name_string), validating_contract_or_submitter_address);`
NOTE: target_function_params do NOT include nonce or signatures
NOTE: validating_contract_or_submitter_address is the the submitting party to the `verify_signatures` function. If on MultisigControl contract itself, it's the submitting user's ETH address, 
if function is on a referencing smart contract, such as a bridge that then calls `verify_signatures`, then it's the address of that smart contract as that will be the `msg.sender` when that function is called
NOTE: the embedded encodings `encode(encode(...))`, this is required to verify what function/contract the function call goes to. There's a possible attack if MultisigControl doesn't explicitly verify that the msg.sender is the intended msg.sender. 
NOTE: when msg.sender is required by function, that account must also be the submitter of the transaction to the Ethereum blockchain 

Pseudo Example:  
A bridge smart contract has a `withdraw_asset(address asset_source, uint256 asset_id, uint256 amount, uint256 nonce, bytes memory signatures)` function,
the function requires that msg.sender be passed along as well (given that it's the wallet address that will be credited with this withdrawal)
This means that the message to sign will look like this: 
    `abi.encode(abi.encode(asset_source, asset_id, amount, address_of_user, nonce, "withdraw_asset"), bridge_address)`
The resulting message is then hashed to a bytes32 message_hash which is then signed by a Vega validator (that has been previously added as a valid signer to the `MultisigControl` smart contract)
 
Each signature is a 65 byte hex string in the format `0x1230477...` the `0x` is removed (except for the first in the bundle) and appended to the end of the bundle of other validator signatures. 
This bundle is the `signatures` parameter ultimately passed to `verify_signatures`. In the `verify_signatures` function this signature bundle is broken into individual signatures and checked against the valid signer list. If the number of valid signatures if above the threshold %, this is a valid bundle.   

## Adding Signers
Additional Vega validator nodes are added as MultisigControl signers by running the `add_signer` function.

Following the information above from "Signature Bundles", the message to sign will look like this:
`abi.encode(abi.encode(new_signer_address, nonce, "add_signer"), submitter)`
In this case, the submitter will most likely be the new signer since they are effectively the proposer. The reason the submitter is not a contract as in the case with the bridges is that the function is called directly by a user, not by a smart contract, like the bridge. 

## Removing Signer
Vega validator nodes are removed from being MultisigControl signers by running the `remove_signer` function.
Following the information above from "Signature Bundles", the message to sign will look like this:
`abi.encode(abi.encode(old_signer_address, nonce, "remove_signer"), submitter)`
In this case, the submitter will likely be the user/party who proposed the removal of that node as a signer.  


# Pseudo-code / Examples
The MultisigControl smart contract contains the following functions and events.

```go
contract MultisigControl {
   
    /***************************EVENTS****************************/
    event SignerAdded(address new_signer);
    event SignerRemoved(address old_signer);
    event ThresholdSet(uint16 new_threshold);

    //Sets threshold of signatures that must be met before function is executed. Emits 'ThresholdSet' event
    //Ethereum has no decimals, threshold is % * 10 so 50% == 500 100% == 1000
    // signatures are OK if they are >= threshold count of total valid signers
    function set_threshold(uint16 new_threshold, uint nonce, bytes memory signatures) public;

    //Adds new valid signer and adjusts signer count. Emits 'SignerAdded' event
    function add_signer(address new_signer, uint nonce, bytes memory signatures) public;

    //Removes currently valid signer and adjust signer count. Emits 'SignerRemoved' event
    function remove_signer(address old_signer, uint nonce, bytes memory signatures) public;
    
    //Verifies a signature bundle and returns true only if the threshold of valid signers is met,
    //this is a function that any function controlled by Vega MUST call to be securely controlled by the Vega network
    // message to hash to sign follows this pattern:
    // abi.encode( abi.encode(param1, param2, param3, ... , nonce, function_name_string), validating_contract_or_submitter_address);
    // Note that validating_contract_or_submitter_address is the the submitting party. If on MultisigControl contract itself, it's the submitting ETH address
    // if function on bridge that then calls Multisig, then it's the address of that contract
    // Note also the embedded encoding, this is required to verify what function/contract the function call goes to
    function verify_signatures(bytes memory signatures, bytes memory message, uint nonce) public returns(bool);

    
    
    /**********************VIEWS*********************/
    //Returns number of valid signers
    function get_valid_signer_count() public view returns(uint8);
    
    //Returns current threshold
    //Ethereum has no decimals, threshold is % * 10 so 50% == 500 100% == 1000
    function get_current_threshold() public view returns(uint16);
    
    //Returns true if address provided is valid signer
    function is_valid_signer(address signer_address) public view returns(bool);
    
    //returns true if nonce has been used
    function is_nonce_used(uint nonce) public view returns(bool);
}
```  

# Acceptance Criteria
### MultisigControl Smart Contract 
* MultisigControl smart contract is deployed to Ethereum testnet (Ropsten) (<a name="0030-ETHM-001" href="#0030-ETHM-001">0030-ETHM-001</a>)
* Set Threshold
  * A valid signature bundle, threshold (in tenths of %), and unused nonce can be passed to `set_threshold` function to set the approval threshold in hundredths of a percent (`TODO: check this mechanism/math`) (<a name="0030-ETHM-002" href="#0030-ETHM-002">0030-ETHM-002</a>)
  * A successful call to `set_threshold` emits `ThresholdSet` event (<a name="0030-ETHM-003" href="#0030-ETHM-003">0030-ETHM-003</a>)
  * Subsequent calls to `get_current_threshold()` returns updated threshold value (<a name="0030-ETHM-004" href="#0030-ETHM-004">0030-ETHM-004</a>)
  * An invalid signature passed to `set_threshold` function is rejected  (<a name="0030-ETHM-005" href="#0030-ETHM-005">0030-ETHM-005</a>)
  * A threshold passed to `set_threshold` outside of sane range is rejected (<a name="0030-ETHM-006" href="#0030-ETHM-006">0030-ETHM-006</a>)
  * A nonce passed to `set_threshold` that has already been used is rejected (<a name="0030-ETHM-007" href="#0030-ETHM-007">0030-ETHM-007</a>)
* Add Signer 
  * A valid signature bundle, non-signer ethereum address, and unused nonce can be passed to `add_signer` function to add an Ethereum address of a new signer to the list of approved signers (<a name="0030-ETHM-008" href="#0030-ETHM-008">0030-ETHM-008</a>)
  * A successful call to `add_signer` increments signer count (<a name="0030-ETHM-009" href="#0030-ETHM-009">0030-ETHM-009</a>)
  * A successful call to `add_signer` emits `SignerAdded` event (<a name="0030-ETHM-010" href="#0030-ETHM-010">0030-ETHM-010</a>)
  * Subsequent calls to `is_valid_signer()` with added Ethereum address returns true until that signer is removed  (<a name="0030-ETHM-011" href="#0030-ETHM-011">0030-ETHM-011</a>)
  * An invalid signature bundle, currently approved signer address, or used nonce passed to `add_signer` is rejected (<a name="0030-ETHM-012" href="#0030-ETHM-012">0030-ETHM-012</a>)
* Remove Signer
  * A valid signature bundle, current signer Ethereum address, and unused nonce can be passed to `remove_signer` to remove a currently valid signer from the list of signers (<a name="0030-ETHM-013" href="#0030-ETHM-013">0030-ETHM-013</a>)
  * A successful call to `remove_signer` decrements signer count (<a name="0030-ETHM-014" href="#0030-ETHM-014">0030-ETHM-014</a>)
  * A successful call to `remove_signer` emits `SignerRemoved` event (<a name="0030-ETHM-015" href="#0030-ETHM-015">0030-ETHM-015</a>)
  * Subsequent calls to `is_valid_signer()` with removed Ethereum address returns false unless that signer is re-added (<a name="0030-ETHM-016" href="#0030-ETHM-016">0030-ETHM-016</a>)
  * An invalid signature bundle, non current signer Ethereum address, or used nonce passed to `remove_signer` is rejected (<a name="0030-ETHM-017" href="#0030-ETHM-017">0030-ETHM-017</a>)
* Getters
  * `get_valid_signer_count()` returns current count of valid signers (<a name="0030-ETHM-018" href="#0030-ETHM-018">0030-ETHM-018</a>)
  * `get_current_threshold()` returns current threshold (<a name="0030-ETHM-019" href="#0030-ETHM-019">0030-ETHM-019</a>)
  * `is_valid_signer()` returns true is signer is valid (<a name="0030-ETHM-020" href="#0030-ETHM-020">0030-ETHM-020</a>)
  * `is_nonce_used()` returns true if nonce has been used to successfully sign something previously (<a name="0030-ETHM-021" href="#0030-ETHM-021">0030-ETHM-021</a>)

### MultisigControl Consuming Smart Contract
* MultisigControl consuming smart contract (such as bridge) is deployed to Ethereum testnet (Ropsten) (<a name="0030-ETHM-022" href="#0030-ETHM-022">0030-ETHM-022</a>)
* Consuming smart contract calls `verify_signatures` with valid signature bundle and message hash is returned true if the valid signature count is over threshold % of total signers  (<a name="0030-ETHM-023" href="#0030-ETHM-023">0030-ETHM-023</a>)
 
