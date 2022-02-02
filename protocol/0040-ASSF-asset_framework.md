# Summary
Vega uses various asset classes as settlement assets for markets. In order to ensure the safety, security, and allocation of these assets, they must be managed in a fully decentralized and extensible way. Here, we lay out a framework for assets in Vega.
This specification covers how the new asset framework allow users of the vega network to create new asset (Whitelist) to be used in the vega network, are not covered deposits and withdrawal for an asset.

# Guide-level explanation
## Asset Definition
The following code sample lay out the common representation for assets being hosted in foreign network (e.g: erc20 on ethereum).
The common part to all asset are the basic fields from the Asset message, these are either retrieved from the foreign chain, or submitted through governance proposal.

In the case of an ERC20 token for example, only the contract address of the token will be required, from there the vega node will retrieve all other information for the token from and ethereum node (name, symbol, totalSupply and decimals).

The asset specific part is represented by the source field, which can be one of the different source of assets supported by vega.


```protobuf
syntax = "proto3";

package vega;
option go_package = "code.vegaprotocol.io/vega/proto";

message Asset {

  string ID = 1;
  string name = 2;
  string symbol = 3;
  string totalSupply = 4;
  uint64 decimals = 5;
  string quantum = 1000000000000000000; 

  oneof source {
    BuiltinAsset builtinAsset = 101;
    ERC20 erc20 = 102;
  }
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
This process start with an user submitting a new asset proposal to the vega network. This follow all the normal process for a new proposal (e.g: validation, vote, etc).
After an asset has been approved and voted in, the proof of that action needs to be submitted to the appropriate asset bridge to whitelist the asset.
There are many interfaces and protocols to manage cryptocurrencies and other digital assets, so each protocol and asset class that is supported by Vega has a bridge that manages the storage and distribution of deposited assets in a decentralised manner.
Most of these rely on some form of multisignature security managed either by the protocol itself or via smart contracts.
In order for the Vega network to hold value via asset bridges, assets must be added to Vega and that order must be propagated to the appropriate Vega bridge smart contract.
To add a new asset to Vega, a market maker or other interested party will submit the a new asset proposal to the Vega API for a governance vote.


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
See: [Governance spec](./0028-GOVE-governance.md).

### Signature Aggregation
All new asset listing is first accepted through governance as describe before. In order to reflect the approval / the decision of the network of accepting a new asset, all validators are required to sign a specific message using a private key to which the signature can be verified by the foreign chain owning the asset.
The public key counterpart of the private key must have previously been added to the set of allowed signer for the smart contract of the bridge hosted in the foreign chain.
All vega node will aggregate the signature emitted by the validators, the clients could request at anytime the list of generated signature, and apply verification using the public keys of the validators.

See: [Multisig Control spec](./0030-ETHM-multisig_control_spec.md) 

### Vega Asset Bridges
Before an asset can be accepted for deposit by a bridge, it needs to be whitelisted on that bridge.

#### Ethereum-based assets
Once an asset is listed, the submitter of the listing will request an aggregated multisig signature bundle from Vega validator nodes. See: [multisig control spec](./0030-ETHM-multisig_control_spec.md).

All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface. The interface defines a function to whitelist new assets:

`function whitelist_asset(address asset_source, uint256 asset_id, uint256 vega_id, bytes memory signatures) public;`

Once a successful whitelist_asset transaction has occurred, the `Asset_Whitelisted` event will be emitted for later use by the Vega Event Queue.

See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

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
Bitcoin doesn't support smart contracts natively, so we've developed a virtual bridge that uses an aggregated multisig mechanism. As such, it cannot be added or removed from the bridge
See: [insert BTC spec here]

#### Other Asset Classes
This section will be expanded as new asset classes are supported by Vega. Since each asset class is different, each section will be unique but follow the multisig management pattern used by the other bridges.

### Event Queue
Once the listing transaction has completed the Vega Event Queue will package it up as an event and submit it through Vega consensus. Once added to the Vega blockchain, this is known to be resolved.

## Asset Delisting Process
In order for the Vega network to hold value via asset bridges, assets must be added to Vega and that order must be propagated to the appropriate Vega bridge smart contract.
To add a new asset to Vega, a market maker or other interested party will submit the proposal to the Vega API for a governance vote.

### Governance Vote
Same process than for listing an asset here.

### Signature Aggregation
Same process than for listing an asset here.

See: [Multisig Control spec](./0030-ETHM-multisig_control_spec.md).

### Vega Asset Bridges
Once a whitelisted asset is voted out as a valid asset by the governance process, the asset needs to be removed from that bridge.

#### Ethereum-based assets
Once an asset is delisted, the submitter of the delisting will request an aggregated [multisig signature bundle](./0030-ETHM-multisig_control_spec.md#signature-bundles) from Vega validator nodes. See: 

All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface. The interface defines a function to blacklist assets:

`function blacklist_asset(address asset_source, uint256 asset_id, uint256 nonce, bytes memory signatures) public;`

Once a successful blacklist_asset transaction has occurred, the `Asset_Blacklisted` event will be emitted for later use by the Vega Event Queue.

See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

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
Bitcoin doesn't support smart contracts natively, so we've developed a virtual bridge that uses an aggregated multisig mechanism. As such, it cannot be added or removed from the bridge
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

See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

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
For deposit, the BTC virtual bridge generates a deposit address that is presented to the user. This address is a secure, multisignature wallet, controlled in a decentralised manner by the validators of the Vega network, similar to the MultisigControl pattern used for Ethereum.
The user will provide their Vega public key along with a standard bitcoin transfer transaction. This public key will be picked up by the Vega Event Queue for later processing.
See: [insert BTC spec here]

#### Other Asset Classes
This section will be expanded as new asset classes are supported by Vega. Since each asset class is different, each section will be unique but follow the multisig management pattern used by the other bridges.

### Event Queue Path
Once a deposit is complete and the appropriate events/transaction information is available on the respective chain, the transaction is recognized by the Vega Event Queue and packaged as an event. This event is submitted to Vega consensus, which will verify the event contents against a trusted node of the appropriate blockchain. A consequence of the transaction being verified is the Vega public key submitted in the transaction will be credited with the deposited asset in their Vega account.

## Asset Withdrawal Process
Once a user decides they would like to remove their assets from the Vega network, they will submit a withdrawal request via the Vega website or API.
This request, if valid, will be approved and assigned en expiry. This order will then be put through Vega consensus.
After the order is made and saved to chain, the validators will sign the multi-signature withdrawal order and the aggregate of these will be made available to the user to submit to the appropriate blockchain/asset management API.

### Withdrawal Request
All withdrawal request contains a common part, in order to identify a party on the network, specify an asset and amount, as well as a foreign chain specific part in order to identify the user wallet / address / public key in the foreign chain.
```
 // A request for withdrawing funds from a trader
 message WithdrawSubmission {
   // The party which wants to withdraw funds
   string partyID = 1;
   // The amount to be withdrawn
   uint64 amount = 2;
   // The asset we want to withdraw
   string asset = 3;

   // foreign chain specifics
   oneof ext {
     Erc20WithdrawExt erc20 = 1001;
   }
 }

 // An extension of data required for the withdraw submissions
 message Erc20WithdrawExt {
   // The address into which the bridge will release the funds
   string receiverAddress = 1;
 }
```

### Validator Signature Aggregation
Same process than AssetList.

See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

### Vega Asset Bridges
After signatures are aggregated a user is ready to make the withdrawal transaction. Each asset has a different withdrawal process, but they will primarily be managed by Vega Bridges, a CQRS pattern Vega uses to integrate the various blockchains and asset management APIs.
Where available, multisignature withdrawal orders will have a built-in and protocol-enforced expiration timestamp.

#### Ethereum-based assets
All Ethereum assets are managed by a smart contract that supports the IVega_Bridge interface.
The interface defines a function to withdrawal assets:

`function withdraw_asset(address asset_source, uint256 asset_id, uint256 amount, uint256 expiry, uint256 nonce, bytes memory signatures) public;`

Once a successful withdrawal transaction has occurred, the `Asset_Withdrawn` event will be emitted for later use by the Vega Event Queue.

See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

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
1. An asset of that class can Be voted into Vega (<a name="0040-ASSF-001" href="#0040-ASSF-001">0040-ASSF-001</a>)
2. An asset previously voted in can be voted out of Vega (<a name="0040-ASSF-002" href="#0040-ASSF-002">0040-ASSF-002</a>)
3. A voted-in asset can be deposited into a Vega bridge (<a name="0040-ASSF-003" href="#0040-ASSF-003">0040-ASSF-003</a>)
4. A properly deposited asset is credited to the appropriate user (<a name="0040-ASSF-004" href="#0040-ASSF-004">0040-ASSF-004</a>)
5. A withdrawal can be requested and verified by Vega validator nodes (<a name="0040-ASSF-005" href="#0040-ASSF-005">0040-ASSF-005</a>)
6. multisig withdrawal order signatures from Vega validator nodes can be aggregated at the request of the user (<a name="0040-ASSF-006" href="#0040-ASSF-006">0040-ASSF-006</a>)
7. A user can submit the withdrawal order and receive their asset (<a name="0040-ASSF-007" href="#0040-ASSF-007">0040-ASSF-007</a>)
8. Withdrawal orders expire successfully (where available). (<a name="0040-ASSF-008" href="#0040-ASSF-008">0040-ASSF-008</a>)
