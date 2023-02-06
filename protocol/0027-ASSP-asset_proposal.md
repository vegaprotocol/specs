# Asset proposals

This spec covers the common aspects of creation, discoverability, and modification on the Vega network of new assets, as well as the specifics of this process for ERC20 tokens on the Ethereum blockchain.

Future specs (or updates to this spec) will cover implementation of other chains/assets (ETH, Cosmos/Terra/IBC, BTC, etc…).
Implementation should keep in mind that the framework will be extended to other chains/assets.

## Reference-level explanation

### Proposing a new asset

The addition of a new asset is achieved using the on-chain governance system. This requires a [governance proposal](./0028-GOVE-governance.md#new-asset-proposals) type for addition of a new asset to the network's set of supported assets.

This proposal can be initiated by anyone with a sufficient number of vega tokens.

On top of the standard voting procedure for other governance proposals, network validators also have a vote. The asset's validity (see [asset framework](./0040-ASSF-asset_framework.md)) is verified against the origin blockchain, which allows the vega network to obtain information about the asset (e.g: ticker symbol, name, decimal place, etc).
If the asset is accepted by the node, the node will then send it's own vote as a transaction to the chain, so the other validators can keep track of whom is accepting the new asset.

When exactly the nodes must have approved or not signalled approval of the asset is controlled in the proposal by `validationTimestamp`. This gives proposers the flexibility to propose assets before they exist on an external chain before they are deployed - but for most cases, the validation period should be set early on in the proposal lifecycle. Users can vote on proposals before the chain has validated the asset.

### Validating an asset

As detailed above, the validators will check the validity of the details supplied by the asset proposer. The validation occurs before the `validationTimestamp` provided in the `ProposalTerms`. The following checks should be applied:

### ERC20 assets

- The contract address provided must point to an ERC20 asset on the [bridged Ethereum network](./0031-ETHB-ethereum_bridge_spec.md)
- The contract must not already have an existing asset accepted on the Vega network (note: another _proposal_ could exist for the same asset)
- The name must strictly match the name in the ERC20 contract (e.g. `Wrapped ether`)
- The symbol must strictly match the symbol (e.g. `WETH`)

## Enabling a new asset on the bridge

Once the proposal is accepted, validators will produce a bundle (e.g. transaction plus signature/s) for submission to the asset's originating blockchain. Vega nodes will make this bundle available via an API.

- In the case of Ethereum/EVM ERC20 tokens, this bundle will be an Ethereum transaction to whitelist the asset on the [bridge](./0031-ETHB-ethereum_bridge_spec.md) via [multisig control](./0030-ETHM-multisig_control_spec.md), and a set of signatures to authenticate the transaction with multisig control.

## Enabling a new asset on vega

Once the asset has been allowlisted on the originating chain, deposits in this asset will be accepted to the bridge.
The bridge contract e.g. [Ethereum bridge](./0031-ETHB-ethereum_bridge_spec.md) must emit an event (on the bridged chain).
Vega chain will be notified of this event (new asset allowlisted on the bridge contract) via the [event queue](./0036-BRIE-event_queue.md).

Once this has happened, the new asset is ready to be used in the vega network.

## Modifying an existing asset

If an asset modification that went through [governance](./0028-GOVE-governance.md) is enacted then there are Vega chain part and bridged chain part.

### Bridged chain part

If it changes one of: `maximumLifetimeDeposit` and `withdrawalDelayThreshold` then a signed payload for the appropriate bridge is emitted.
Anyone willing to pay the transaction fee (gas) can submit this to the bridge contract via multisig control and cause the changes to be appropriately reflected there.
Vega will then update it's internal asset definition once the events are emitted and confirmed the correct number of times by the bridge chain.

**Note on asset bundles produced but not submitted to the bridge.** If an asset update `A` is produced and never submitted to bridged chain bridge contract and subsequently an asset update `B` is produced then out of order use is a possibility (someone can submit `A` after `B` has been submitted).
The onus is on the creator of proposal `B` to submit (and pay the gas for) for proposal `A` before their proposal `B`. (this means that `A` cannot be submitted again).

### Vega chain part

If it changes `quantum` then this new value becomes used immediately on enactment.

**Note on `decimals`.**

- Only non-negative integer values are allowed to specify number of asset decimal places.
- The Vega ERC20 bridge does not support assets with a changing number of decimals, and is unlikely ever to support such assets (due to both the added complexity and the lack of demonstrable use cases for this).
Therefore, it is undefined how to proceed in the event that decimals does change, and the specific, immutable instance of the token smart contract on the Ethereum blockchain must be verified by community members when voting on each new asset that is proposed to ensure that the number of decimals used by the asset is guaranteed to be perpetually invariant for the lifetime of the asset.
Contracts that do not meet this guarantee are not suitable as a basis for Vega bridge assets.

## Pseudo-code / Examples

### Changes to the voting

```proto

message ERC20 {
	// contract address of an ERC20 token
	string contractAddress = 1;
	string maximumLifetimeDeposit = 2; // note that e.g: 100000 in here will be interpreted against the asset decimals
    string withdrawalDelayThreshold = 3;  // this is will be interpreted against the asset decimals
}

message AssetSource {
  string symbol = 1;
  // an minimal amount of stake to be committed
  // by liquidity providers.
  // use the number of decimals defined by the asset.
  string quantum = 2; // note that e.g: 1000000000000000000 in here will be interpreted against the asset decimals
  uint64 decimals = 3;
  string name = 4;

  oneof source {
	// vega internal assets
	BuiltinAsset builtinAsset = 100;
	// foreign chains assets
	ERC20 erc20 = 200;
  }

}

message NewAsset {
  AssetSource changes = 1 [(validator.field) = {msg_exists: true}];
}

message ERC20Update {
    string maximumLifetimeDeposit = 2; // note that e.g: 100000 in here will be interpreted against the asset decimals
    string withdrawalDelayThreshold = 3;  // this is will be interpreted against the asset decimals
}

message UpdateAssetSource {
  string symbol = 1;
  // an minimal amount of stake to be committed
  // by liquidity providers.
  // use the number of decimals defined by the asset.
  string quantum = 2; // note that e.g: 1000000000000000000 in here will be interpreted against the asset decimals
  uint64 decimals = 3;
  string name = 4;

  oneof source {
     ERC20Update erc20 = 100;
  }
}

message UpdateAsset {
  string asset_id = 1;
  UpdateAssetSource changes = 2;
}

message ProposalTerms {
  int64 closingTimestamp       = 1 [(validator.field) = {int_gt: 0}];
  int64 enactmentTimestamp     = 2 [(validator.field) = {int_gt: 0}];
  int64 validationTimestamp     = 3 [(validator.field) = {int_gt: 0}];
  uint64 minParticipationStake = 4 [(validator.field) = {int_gt: 0}];
  oneof change {
    UpdateMarket  updateMarket  = 101;
    NewMarket     newMarket     = 102;
    UpdateNetwork updateNetwork = 103;
	// new field:
	NewAsset = newAsset = 104;
	UpdateAsset = updateAsset = 105;
};
}
```

### An ERC20 example

```json
{
	"newAsset": {
		"changes": {
			"contractAddress": "0xsomething"
		},
		"quantum": "10000000" // if the asset supports 5 decimals = 100.00000
	}
}
```

Note that the `quantum` (compulsory field) sets the minimum economically meaningful amount in the asset.
For example for USD this may be 1 USD or perhaps 0.01 USD.
This must be an integer strictly greater than `0`.

## Acceptance Criteria

### User actions

- As a user I can submit a new proposal asset to be used in vega (<a name="0027-ASSP-001" href="#0027-ASSP-001">0027-ASSP-001</a>)
- As a user I can vote for an asset proposal. (<a name="0027-ASSP-002" href="#0027-ASSP-002">0027-ASSP-002</a>)
- As a user, original submitter of the asset, I can call the node to get a signature of the asset, so I can send it to the asset bridge, and whitelist the asset. (<a name="0027-ASSP-003" href="#0027-ASSP-003">0027-ASSP-003</a>)
- `quantum` is a required parameter  (<a name="0027-ASSP-004" href="#0027-ASSP-004">0027-ASSP-004</a>)

### Node actions

- As a node, when a new asset proposal is emitted, I can validate the asset with it's chain, and send the result of the validation through the chain to the other nodes (first phase proposal) (<a name="0027-ASSP-005" href="#0027-ASSP-005">0027-ASSP-005</a>)
- As a node, when a new asset is accepted through governance, I can sign a payload to the user so they can whitelist the asset with the bridge (<a name="0027-ASSP-006" href="#0027-ASSP-006">0027-ASSP-006</a>)
- As a node, I receive events from the external blockchain queue, that confirm the asset is enabled in the bridge. (<a name="0027-ASSP-007" href="#0027-ASSP-007">0027-ASSP-007</a>)
- As a node, when an existing asset is modified through governance changing any one of `maximumLifetimeDeposit` or `withdrawalDelayThreshold`, emit a signed a payload to the world so that they can update the corresponding parameters on the bridge (<a name="0027-ASSP-008" href="#0027-ASSP-008">0027-ASSP-008</a>)

### Validation

#### ERC20 Validation

- A valid contract address, which exists in ethereum and is specified in the ERC20 proposal **must** be validated as conforming as an ERC20 asset(<a name="0027-ASSP-009" href="#0027-ASSP-009">0027-ASSP-009</a>)
- An ERC20 proposal **must** provide a name and that name **must** exactly equal the name of the ERC20 token on the target chain (<a name="0027-ASSP-010" href="#0027-ASSP-010">0027-ASSP-010</a>)
- An ERC20 proposal **must** provide a code and that code **must** exactly equal the code of the ERC20 token on the target chain (<a name="0027-ASSP-011" href="#0027-ASSP-011">0027-ASSP-011</a>)
- An ERC20 proposal **must** provide a decimal places property and that property **must** exactly equal the decimal places property of the ERC20 token on the target chain (<a name="0027-ASSP-012" href="#0027-ASSP-012">0027-ASSP-012</a>)
- If the contract name or code do not match, or the contract does not exist, or is not an ERC20 contract, the proposal must be rejected and the rejection reason and error details fields should indicate which rule failed (<a name="0027-ASSP-013" href="#0027-ASSP-013">0027-ASSP-013</a>)
- This validation occurs according to the `validationTimestamp` field in the proposal (<a name="0027-ASSP-014" href="#0027-ASSP-014">0027-ASSP-014</a>)
- A new ERC20 proposal that passes node validation but is does not pass normal governance rules is rejected  (<a name="0027-ASSP-015" href="#0027-ASSP-015">0027-ASSP-015</a>)
- A new ERC20 proposal that passes normal governance rules but fails node validation is rejected (<a name="0027-ASSP-016" href="#0027-ASSP-016">0027-ASSP-016</a>)
- `validationTimestamp` must occur after the governance proposal opens voting, and before it closes (<a name="0027-ASSP-017" href="#0027-ASSP-017">0027-ASSP-017</a>)
- `validationTimestamp` must be provided and in the future for all new ERC20 asset proposals (<a name="0027-ASSP-018" href="#0027-ASSP-018">0027-ASSP-018</a>)
- `quantum` must be an integer strictly greater than `0` (<a name="0027-ASSP-019" href="#0027-ASSP-019">0027-ASSP-019</a>)
- If there is a proposal for some ERC20 asset already present then another proposal for the same ERC20 asset will be rejected. (<a name="0027-ASSP-020" href="#0027-ASSP-020">0027-ASSP-020</a>)
- There can be multiple concurrent proposals for the same new ERC20 asset (same means identical Ethereum address). Once the nodes agree (based on events from the external blockchain queue), that the asset is enabled on the bridge all the remaining proposals for the same asset are rejected.
(<a name="0027-COSMICELEVATOR-025" href="#0027-COSMICELEVATOR-025">0027-COSMICELEVATOR-025</a>)
- An invalid contract address, specified in the ERC20 proposal **must** be rejected(<a name="0027-ASSP-021" href="#0027-ASSP-021">0027-ASSP-021</a>)
- An valid contract address which cannot be found in ethereum, specified in the ERC20 proposal **must** be rejected(<a name="0027-ASSP-022" href="#0027-ASSP-022">0027-ASSP-022</a>)

### Delays and Thresholds

- There is an asset `X` on vega / bridge with withdrawal delay threshold `t1`. Withdrawal in asset `X` below `t1` has no delay i.e. can be finalised on Ethereum as soon as the withdrawal bundle is received. A withdrawal in asset `X` with amount greater than or equal to `t1` will be rejected by the bridge before time `bundle creation + delay` but can be finalised after `delay` time passes from bundle creation. Here `delay` is the global bridge delay parameter. (<a name="0027-ASSP-023" href="#0027-ASSP-023">0027-ASSP-023</a>)
- There is an asset `X` on vega / bridge with withdrawal delay threshold `t1`. An asset update proposal is submitted to change these to `t2`; it passes voting and is submitted to Ethereum bridge contract. The new thresholds now apply i.e. withdrawal in asset `X` below `t2` has no delay i.e. can be finalised on Ethereum as soon as the withdrawal bundle is received. A withdrawal in asset `X` with amount greater than or equal to `t2` will be rejected by the bridge before time `bundle creation + delay` but can be finalised after `delay` time passes from bundle creation. Here `delay` is the global bridge delay parameter. (<a name="0027-ASSP-024" href="#0027-ASSP-024">0027-ASSP-024</a>)
