# Check Order Allocate Margin

## Outline

When an order or other market instruction (amend, cancel, etc.) is submitted we need to check if it changes the margin requirement for the trader who has submitted it, and if it increases them we need to allocate (request to allocate in a future, shared world) margin before accepting the order.

Orders should be rejected if we can’t allocate sufficient margin.

## Acceptance criteria

1. If an order is amended such that margin requirement is increased and user has sufficient balance in the general account to top up their margin account then the amendment is executed successfully. (<a name="0011-MARA-001" href="#0011-MARA-001">0011-MARA-001</a>)
1. In Spot market, if an order is amended such that holding requirement is increased and user has sufficient balance in the general account to top up their holding account then the amendment is executed successfully. (<a name="0011-MARA-018" href="#0011-MARA-018">0011-MARA-018</a>)
1. If an order is amended such that margin requirement is increased and user doesn't have sufficient balance in the general account to top up their margin account then their amend is not executed but the unamended order stays on the book. (<a name="0011-MARA-002" href="#0011-MARA-002">0011-MARA-002</a>)
1. In Spot market, if an order is amended such that holding requirement is increased and user doesn't have sufficient balance in the general account to top up their holding account then their amend is not executed but the unamended order stays on the book. (<a name="0011-MARA-019" href="#0011-MARA-019">0011-MARA-019</a>)
1. Cancelling an order releases the margin amount back to user's general account, provided the user has no other orders or positions (<a name="0011-MARA-003" href="#0011-MARA-003">0011-MARA-003</a>)
In Spot market, cancelling an order releases the holding amount back to user's general account. (<a name="0011-MARA-020" href="#0011-MARA-020">0011-MARA-020</a>)
1. If an order is amended such that margin requirement is decreased then the amendment is executed successfully. (<a name="0011-MARA-004" href="#0011-MARA-004">0011-MARA-004</a>)
1. If an order is partially filled then the margin requirements are recalculated reflecting the reduced order size and new position size. (<a name="0011-MARA-005" href="#0011-MARA-005">0011-MARA-005</a>)
In Spot market, if an order is partially filled then the holding requirements are recalculated reflecting the reduced order size. (<a name="0011-MARA-021" href="#0011-MARA-021">0011-MARA-021</a>)
1. If an order is partially filled and if this leads to a reduced position and reduced riskiest long / short then the margin requirements are seen to be reduced and if margin balance is above release level then the excess amount is transferred to the general account. (<a name="0011-MARA-006" href="#0011-MARA-006">0011-MARA-006</a>)
1. Margin is correctly calculated for [all order types](./0014-ORDT-order_types.md) in continuous trading:
    1. Limit GTT (<a name="0011-MARA-007" href="#0011-MARA-007">0011-MARA-007</a>)
    1. Limit GTC (<a name="0011-MARA-008" href="#0011-MARA-008">0011-MARA-008</a>)
    1. Limit GFN (<a name="0011-MARA-009" href="#0011-MARA-009">0011-MARA-009</a>)
    1. Pegged GTT (<a name="0011-MARA-010" href="#0011-MARA-010">0011-MARA-010</a>)
    1. Pegged GTC (<a name="0011-MARA-011" href="#0011-MARA-011">0011-MARA-011</a>)
    1. Pegged GFN (<a name="0011-MARA-012" href="#0011-MARA-012">0011-MARA-012</a>)
1. Margin is correctly calculated for [all order types](./0014-ORDT-order_types.md) in auction mode:
    1.Limit GTT (<a name="0011-MARA-013" href="#0011-MARA-013">0011-MARA-013</a>)
    1.Limit GTC (<a name="0011-MARA-014" href="#0011-MARA-014">0011-MARA-014</a>)
    1.Limit GFA (<a name="0011-MARA-015" href="#0011-MARA-015">0011-MARA-015</a>)
    1.Pegged GTT (parked in auction \*) (<a name="0011-MARA-016" href="#0011-MARA-016">0011-MARA-016</a>)
    1.Pegged GTC (parked in auction \* ) (<a name="0011-MARA-017" href="#0011-MARA-017">0011-MARA-017</a>)
1. In Spot market, holding in holding account is correctly calculated for [all order types](./0014-ORDT-order_types.md) in continuous trading:
    1. Limit GTT (<a name="0011-MARA-022" href="#0011-MARA-022">0011-MARA-022</a>)
    1. Limit GTC (<a name="0011-MARA-023" href="#0011-MARA-023">0011-MARA-023</a>)
    1. Limit GFN (<a name="0011-MARA-024" href="#0011-MARA-024">0011-MARA-024</a>)
    1. Pegged GTT (<a name="0011-MARA-025" href="#0011-MARA-025">0011-MARA-025</a>)
    1. Pegged GTC (<a name="0011-MARA-026" href="#0011-MARA-026">0011-MARA-026</a>)
    1. Pegged GFN (<a name="0011-MARA-027" href="#0011-MARA-027">0011-MARA-027</a>)
1. In Spot market, holding in holding account is correctly calculated for [all order types](./0014-ORDT-order_types.md) in auction mode:
    1.Limit GTT (<a name="0011-MARA-028" href="#0011-MARA-028">0011-MARA-028</a>)
    1.Limit GTC (<a name="0011-MARA-029" href="#0011-MARA-029">0011-MARA-029</a>)
    1.Limit GFA (<a name="0011-MARA-030" href="#0011-MARA-030">0011-MARA-030</a>)
    1.Pegged GTT (parked in auction \*) (<a name="0011-MARA-031" href="#0011-MARA-031">0011-MARA-031</a>)
    1.Pegged GTC (parked in auction \* ) (<a name="0011-MARA-032" href="#0011-MARA-032">0011-MARA-032</a>)

## Pseudocode

The logic is something like this:

```go
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
