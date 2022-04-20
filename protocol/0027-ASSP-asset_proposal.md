Feature name: Asset proposals

# Asset proposals

This spec covers the common aspects of creation, discoverability, and modification on the Vega network of new assets, as well as the specifics of this process for ERC20 tokens on the Ethereum blockchain.
Future specs (or updates to this spec) will cover implementation of other chains/assets (ETH, Cosmos/Terra/IBC, BTC, etc…).
Implementation should keep in mind that the framework will be extended to other chains/assets.


# Reference-level explanation

## Proposing a new asset

The addition of a new asset is achieved using the on-chain governance system.
This requires a [governance proposal](./0028-GOVE-governance.md#new-asset-proposals) type for addition of a new asset to the network's set of supported assets.
This proposal can be initiated by anyone with a sufficient number of vega tokens.
The proposal vote for an asset is done in two steps, first by the validator nodes firsts, then by the token holders.

First, When a new asset is proposed to the network, the asset validity's (see [asset framework](./0040-ASSF-asset_framework.md)) is verified against the origin blockchain, which allows the vega network to recover information about the asset (e.g: ticker symbol, name, decimal place, etc).
If the asset is accepted by the node, the node will then send it's own vote as a transaction to the chain, so the other validators can keep track of whom is accepting the new asset.
This first phase may be configured through [network parameters](./0054-NETP-network_parameters.md) (e.g: duration of the phase, what proportion of validators are required to approve in order to validate the asset, etc.).
In a first version it would be acceptable to hard code these value (e.g: 1 hours duration for the node to validate the asset, at least two thirds + one of the nodes needs to succeed.

Once this first step is done, if enough validators were able to approve the asset, the network will proceed with accepting token holder votes.
If not enough validators approved the asset in the time allowed, then the new asset proposal is rejected.

The second part of the vote follows the normal governance flow.


## Enabling a new asset on the bridge

Once the proposal is accepted, validators will produce a bundle (e.g. transaction plus signature/s) for submission to the asset's originating blockchain. Vega nodes will make this bundle available via an API.
- In the case of Ethereum/EVM ERC20 tokens, this bundle will be an Ethereum transaction to whitelist the asset on the [bridge](./0031-ETHB-ethereum_bridge_spec.md) via [multisig control](./0030-ETHM-multisig_control_spec.md), and a set of signatures to authenticate the transaction with multisig control.


## Enabling a new asset on vega

Once the asset as been allowlisted on the originating chain, meaning that deposits in this asset will be accepted to the bridge, be notified of this (via the [event queue](./0036-BRIE-event_queue.md)) a notification, which will need to be sent through the chain, so all nodes can enabled the asset.

Once this has been done, the new asset is ready to be used in the vega network to create new markets.


## Modifying an existing asset

If an asset modification that went through [governance](./0028-GOVE-governance.md) is enacted and it changes one of: `maximumLifetimeDeposit`, `withdrawalDelayPeriod` and `withdrawalDelayThreshold` then a signed payload for the appropriate bridge is emmited (and that's all that happens). 
Anyone willing to pay the transaction fee (gas) can submit this to the bridge contract via multisig control and cause the changes to be appropriately reflected there. 
Vega will then update it's internal asset definition once the events are emmitted and confirmed the correct number of times by the bridge chain.


# Changes initiated on chain

In addition to changes initiated by governance on Vega, an asset's particulars can change on its originating chain. 
The details that are sourced from the originating chain may vary by blockchain and aasset standard. 
For ERC20 on Ethereum, this would be the asset's `name`, `symbol`, and `totalSupply`.

Vega nodes will run nodes for all bridged chains. They will either listen to the relevant events or poll the current value of these data reguarly in order to ensure that the asset data on Vega reflects the current value (after the configured number of confirmations). 
In the case of Ethereum ERC20 assets, in will be necessary to poll the contract's "read" functions (name, symbol, totalSupply) as specified in the ERC20 standard, because no events are standardised for changes to these values.
This polling would ideally be done with each new Ethereum block, but if this is too expensive (in computational costs — there is no gas for read functions) then as long as it occurs at least once per epoch this is acceptable. 

**Note on `decimals`.** The Vega ERC20 bridge does not support assets with a changing number of deicmals, and is unlikely ever to support such assets (due to both the added complexity and the lack of demonstrable use cases for this). 
Therefore, it is undefined how to proceed in the event that decimals does change, and the specific, immutable instance of the token smart contract on the Ethereum blockchain much be verified by community members when voting on each new asset that is proposed to ensure that the number of decimals used by the asset is guaranteed to be perpetually invariant for the lifetime of the asset.
Contracts that do not meet this guarantee are not suitable as a basis for Vega bridge assets.


# Pseudo-code / Examples

Changes to the voting:

```

message ERC20 {
	// contract address of an ERC20 token
	string contractAddress = 1;
}

message BTC {
	// some btc require fields
	// e.g network to use etc.
}

message AssetSource {
  oneof source {
	// vega internal assets
	BuiltinAsset builtinAsset = 1;
	// foreign chains assets
	ERC20 erc20 = 2;
	// more to be done, BTC, ETH, etc..
	BTC btc = 3;
  }
   
}

message NewAsset {
  AssetSource changes = 1 [(validator.field) = {msg_exists: true}];
  // an minimal amount of stake to be committed 
  // by liquidity providers.
  // use the number of decimals defined by the asset.
  string quantum = 1000000000000000000;
}

message ProposalTerms {
  int64 closingTimestamp       = 1 [(validator.field) = {int_gt: 0}];
  int64 enactmentTimestamp     = 2 [(validator.field) = {int_gt: 0}];
  uint64 minParticipationStake = 3 [(validator.field) = {int_gt: 0}];
  oneof change {
    UpdateMarket  updateMarket  = 101;
    NewMarket     newMarket     = 102;
    UpdateNetwork updateNetwork = 103;
	// new field:
	NewAsset = newAsset = 104;
  };
}
```

## An ERC20 example
```
{
	"newAsset": {
		"changes": {
			"contractAddress": "0xsomething"
		},
		"quantum": "10000000" // if the asset supports 5 decimals = 100.00000
	}
}
```


Note that the `quantum` field sets the minimum economically meaningful amount in the asset. 
For example for USD this may be 1 USD or perhaps 0.01 USD. 


# Acceptance Criteria

## user actions

- [ ] As a user I can submit a new proposal asset to be used in vega (<a name="0027-ASSP-001" href="#0027-ASSP-001">0027-ASSP-001</a>)
- [ ] As a user I can vote for an asset proposal. (<a name="0027-ASSP-002" href="#0027-ASSP-002">0027-ASSP-002</a>)
- [ ] As a user, original submitter of the asset, I can call the node to get a signature of the asset, so I can send it to the asset bridge, and whitelist the asset. (<a name="0027-ASSP-003" href="#0027-ASSP-003">0027-ASSP-003</a>)
- [ ] `quantum` is a required parameter  (<a name="0027-ASSP-004" href="#0027-ASSP-004">0027-ASSP-004</a>)
 
## node actions

- [ ] As a node, when a new asset proposal is emitted, I can validate the asset with it's chain, and send the result of the validation through the chain to the other nodes (first phase proposal) (<a name="0027-ASSP-005" href="#0027-ASSP-005">0027-ASSP-005</a>)
- [ ] As a node, when a new asset is accepted through governance, I can sign a payload to the user so they can whitelist the asset with the bridge (<a name="0027-ASSP-006" href="#0027-ASSP-006">0027-ASSP-006</a>)
- [ ] AS a node, I receive events from the external blockchain queue, that's confirm the asset is enabled in the bridge. (<a name="0027-ASSP-007" href="#0027-ASSP-007">0027-ASSP-007</a>)
- [ ] As a node, when an existing asset is modified through governance changing any one of `maximumLifetimeDeposit`, `withdrawalDelayPeriod` and `withdrawalDelayThreshold`, emit a signed a payload to the world so that they can update the corresponding parameters on the bridge (<a name="0027-ASSP-007" href="#0027-ASSP-007">0027-ASSP-007</a>)
