Feature name: Asset Framework

Start date: 2020-04-09

Specification PR: https://gitlab.com/vega-protocol/product/merge_requests

# Summary
Vega uses various asset classes as settlement assets for markets. In order to ensure the safety, security, and allocation of these assets, they must be managed in a fully decentralized and extensible way. Here, we lay out a framework for assets in Vega.  
[TODO, more/better summary]

# Guide-level explanation
## Asset Definition
[TODO, details/expand]

```protobuf
syntax = "proto3";

package vega;
option go_package = "code.vegaprotocol.io/vega/proto";

message Asset {

  string ID = 1;
  string name = 2;
  string symbol = 3;
  // this may very much likely be a big.Int
  string totalSupply = 4;
  uint64 decimals = 5;
  
  oneof source {
    BuiltinAsset builtinAsset = 101;
    ERC20 erc20 = 102;
  }
  
  //does not need a status because its existance is its status
}


message AssetSource {
  oneof source {
    BuiltinAsset builtinAsset = 1;
    ERC20 erc20 = 2;
    //expandable as necessary
  }
}

message BuiltinAsset {
  string name = 2;
  string symbol = 3;
  string totalSupply = 4;
  uint64 decimals = 5;
}

message ERC20 {
  string contractAddress = 1;
}

message DevAssets {
  repeated AssetSource sources = 1;
}
```
See: https://github.com/vegaprotocol/vega/blob/develop/proto/assets.proto
And: https://github.com/vegaprotocol/vega/blob/develop/proto/governance.proto


## Asset Listing Process
After an asset has been approved and voted in, the proof of that action needs to be submitted to the appropriate asset bridge to whitelist the asset. 
There are many interfaces and protocols to manage cryptocurrencies and other digital assets, so each protocol and asset class that is supported by Vega has a bridge that decentrally manages the storage and distribution of deposited assets.
Most of these rely on some form of multisignature security managed either by the protocol itself or via smart contracts.
In order for the Vega network to hold value via asset bridges, assets must be added to Vega and that order must be propagated to the appropriate Vega bridge smart contract.  
To add a new asset to Vega, a market maker or other interested party will submit the (`TODO`) to the Vega API for a governance vote.


### Governance Vote
`https://github.com/vegaprotocol/vega/blob/develop/proto/governance.proto`
`ProposalTerms `
```
oneof change {
       ...
       // Proposal change for creating new assets on Vega.
       NewAsset      newAsset      = 104;
     };
     
message NewAsset {
  AssetSource changes = 1 [(validator.field) = {msg_exists: true}];
}
```
[LINK TO GOVERNANCE SPEC]

### Signature Aggregation
[TODO]

See: https://github.com/vegaprotocol/product/blob/master/specs/0030-multisig_control_spec.md 

### Vega Asset Bridges
Before an asset can be accepted for deposit by a bridge, it needs to be whitelisted on that bridge. 

#### Ethereum-based assets
Once an asset is listed, the submitter of the listing will request an aggregated multisig signature bundle from Vega validator nodes. See: https://github.com/vegaprotocol/product/blob/Multisig_Control_Spec/specs/0030-multisig_control_spec.md#signature-bundles

All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface. The interface defines a function to whitelist new assets: 

`function whitelist_asset(address asset_source, uint256 asset_id, uint256 vega_id, bytes memory signatures) public;`

Once a successful whitelist_asset transaction has occurred, the `Asset_Whitelisted` event will be emitted for later use by the Vega Event Queue.

See: https://github.com/vegaprotocol/product/blob/master/specs/0031-ethereum-bridge-spec.md

##### Ether (ETH)
Since Ether is the only asset type in it's asset class, the ETH bridge smart contract automatically whitelists this asset. That being the case, both `whitelist_asset` and `blacklist_asset` are inoperable on this bridge smart contract.

##### ERC20 
To add a new ERC20, the signature bundle and token address is submitted to the appropriate Vega ERC20 bridge by way of the `whitelist_asset` function.
Upon successful execution of the `whitelist_asset` function, that token will be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the contract will raise the `Asset_Deposited` event which will then be consumed and propagated through Vega consensus by way of the Event Queue.
 
##### ERC1155 
The signature bundle, token address, and token ID are submitted to the appropriate Vega ERC1155 bridge by way of the `whitelist_asset` function.
Upon successful execution of the `whitelist_asset` function, that token will be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the contract will raise the `Asset_Deposited` event which will then be consumed and propagated through Vega consensus by way of the Event Queue.

##### Other Ethereum Token Standards
This section will be expanded as new token standards are supported by Vega. New bridges will be expected to implement `IVega_Bridge`. 

#### BTC
Bitcoin doesn't support smart contracts nativaly, so we've developed a virtual bridge that uses an aggregated multisig mechanism. As such, it cannot be added or removed from the bridge 
See: [insert BTC spec here]

#### Other Asset Classes
This section will be expanded as new asset classes are supported by Vega. Since each asset class is different, each section will be unique but follow the multisig management pattern used by the other bridges.     
`TODO`

### Event Queue
Once the listing transaction has completed the Vega Event Queue will package it up as an event and submit it through Vega consensus. Once added to the Vega blockchain, this is known to be resolved.

## Asset Delisting Process
In order for the Vega network to hold value via asset bridges, assets must be added to Vega and that order must be propagated to the appropriate Vega bridge smart contract.  
To add a new asset to Vega, a market maker or other interested party will submit the (`TODO`) to the Vega API for a governance vote.

### Governance Vote
[TODO FILL THIS IN]

[LINK TO GOVERNANCE]

### Signature Aggregation
[TODO]

See: https://github.com/vegaprotocol/product/blob/master/specs/0030-multisig_control_spec.md 

### Vega Asset Bridges
Once a whitelisted asset is voted out as a valid asset by the governance process, the asset needs to be removed from that bridge. 

#### Ethereum-based assets
Once an asset is delisted, the submitter of the delisting will request an aggregated multisig signature bundle from Vega validator nodes. See: https://github.com/vegaprotocol/product/blob/Multisig_Control_Spec/specs/0030-multisig_control_spec.md#signature-bundles

All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface. The interface defines a function to blacklist assets: 

`function blacklist_asset(address asset_source, uint256 asset_id, uint256 nonce, bytes memory signatures) public;`

Once a successful blacklist_asset transaction has occurred, the `Asset_Blacklisted` event will be emitted for later use by the Vega Event Queue.

See: https://github.com/vegaprotocol/product/blob/master/specs/0031-ethereum-bridge-spec.md

##### Ether (ETH)
Since Ether is the only asset type in it's asset class, the ETH bridge smart contract automatically whitelists this asset. That being the case, both `whitelist_asset` and `blacklist_asset` are inoperable on this bridge smart contract.

##### ERC20 
To remove an ERC20, the signature bundle and token address is submitted to the appropriate Vega ERC20 bridge by way of the `blacklist_asset` function.
Upon successful execution of the `blacklist_asset` function, that token will no longer be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the contract via the `deposit_asset` function will be rejected.
 
##### ERC1155 
The signature bundle, token address, and token ID are submitted to the appropriate Vega ERC1155 bridge by way of the `blacklist_asset` function.
Upon successful execution of the `blacklist_asset` function, that token will no longer be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the `deposit_asset` function will be rejected.

##### Other Ethereum Token Standards
This section will be expanded as new token standards are supported by Vega. New bridges will be expected to implement `IVega_Bridge`. 

#### BTC
Bitcoin doesn't support smart contracts nativaly, so we've developed a virtual bridge that uses an aggregated multisig mechanism. As such, it cannot be added or removed from the bridge 
See: [insert BTC spec here]

#### Other Asset Classes
This section will be expanded as new asset classes are supported by Vega. Since each asset class is different, each section will be unique but follow the multisig management pattern used by the other bridges.     

### Event Queue
Once the delist transaction has completed the Vega Event Queue will package it up as an event and submit it through Vega consensus. Once added to the Vega blockchain, this is known to be resolved. 

## Asset Deposit Process
In order to acquire an asset balance on the Vega network, a user must first deposit an asset using a Vega Asset Bridge. There is a bridge for every asset class supported by and voted into Vega. Due to variation in asset infrastructure, each bridge will have a different way to make a deposit, and are described here.    

### Vega Asset Bridges
#### Ethereum-based assets
All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface. 
The interface defines a function to deposit assets: 

`function deposit_asset(address asset_source, uint256 asset_id, uint256 amount, bytes32 vega_public_key) public;`

Once a successful deposit transaction has occurred, the `Asset_Deposited` event will be emitted for later use by the Vega Event Queue.

See: https://github.com/vegaprotocol/product/blob/master/specs/0031-ethereum-bridge-spec.md

##### Ether
In the Vega Ether Bridge smart contract, Ether is the only asset available so users run `deposit_asset` with 0 as the `asset_source`, 0 as the `asset_id`, and the `amount` being the same `msg.value` of the Ether being sent with the transaction.  

NOTE: This function expects the transaction to have an Ether value equal to `amount`

##### ERC20
ERC20 tokens have a token address but no individual token ID, as such, the Vega ERC20 Bridge will require that a user pass 0 as `asset_id` for all ERC20 tokens. `asset_source` will be the address of the asset token smart contract. 

NOTE 1: This function expects that the token being used has been whitelisted.

NOTE 2: Before running this function, the user must run the ERC20-standard `approve` function to authorize the bridge smart contract as a spender of the user's target token. This will only allow a specific amount of that specific token to be spent by the bridge. See: https://eips.ethereum.org/EIPS/eip-20

##### ERC1155
ERC1155 tokens are semi-fungible item tokens where one token smart contract manages multiple tokens, each with their own token ID. The Vega ERC1155 Bridge takes the ERC1155 token smart contract address as the `asset_source` and the token ID as the `asset_id`.

Note 1: This function expects that the token being deposited has been whitelisted

Note 2: Before running this function, the user must run the ERC1155-standard `setApprovalForAll` function to authorize the bridge smart contract as a mover of the user's tokens. This will authorize the bridge to move all of the users tokens, but the function specifically limits deposit to the specific token the owner specifies, and the bridge smart contract has no other means of moving a user's tokens.  See: https://eips.ethereum.org/EIPS/eip-1155

##### Other Ethereum Token Standards
This section will be expanded as new token standards are supported by Vega. New bridges will be expected to implement `IVega_Bridge`.

#### BTC
For deposit, the BTC virtual bridge generates a deposit address that is presented to the user. This address is a secure, multisignature wallet, decentrally controlled by the validators of the Vega network, similar to the MultisigControl pattern used for Ethereum. 
The user will provide their Vega public key along with a standard bitcoin transfer transaction. This public key will be picked up by the Vega Event Queue for later processing.
See: [insert BTC spec here]

#### Other Asset Classes
This section will be expanded as new asset classes are supported by Vega. Since each asset class is different, each section will be unique but follow the multisig management pattern used by the other bridges.

### Event Queue Path
Once a deposit is complete and the appropriate events/transaction information is available on the respective chain, the transaction is recognized by the Vega Event Queue and packaged as an event. This event is submitted to Vega consensus, which will verify the event contents against a trusted node of the appropriate blockchain. A consequence of the transaction being verified is the Vega public key submitted in the transaction will be credited with the deposited asset in their Vega account.  

## Asset Withdrawal Process
Once a user decides they would like to remove their assets from the Vega network, they will submit a withdrawal request via the Vega website or API. 
This request, if valid, will be approved and assigned en expiry. This order will then be put through Vega consensus. 
After the order is made and saved to chain, the validators will sign the multi-signature withdrawal order and the aggregate of these will be made available to the user to submit to the approprite blockchain/asset management API.  

### Withdrawal Request
[API REFERENCE]

### Validator Signature Aggregation
[TODO]

See: https://github.com/vegaprotocol/product/blob/master/specs/0030-multisig_control_spec.md 

### Vega Asset Bridges
After signatures are aggregated a user is ready to make the withdrawal transaction. Each asset has a different withdrawal process, but they will primarily be managed by Vega Bridges, a CQRS pattern Vega uses to integrate the various blockchains and asset management APIs. 
Where available, multisignature withdrawal orders will have a built-in and protocol-enforced expiration timestamp.  

#### Ethereum-based assets
All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface.
The interface defines a function to withdrawal assets:

`function withdraw_asset(address asset_source, uint256 asset_id, uint256 amount, uint256 expiry, uint256 nonce, bytes memory signatures) public;`

Once a successful withdrawal transaction has occurred, the `Asset_Withdrawn` event will be emitted for later use by the Vega Event Queue.

See: https://github.com/vegaprotocol/product/blob/master/specs/0031-ethereum-bridge-spec.md

##### Ether
In the Vega Ether Bridge smart contract, Ether is the only asset available so users run `deposit_asset` with 0 as the `asset_source`, 0 as the `asset_id`.

##### ERC20
ERC20 tokens have a token address but no individual token ID, as such, the Vega ERC20 Bridge will require that a user pass 0 as `asset_id` for all ERC20 tokens. `asset_source` will be the address of the asset token smart contract.

#### BTC
For withdrawal, the BTC virtual bridge uses bitcoin's built-in multi-signature wallets to allow a user to submit the aggregated withdrawal signatures from Vega validators to any bitcoin node to receive withdrawn BTC.
NOTE:  
See: [insert BTC spec here]

#### Other Asset Classes
This section will be expanded as new asset classes are supported by Vega. Since each asset class is different, each section will be unique but follow the multisig management pattern used by the other bridges.

### Event Queue Path
Once a withdrawal is complete and the appropriate events/transaction information is available on the respective chain, the transaction is then recognized by the Vega Event Queue and packaged as an event. This event is submitted to Vega consensus, which will verify the event contents against a trusted node of the appropriate blockchain, which completes the cycle.

# Acceptance Criteria
For each asset class to be considered "supported" by Vega, the following must happen:
1. An asset of that class can Be voted into Vega
2. An asset previously voted in can be voted out of Vega
3. A voted-in asset can be deposited into a Vega bridge 
4. A properly deposited asset is credited to the appropriate user
5. A withdrawal can be requested and verified by Vega validator nodes
6. multisig withdrawal order signatures from Vega validator nodes can be aggregated at the request of the user
7. A user can submit the withdrawal order and receive their asset  
8. Withdrawal orders expire successfully (where available).