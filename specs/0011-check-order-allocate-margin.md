# Check Order Allocate Margin

# Outline

When an order or other market instruction (amend, cancel, etc.) is submitted we need to check if it changes the margin requirement for the trader who has submitted it, and if it increases them we need to allocate (request to allocate in a future, shared world) margin before accepting the order.

Orders should be rejected if we can’t allocate sufficient margin.


## Pseudocode

The logic is something like this:

```
enum ValidationResult = Accept | Reject

/* NB: a position record is assumed to contain all required data about a trader's open volume and active orders to calculate margin. For example, this means containing or being able calculate the 'net worst' long and short positions given all orders.
*/

/*** Ensure that it is reasonably likely (guaranteed, in a non-sharded 
		 environment) that there is sufficient allocated margin to execute 
		 a market instruction, or reject the instruction. */

fn allocate_instruction_margin(
		m: Market, 
		i: Instruction) -> ValidationResult {

	let current_pos = get_position(
			market: m, 
			party: i.sender)
	let new_pos = calculate_updated_position(
			current_pos, 
			instruction: i)
	
	// NB: this is oversimplified. In reality, margins are a list of 
	// assets + amounts, 1 per margin asset for the market. So the margin
	// logic is repeated at each step for each asset.
	let current_margin = margin_account_balance(
			party: i.sender, 
			market: m)
	let new_margin = calculate_adjusted_margin(
			current_pos,
			new_pos,
			current_margin)

	if new_margin.initial_margin > current_margin {
		let available = collateral_account_balance(
			party: i.sender, 
			asset: m.margin_asset)
		if available < new_margin.initial_margin - current_margin { 
			return ValidationResult.REJECT
		}		
		request_transfer(
				from: collateral_account_for(
						party: i.sender, 
						asset: m.margin_asset),
				to: margin_account_for(
						party: i.sender,
						market: m, 
						asset: m.margin_asset),
				amount: new_margin.initial_margin - current_margin)
	}
	
	return ValidationResult.ACCEPT
}
```
