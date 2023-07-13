# Network Treasury

The Network Treasury is a set of accounts (up to 1 per asset supported by the network via the asset framework) that are funded by parties, deposits, or by direct transfers (e.g. a portion of fees, or from insurance pools at market closure).
The purpose of the Network Treasury is to allow funding to be allocated to rewards, grants, etc. by token holder governance.

The funds in the network treasury are spent by being transferred to another account, either by direct governance action (i.e. voting on a specific proposed transfer) or by mechanisms controlled by governance, such as a periodic transfer, which may have network parameters that control the frequency of transfers, calculation of the amount, etc..
These transfers may be to a party general account, reward pool account, or insurance pool account for a market.
There is no requirement or expectation of symmetry between funds flowing into the Network Treasury and funds flowing out.
For example, the treasury account may be seeded by funds held by the team or investors, or through the issuance of tokens at various irregular points in time, and these funds may then be allocated to incentives/rewards, grants, etc. on a different schedule.

## Funding

Funding is how the on-chain treasury account receives collateral to be allocated later.

### Funding by transfer

A transfer may specify the network treasury as the destination of the transfer.
The funds, if available would be transferred instantly and irrevocably to the network treasury account for the asset in question (the treasury account for the asset will be created if it doesn’t exist).

- Transfer from protocol mechanics: there may be a protocol feature such as the charging of fees or handling of expired insurance pool balances that specifies the Network Treasury as destination in a transfer. (Charging of fees is placeholder, currently not to be implemented.)

- Transfer by governance: a [governance proposal](./0028-GOVE-governance.md) can be submitted to transfer funds from a market's insurance pool into the on chain treasury account for the asset.

- Transfer transaction: a transaction submitted to the network may request to transfer funds from the general account for an asset, controlled by the owner’s private key, to the Network Treasury. (see [transfers spec](./0057-TRAN-transfers.md))

### Funding by deposit

A deposit via a Vega bridge may directly specify the Network Treasury as the destination for the deposited funds. This is done by using `0` as the Vega party address.
The deposited funds would then appear in the Network Treasury account for the appropriate asset.

### Funding from fee revenue (future — placeholder)

In future a fee factor (controlled by governance) may be added to allow the treasury to be funded from a component of the trading fees on the network.

### Funding from inflation or tax (future — placeholder)

In future a tax rate and/or inflation rate (controlled by governance) may be used to allow funding the network treasury with governance tokens. This would either involve transferring a fraction of each staked user's tokens to the network treasury per epoch (it is implied that this fraction would be a significantly lower value than the other assets they receive in fees), or periodic issuance of new tokens into the treasury (this would not be possible before the inflation cut-off date in the token contract).

### Direct allocation by governance

A governance proposal may be submitted to transfer funds on enactment from the on-chain treasury to certain account types. Please see [the governance spec](./0028-GOVE-governance.md) for a description of this.

## Acceptance criteria

### 💧 Sweetwater

- Depositing funds via the [ERC-20 bridge](./0031-ETHB-ethereum_bridge_spec.md) directly to the Validators Rewards account (i.e. `xxx` address). There will be no more  on-chain-treasury on sweetwater. (<a name="0055-TREA-001" href="#0055-TREA-001">0055-TREA-001</a>)

### 🤠 Oregon Trail

- Depositing funds via the [ERC-20 bridge](./0031-ETHB-ethereum_bridge_spec.md) to the Network Treasury account (i.e. zero address) when there is no Network Treasury account for the asset being deposited:
  - Creates a Network Treasury account for that asset  (<a name="0055-TREA-002" href="#0055-TREA-002">0055-TREA-002</a>)
  - Results in the balance of the Network Treasury account for the asset being equal to the amount of the asset that was deposited (<a name="0055-TREA-003" href="#0055-TREA-003">0055-TREA-003</a>)
  - The Network Treasury accounts API includes the new account  (<a name="0055-TREA-004" href="#0055-TREA-004">0055-TREA-004</a>)
  - The Network Treasury accounts API returns the correct balance for the new account (<a name="0055-TREA-005" href="#0055-TREA-005">0055-TREA-005</a>)
- Depositing funds via the ERC-20 bridge to the Network Treasury account (i.e. zero address) when there is already a Network Treasury account for the asset being deposited:
  - Increments the balance of the Network Treasury account for the asset by the amount of the asset that was deposited (<a name="0055-TREA-006" href="#0055-TREA-006">0055-TREA-006</a>)
  - The Network Treasury accounts API returns the correct balance for the new account (<a name="0055-TREA-007" href="#0055-TREA-007">0055-TREA-007</a>)
- The network treasury account balances [are restored after a network restart](./0073-LIMN-limited_network_life.md)  (<a name="0055-TREA-010" href="#0055-TREA-010">0055-TREA-010</a>)

### Cosmic Elevator

- If a governance proposal for a single transfer from a network treasury account to some other account is enacted then
  - if the amount in the proposal greater than or equal amount in network treasury for the asset then the entire balance of the net treasury account is transferred to the destination account (party address). (<a name="0055-COSMICELEVATOR-050" href="#0055-COSMICELEVATOR-050">0055-COSMICELEVATOR-050</a>)
  - if the balance in the network treasury for the asset is greater than the amount specified in the transfer then the network treasury balance is decreased by the said amount and the destination account (party address) account is incremented by the right amount. (<a name="0055-COSMICELEVATOR-051" href="#0055-COSMICELEVATOR-051">0055-COSMICELEVATOR-051</a>)
- If a governance proposal for a single periodic transfer from a network treasury account to some other account is enacted then the transfers run as individual transfers as specified by the schedule / amounts until the schedule ends. (<a name="0055-COSMICELEVATOR-060" href="#0055-COSMICELEVATOR-060">0055-COSMICELEVATOR-060</a>)
