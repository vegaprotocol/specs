# Asset framework

## Summary

Vega uses various digital assets (cryptocurrencies or tokens) to settlement positions in its markets.
In order to ensure the safety, security, and allocation of these assets, they must be managed in a fully decentralised and extensible way. Here, we lay out a framework for assets in Vega.
This specification covers how the new asset framework allow users of the vega network to create new asset (Whitelist) to be used in the vega network, also covered is deposits and withdrawal for an asset.

## Guide-level explanation

### Asset Definition

The following code sample lays out the representation for assets being hosted in foreign network (e.g.: ERC-20 on ethereum).
Common to all asset definitions are the basic fields from the Asset message, these are either retrieved from the foreign chain, or submitted through governance proposal.

In the case of an ERC-20 token for example, only the contract address of the token will be submitted via a new asset proposal.
From there the vega node will retrieve all other information for the token from and ethereum node (name, symbol, `totalSupply` and decimals).

The asset specific details are contained within the source field, which can be one of the different source of assets supported by vega.

```protobuf
syntax = "proto3";

package vega;
option go_package = "code.vegaprotocol.io/vega/proto";

message Asset {

  string ID = 1;  // immutable
  string name = 2;
  string symbol = 3;
  string totalSupply = 4;
  uint64 decimals = 5;  // immutable
  string quantum = 1000000000000000000;

  oneof source {
    BuiltinAsset builtinAsset = 101;
    ERC20 erc20 = 102;
  }  // immutable
}


message AssetSource {
  oneof source {
    BuiltinAsset builtinAsset = 1;
    ERC20 erc20 = 2;
    // expandable as necessary
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
  string maximumLifetimeDeposit = 100000; // note that 100000 in this example is effectively 1, as the asset has 5 decimals
  string withdrawalDelayThreshold = 1000000;  // this is effectively 10 due to the 5 decimals
}

message DevAssets {
  repeated AssetSource sources = 1;
}
```

See:

- [assets proto](https://github.com/vegaprotocol/vega/blob/develop/protos/sources/vega/assets.proto)
- [governance proto](https://github.com/vegaprotocol/vega/blob/develop/protos/sources/vega/governance.proto)

The `maximumLifetimeDeposit` and `withdrawalDelayThreshold` govern how [limits](../non-protocol-specs/0003-NP-LIMI-limits_aka_training_wheels.md) behave.

All the asset definition fields are immutable (cannot be changed even by governance) except:

- `name`, `symbol`, `totalSupply` — refer to the asset proposal spec. for the relevant chain for whether or not these can be changed for assets on that chain, and if so, the mechanism by which they change
- `quantum`, `maximumLifetimeDeposit`, `withdrawalDelayThreshold` —
These can be changed by asset modification [governance proposal](./0028-GOVE-governance.md).

## Asset framework fields

### `quantum`

This field defines an approximation of the smallest “meaningful” amount of an asset.

It exists to get around the fact that it is not always possible to guarantee a precise exchange rate between assets and a common reference asset (such as USD), however an approximate assessment of the value of the asset is necessary for purposes such as spam protection, reward calculation, etc.

By convention we intend this field to be set to the quantity of the asset valued at around the value of 1 USD.
It is in fact allowed and expected to be sufficiently imprecise that it would be perfectly acceptable for quantum to be set at a value of around 1 of any of USD/EUR/GBP, at any time a decade or so either side of today.

This convention makes sense because many assets on Vega are expected to be stablecoins, so they can be created with quantum set to 1 (or something around 1 USD if not close enough already) and mostly ignored.
More volatile assets will require occasional updates via governance, but again, as we can cope with significant variance, this should not need to happen too often, even for volatile assets.

A consequence of this is that quantum should only ever be used to drive aspects of the protocol where an order of magnitude variance from the $1 "standard" can be comfortably tolerated. For example, the minimum LP commitment on a market, minimum size of a user initiated transfer, or a threshold of significant trading required to be eligible for a market creation reward.

In general, quantum would be expected to be used with a multiplier, often specified as a network parameter for the specific use case, for example:

- To reward market creators after a market they created does in the order of magnitude of $10m of lifetime volume, use a threshold of `quantum ✖️ 10^7`

- To prevent transferring value less than in the order of magnitude of $0.01, use `quantum ✖️ 10^-2`

- To require a minimum stake of in the order of magnitude of $1000, use `quantum ✖️ 10^3`

It is recommended that:

- `quantum` **should not be relied on directly without a configurable multiplier**, even if this is initially one, as many assets could experience a significant run-up or drop in value and it is both easier (and less likely to be controversial from a governance perspective) to change a multiplier affecting a specific feature quickly than to change quantum on many assets.

- **`quantum` multipliers should not be shared between unrelated features**, as even if they seem to require roughly the same value initially, it may become apparent that the value implied by the multiplier is too high for one feature and simultaneously too low for another. If they do not have independent multipliers, this problem cannot be satisfactorily resolved.

- **`quantum` should be set to round values**, as it is an imprecise measure and represents an order of magnitude level approximation of value. For example, at the time of writing, BTC is $21,283.44. This implies setting quantum to `46984885901903` for a wBTC (wrapped BTC) asset with 18 decimals. *Don't do this!* A much more reasonable value would be `50000000000000` ($1 if BTC is $20,000) or `40000000000000` ($1 if BTC is $25,000).

- If the Solana token is added, try to resist the temptation to set a quantum of SOL to `007`.

## Asset Listing Process

This process start with an user submitting a new asset proposal to the vega network. This follows all the normal process for a new proposal (e.g: validation, vote, etc).
After an asset has been approved and voted in, the proof of that action needs to be submitted to the appropriate asset bridge to whitelist the asset.
There are many interfaces and protocols to manage cryptocurrencies and other digital assets, so each protocol and asset class that is supported by Vega has a bridge that manages the storage and distribution of deposited assets in a decentralised manner.
Most of these rely on some form of multi-signature security managed either by the protocol itself or via smart contracts.
In order for the Vega network to hold value via asset bridges, assets must be added to Vega and that order must be propagated to the appropriate Vega bridge smart contract.
To add a new asset to Vega, a market maker or other interested party will submit the a new asset proposal to the Vega API for a governance vote.

### Governance Vote

`https://github.com/vegaprotocol/vega/blob/develop/proto/governance.proto`
`ProposalTerms`

```proto
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

#### Ethereum-based assets on the bridge

Once an asset is listed, the submitter of the listing will request an aggregated multisig signature bundle from Vega validator nodes. See: [multisig control spec](./0030-ETHM-multisig_control_spec.md).
All Ethereum assets are managed by a smart contract that supports the `IVega_Bridge` interface. The interface defines a function to whitelist new assets:

`function whitelist_asset(address asset_source, uint256 asset_id, uint256 vega_id, bytes memory signatures) public;`

Once a successful whitelist_asset transaction has occurred, the `Asset_Whitelisted` event will be emitted for later use by the Vega Event Queue.
See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

##### Ether (ETH) on the bridge

Ether (ETH) is not supported unless wrapped as an ERC20.

##### ERC-20 on the bridge

To add a new ERC-20, the signature bundle and token address is submitted to the appropriate Vega ERC-20 bridge by way of the `whitelist_asset` function.
Upon successful execution of the `whitelist_asset` function, that token will be available for on-chain deposits via the `deposit_asset` function on the smart contract.
Deposits that are made to the contract will raise the `Asset_Deposited` event which will then be consumed and propagated through Vega consensus by way of the Event Queue.

##### Other Ethereum Token Standards

This section will be expanded if additional Ethereum token standards are supported by Vega. New bridges will be expected to implement `IVega_Bridge`.

#### Other Assets on the bridge

This section will be expanded when asset bridges to other blockchains are supported by Vega. Since blockchains and their supported asset standards vary significantly, each section will be unique.

### Event Queue

Once the listing transaction has completed the Vega Event Queue will package it up as an event and submit it through Vega consensus. Once added to the Vega blockchain, this is known to be resolved.

## Asset Deposit Process

In order to acquire an asset balance on the Vega network, a user must first deposit an asset using a Vega Asset Bridge. There is a bridge for every asset class supported by and voted into Vega. Due to variation in asset infrastructure, each bridge will have a different way to make a deposit, and are described here.

### Vega Bridge Assets

#### Ethereum assets

All Ethereum assets are managed by a smart contract that supports the `IVega_Bridge` interface.
The interface defines a function to deposit assets:

`function deposit_asset(address asset_source, uint256 asset_id, uint256 amount, bytes32 vega_public_key) public;`

Once a successful deposit transaction has occurred, the `Asset_Deposited` event will be emitted for later use by the Vega Event Queue.
See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

##### ERC-20 assets

ERC-20 tokens have a token address but no individual token ID, as such, the Vega ERC-20 Bridge will require that a user pass 0 as `asset_id` for all ERC-20 tokens. `asset_source` will be the address of the asset token smart contract.

NOTE 1: This function expects that the token being used has been whitelisted.

NOTE 2: Before running this function, the user must run the ERC-20-standard `approve` function to authorise the bridge smart contract as a spender of the user's target token. This will only allow a specific amount of that specific token to be spent by the bridge. See: [Ethereum improvement proposal 20](https://eips.ethereum.org/EIPS/eip-20)

##### Other Ethereum Token Standards (Depositing)

This section will be expanded if additional ethereum based token standards are supported by Vega. New bridges will be expected to implement `IVega_Bridge`.

#### Other Assets

This section will be expanded when asset bridges to other blockchains are supported by Vega. Since blockchains and their supported asset standards vary significantly, each section will be unique.

### Event Queue Path

Once a deposit is complete and the appropriate events/transaction information is available on the respective chain, the transaction is recognised by the Vega Event Queue and packaged as an event.
This event is submitted to Vega consensus, which will verify the event contents against a trusted node of the appropriate blockchain.
A consequence of the transaction being verified is the Vega public key submitted in the transaction will be credited with the deposited asset in their Vega account.

## Asset Withdrawal Process

Once a user decides they would like to remove their assets from the Vega network, they will submit a withdrawal request via the Vega website or API.
This request, if valid, will be approved and assigned en expiry. This order will then be put through Vega consensus.
After the order is made and saved to chain, the validators will sign the multisignature withdrawal order and the aggregate of these will be made available to the user to submit to the appropriate blockchain/asset management API.

### Withdrawal Request

All withdrawal request contains a common part, in order to identify a party on the network, specify an asset and amount, as well as a foreign chain specific part in order to identify the user wallet / address / public key in the foreign chain.

```proto
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

Same process as `AssetList`. See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

### Vega Asset Bridges (Signing)

After signatures are aggregated a user is ready to make the withdrawal transaction. Each asset has a different withdrawal process, but they will primarily be managed by Vega Bridges, a CQRS pattern Vega uses to integrate the various blockchains and asset management APIs.
Where available, multisignature withdrawal orders will have a built-in and protocol-enforced expiration timestamp.

#### Signing Ethereum-based assets

All Ethereum assets are managed by a smart contract that supports the `IVega_Bridge` interface.
The interface defines a function to withdrawal assets:

`function withdraw_asset(address asset_source, uint256 asset_id, uint256 amount, uint256 expiry, uint256 nonce, bytes memory signatures) public;`

Once a successful withdrawal transaction has occurred, the `Asset_Withdrawn` event will be emitted for later use by the Vega Event Queue. See: [Ethereum Bridge spec](./0031-ETHB-ethereum_bridge_spec.md).

##### Signing ERC-20

ERC-20 tokens have a token address but no individual token ID, as such, the Vega ERC-20 Bridge will require that a user pass 0 as `asset_id` for all ERC-20 tokens. `asset_source` will be the address of the asset token smart contract.

##### Signing other Ethereum Token Standards

This section will be expanded if additional ethereum based token standards are supported by Vega. New bridges will be expected to implement `IVega_Bridge`.

#### Signing other Assets

This section will be expanded when asset bridges to other blockchains are supported by Vega. Since blockchains and their supported asset standards vary significantly, each section will be unique.

### Event Queue Path (Signing)

Once a withdrawal is complete and the appropriate events/transaction information is available on the respective chain, the transaction is then recognised by the Vega Event Queue and packaged as an event. This event is submitted to Vega consensus, which will verify the event contents against a trusted node of the appropriate blockchain, which completes the cycle.

## Acceptance Criteria

For each asset class to be considered "supported" by Vega, the following must happen:

1. An asset of that class can Be voted into Vega (<a name="0040-ASSF-001" href="#0040-ASSF-001">0040-ASSF-001</a>)
2. An asset previously voted in can be voted out of Vega (<a name="0040-COSMICELEVATOR-002" href="#0040-COSMICELEVATOR-002">0040-COSMICELEVATOR-002</a>)
3. A voted-in asset can be deposited into a Vega bridge (<a name="0040-ASSF-003" href="#0040-ASSF-003">0040-ASSF-003</a>)
4. A properly deposited asset is credited to the appropriate user (<a name="0040-ASSF-004" href="#0040-ASSF-004">0040-ASSF-004</a>)
5. A withdrawal can be requested and verified by Vega validator nodes (<a name="0040-ASSF-005" href="#0040-ASSF-005">0040-ASSF-005</a>)
6. multisig withdrawal order signatures from Vega validator nodes can be aggregated at the request of the user (<a name="0040-ASSF-006" href="#0040-ASSF-006">0040-ASSF-006</a>)
7. A user can submit the withdrawal order and receive their asset (<a name="0040-ASSF-007" href="#0040-ASSF-007">0040-ASSF-007</a>)
8. Every asset must specify `quantum` and this must be an integer strictly greater than `0` (<a name="0040-ASSF-008" href="#0040-ASSF-008">0040-ASSF-008</a>)
