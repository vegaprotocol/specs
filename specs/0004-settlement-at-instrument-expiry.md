Parent Issue: #81 
Whitepaper link: [whitepaper](/vega-protocol/product/wikis/Whitepaper) sections: 3.2 and 5.2 


The settlement engine's job is to convert settlement instructions into specific ledger entry instructions for the collateral engine. 

## Acceptance Criteria

- [ ] When an instrument expires the settlement engine calculates the correct expiry cashflows for each trader.
- [ ] The settlement engine informs the collateral engine to "collect" funds from the traders who have a negative cashflow (assuming that negative cashflow means you owe money to the market / are "out of the money") and deposits all these collected funds into the market's general account.
  - [ ] When "collecting" funds from a trader account, the settlement engine must instruct the collateral engine to debit in this order (this order is true on expiry for all instruments):
    1. Margin account of the trader
    2. Market account for the trader
    3. Insurance pool for the market
- [ ] The settlement engine interprets the collateral engine's response and determines whether the traders who are owed money may be paid out of the market's general account.
  - [ ] If there are sufficient funds to pay all traders who are owed money, the settlement engine instructs the collateral engine to pay them out according the above calculated cashflows.
  - [ ] If there are insufficient funds to pay all traders who are owed money, the settlement engine adjusts the amounts according to the position resolution methodology, which for Nicenet is a pro-rated reduction in amounts by the size of the amount.


## Note / boundaries

- The settlement engine does not keep a record of any collateral balances
- [ ] The settlement engine does not maintain the settlement formula for cashflows to be calculated
- [ ] The settlement engine does not actually execute the transfer of funds - it rather instructs the collateral engine to do this.
- [ ] When an instrument expires, the sum of all the settlement cashflows nets to zero across all positions (assumes negative volumes for short positions).


## Expiry Trigger
Logic encapsulated in the [product](./0001-market-framework.md) will define that the market has generated settlement cashflows for settlement, and emit an event accordingly. (note also same for interim cashflows)

Logic encapsulated in the [product](./0001-market-framework.md) will define that the market has expired and that settlement cashflows may be generated for settlement. (note this is similar for interim cashflows)

How this logic occurs is out of the scope of this ticket. 

## Resulting Actions

1. The [product](./0001-market-framework.md) specifies the market-based settlement function which maybe be used by the settlement engine to calculate settlement instructions for each party.  This settlement function is paramaterised at expiry (this is outside the scope of this ticket) and is accessible by the settlement engine when this is completed.

```rust
// The product's definition contains the settlementByTrader function
enum Product {
	Future { maturity: String, oracle: Oracle, asset: String },

}
``` 

2. The settlement engine will evaluate each party's net cashflows according to the formula provided and utilising knowledge of a trader's net [open position](../wikis/Trading-and-Protocol-Glossary#open-position). 

```rust
// maybe something like
struct Position {
  ... <contains trades> ...
  size: uint,
  average_entry_price: uint
}

// implementation options below - not 100% sure of how this might go, former is maybe more amenable to optimisation but less neat in terms of types and data encapsulation
fn <product>.settle(entryPrice: uint, netPosition: uint) {  // OR could be...
fn <product>.settle(position: Position) {

  FinancialAmount {
    asset: this.settlement_asset,
    amount: <...>
  }
}
``` 

3. The settlement process has two phases.  In the first phase the settlement engine ***collects*** (by instructing the collateral engine - see parent ticket #81 ) funds from loss making positions and accesses the insurance pool if necessary where there is a shortfall in some parties' collateral accounts. In the second phase, the settlement engine ***distributes*** the collected funds including those collected from the insurance pool. Where there is a shortfall, the settlement engine calculates reduced amounts to be distributed to some participants according to the "Position resolution algorithm" (Section 5.3 Whitepaper).


When the Settlement Engine has received all "collect" responses from the collateral engine, it will ascertain whether the collateral engine was able to move all of the requested ("from") amounts to the destination ("to") account (market's pool account) - e.g. if the total funds now in the market's settlement account are equal to the required total payouts for the distribute phase or not.

If this is not the case, the settlement engine will need to alter the "distribute" amounts before sending them to the collateral engine. The amounts are altered using a formula which is out of scope for this ticket. As a stub implementation distribution can pro-rata the amount in the settlement account between positions by relative position size.

### Settlement Engine Example

*(see https://docs.google.com/spreadsheets/d/1PMTS8DUZ-s4881WCGMMlxVffOm5nRGUKWXEHqnmAC_c/edit#gid=79914074)*

Below is a futures market example. All the logic applies to whatever the instrument is.  The fact it's a future is seen by which settlement method is called.

```rust
Future { maturity: Date('31-Dec-2019'), oracle: Oracle1, asset: 'TUSD' } // 


fn Future.settle(entryPrice, netPosition) {
  FinancialAmount {
    asset: this.settlement_asset,
    amount: (this.oracle.settlementPrice - entryPrice) * netPosition // this is the real settlement method that will apply to all futures
  }
}

// if this.oracle.price = 4000, these settlement instructions are generated and sent to the collateral engine in two batches - first, the 'collect' instructions, then the 'distribute' instructions.

// the transfer request to collect funds is a list of transfer requests as accepted by the collateral manager's 'transfer' function
let transfer_request_collect_funds =
    [
        TransferRequest {
            from: [ 
                Account { party: Trader3MarginAccount, ... },  
                Account { party: Trader3AccountForThisMarket },
                Account { party: InsurancePoolForThisMarket }
            ],

            to: [
                Account { party: SettlementAccountForThisMarket }        
            ],

            amount:  
                FinancialAmount {
                    asset: this.settlement_asset,
                    amount: 400 // settlementFunction.settlementByParty(trader-3)  = eval(4000 * 2 + -1 * 4200 * 1) = -400
                },

            reference: "expiry-of-instrument-BTCUSDZ2019",  // or some way to link back to the causal event that created this transfer
            type: enum ,  // what type of transfer - types TBC, could leave this field out initially
            min_amount: 400
        },

        TransferRequest {
            from: [ 
                Account { party: Trader4MarginAccount, ... },  
                Account { party: Trader4AccountForThisMarket },
                Account { party: InsurancePoolForThisMarket }
            ],

            to: [
                Account { party: SettlementAccountForThisMarket }        
            ],

            amount:  
                FinancialAmount {
                    asset: this.settlement_asset,
                    amount: 900 // settlementFunction.settlementByParty(trader-4) = eval(4000 * 1 -1 * 4900 * 1 = -900,
                },

            reference: "expiry-of-instrument-BTCUSDZ2019",  // or some way to link back to the causal event that created this transfer
            type: enum ,  // what type of transfer - types TBC, could leave this field out initially
            min_amount: 900
        }

    ]


``` 


#### Collateral Engine Response - Scenario 1

```rust
TransferResponse {
  transfers: [
      
    LedgerEntry: {
        from: Trader3MarginAccount,
        to: SettlementAccountForThisMarket,
        amount: 300,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: Trader3AccountForThisMarket,
        to: SettlementAccountForThisMarket,
        amount: 100,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: Trader4MarginAccount,
        to: SettlementAccountForThisMarket,
        amount: 280,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: Trader4AccountForThisMarket,
        to: SettlementAccountForThisMarket,
        amount: 500,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: InsurancePoolForThisMarket,
        to: SettlementAccountForThisMarket,
        amount: 120,
        reference: String,
        type: String,
        timestamp: DateTime
    },
  ],

  balances: [
      { MarketAAccount: 1300 }
  ]
}
```

##### *Sent back to Collateral Engine by Settlement Engine*

```
TransferRequestDistributeFunds {
    [

       TransferRequest {
            from: [ 
                Account { party: SettlementAccountForThisMarket },  
            ],

            to: [
                Account { party: Trader1GeneralAccount }        
            ],

            amount:  
                FinancialAmount {
                    asset: this.settlement_asset,
                    amount: 500 // settlementFunction.settlementByParty(trader-1) = eval(4000 * 1 - 1 * 3500 * 1) = 500
                },

            reference: "expiry-of-instrument-BTCUSDZ2019",  // or some way to link back to the causal event that created this transfer
            type: enum ,  // what type of transfer - types TBC, could leave this field out initially
            min_amount: 500
        },

        TransferRequest {
            from: [ 
                Account { party: SettlementAccountForThisMarket },  
            ],

            to: [
                Account { party: Trader2GeneralAccount }        
            ],

            amount:  
                FinancialAmount {
                    asset: this.settlement_asset,
                    amount: 800 //settlementFunction.settlementByParty(trader-2) = eval(4000 * -4 - 1 * 4200 * -4) = 800,
                },

            reference: "expiry-of-instrument-BTCUSDZ2019",  // or some way to link back to the causal event that created this transfer
            type: enum ,  // what type of transfer - types TBC, could leave this field out initially
            min_amount: 800
        },
    ]
}


// Collateral engine will then respond again with LedgerEntry's and an update on the market's ledger balance. 

TransferResponse {
  transfers: [
      
    LedgerEntry: {
        from: SettlementAccountForThisMarket,
        to: Trader1GeneralAccount,
        amount: 500,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: SettlementAccountForThisMarket,
        to: Trader2GeneralAccount,
        amount: 800,
        reference: String,
        type: String,
        timestamp: DateTime
    },

  balances: [
      { MarketAAccount: 0 }
  ]
}


```

#### Collateral Engine Response - Scenario 2

```
TransferResponse {
  transfers: [
      
    LedgerEntry: {
        from: Trader3MarginAccount,
        to: SettlementAccountForThisMarket,
        amount: 300,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: Trader3AccountForThisMarket,
        to: SettlementAccountForThisMarket,
        amount: 100,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: Trader4MarginAccount,
        to: SettlementAccountForThisMarket,
        amount: 280,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: Trader4AccountForThisMarket,
        to: SettlementAccountForThisMarket,
        amount: 500,
        reference: String,
        type: String,
        timestamp: DateTime
    },

    LedgerEntry: {
        from: InsurancePoolForThisMarket,
        to: SettlementAccountForThisMarket,
        amount: 20,
        reference: String,
        type: String,
        timestamp: DateTime
    },
  ],

  balances: [
      { MarketAAccount: 1200 }
  ]
}
```

##### *Sent back to Collateral Engine by Settlement Engine*
*Note, this scenario has applied position resolution to the instructions that it sends back.*

```rust

// the transfer request to distribute funds is a list of transfer requests as accepted by the collateral manager's 'transfer' function
let transfer_request_distribute_funds =
    [

       TransferRequest {
            from: [ 
                Account { party: SettlementAccountForThisMarket },  
            ],

            to: [
                Account { party: Trader1GeneralAccount }        
            ],

            amount:  
                FinancialAmount {
                    asset: this.settlement_asset,
                    amount: 461.53  // Applying "stub" of position resolution: 500/(500+800)*1200
                },

            reference: "expiry-of-instrument-BTCUSDZ2019",  // or some way to link back to the causal event that created this transfer
            type: enum ,  // what type of transfer - types TBC, could leave this field out initially
            min_amount: 461.53
        },

        TransferRequest {
            from: [ 
                Account { party: SettlementAccountForThisMarket },  
            ],

            to: [
                Account { party: Trader2GeneralAccount }        
            ],

            amount:  
                FinancialAmount {
                    asset: this.settlement_asset,
                    amount: 738.46 // Applying "stub" of position resolution: 800/(500+800)*1200
                },

            reference: "expiry-of-instrument-BTCUSDZ2019",  // or some way to link back to the causal event that created this transfer
            type: enum ,  // what type of transfer - types TBC, could leave this field out initially
            min_amount: 738.46 
        },
    ]
```
