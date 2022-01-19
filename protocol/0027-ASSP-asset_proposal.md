Feature name: assets proposals

# Summary
This spec covers the creation, discoverability of a settlement asset in the vega network.

All markets require a settlement asset, this settlement asset will be hosted in a blockchain and all information about them will be relayed from a vega bridge on the given asset blockchain.
This spec covers how a vega user can propose a new asset, what's the mechanism to make this asset available inside vega, and usable by any market.
As of now, we will only cover implementation of ERC-20 tokens, following specs will cover implementation of other asset (first ETH, then BTC, etc, etc...), so implementation needs to keep in mind these details.

# Reference-level explanation

## Proposing a new asset

The proposal of a new asset must be done through the [governance system](./0028-GOVE-governance.md).
This means the introduction of a new proposal type in order to propose a new asset to be added to the network.
This proposal could be done by anyone with stake in vega token, although we expect market makers to do it.

The proposal vote for an asset is done in two step, first by the validator nodes firsts, then by the token holders.

First, When a new asset is proposed to the network, the [asset validity](./0040-ASSF-asset_framework.md) is verified with their origin blockchain, which allows the vega network to recover information about the asset class (e.g: symbol, name, decimal place, etc).
If the asset is accepted by the node, the node will then send it's own vote as a transaction to the chain, so the other validators can keep track of whom is accepting the new asset.
This first phase may be configured through [network parameters](./0054-NETP-network_parameters.md) (e.g: duration of the phase, how much validator needs to succeed to validate the asset).
In a first version we could hard code these value (e.g: 1 hours duration for the node to validate the asset, only two thirds + one of the nodes needs to succeed.

Once this first step is done, if enough nodes were able to validate the asset, the network will proceed with accepting token holders votes, but if not enough nodes were able to validate the asset, then the new asset is rejected.

The second part of the vote is the normal governance flow.

## Enabling a new asset on the bridge

Once the proposal is accepted, the original submitter of the proposal, can reach out to the nodes, and get confirmation (as a signature, e.g: of the contract address of the asset to enable) of the acceptance of the new asset.
The original submitter must then aggregate two thirds + one signatures from the nodes, and send them to the bridge. The bridge will then whitelist this new asset, and start forwarding event with it.
(this is the multi-signature scheme, which allow us to validate decisions in between the bridges and the vega network and is described in the bridge specs).

## Enabling a new asset on vega

Once the asset as been whitelisted, the network will receive from the event queue a notification, which will need to be sent through the chain, so all nodes can enabled the asset.

Once this has been done, the new asset is ready to be used in the vega network to create new markets.


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
