# Summary
As a user with a Vega client side application, in order to start interacting with the nework I need to be able to fetch a URL for a data node

This spec adds a single network parameter that allows us to leverage our existing Governance system to have a network-wide agreed upon IPFS hash for 

# Guide-level explanation
However, IPFS doesn't solve everything. Most browsers and platforms can't natively resolve an IPFS hash and grab the content behind it. However:
- Some forward looking browsers like Brave are building in IPFS support
- Other browsers have extensions
- There are publicly accessible gateways

This makes IPFS a reasonable place to put the list of data nodes. It does have the classic bootstrapping problem - if you don't know a data node to get the IPFS hash from, how do you get the list of data nodes? This is a solvable problem that isn't yet solved. Our first limited mainnet will have a set of known validators, any of whom could choose to provide a static, web-accessible link that will resolve the IPFS content.

# Reference-level explanation
This is broken down by requirements for an initial, known-validator set and slightly beyond. This does not solve for a completely fluid validator set.

## Restricted mainnet
A new network parameter is added that contains an IPFS hash.

The hash that is set in the genesis file is the hash of a file that has been hand-coded by one of the validators in the initial genesis set of validators.

The file contains a set of URLS for data nodes, as a JSON array. For example, our current testnet data node list would look like:

```
[
  "https://n01.testnet.vega.xyz",
  "https://n02.testnet.vega.xyz",
]
```

### Updating the restricted mainnet data node list
The process for changing this list are:
- Make a new file containing the updated list of validators
- Pin the file to IPFS
- Submit a governance proposal to update `data-node-list-hash` with the new list hash
- It is then up to users to verify the list and approve or vote down the proposal 

## Client usage
Now that there is a list of data nodes agreed on by the network, we have an established, provably approved list of data nodes that the Console, token front end or Go wallet could use. The only problem for them is getting hold of it, as currently none of them have IPFS libraries built in.

### Short term
Initially, we can hardcode the same hash as the genesis file `data-node-list-hash` in to any client, and use the IPFS.io public gateway.

### Long term
An IPNS can be provided that always points to the IPFS hash of the current network's `data-node-list-hash`.

# Network parameters

- `data-node-list-hash` - A string containing an IPFS hash.

# Acceptance criteria

## Basic
- There is a new network parameter that contains a string.
	- That string should look like an IPFS hash
	- It does not need to be verified as a valid IPFS hash
	- It does not need to be verified as an available IPFS hash
	- The contents of the IPFS hash does not need to be verified as a valid address list 
- The genesis file of every network contains an IPFS hash of a JSON file that contains data node addresses
  - That file is valid JSON
  - That file contains 1 or more data nodes that are assumed to be available 
