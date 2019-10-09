Feature name: feature-name
Start date: YYYY-MM-DD
Specification PR: https://gitlab.com/vega-protocol/product/merge_requests
Whitepaper link: [whitepaper](/vega-protocol/product/wikis/Whitepaper) sections: 3.2 and 5.2 


# Acceptance Criteria

- [ ] When an instrument expires the settlement instructions include correct expiry cashflows for each trader.
- [ ] The settlement instructions are used to "collect" funds from the traders who have a negative cashflow (assuming that negative cashflow means you owe money to the market / are "out of the money") and deposits all these collected funds into the market's general account.
  - [ ] When "collecting" funds from a trader account, the settlement engine must instruct the collateral engine to debit in this order (this order is true on expiry for all instruments):
    1. Margin account of the trader
    2. Market account for the trader
    3. Insurance pool for the market
- [ ] The settlement function interprets the collateral responses and determines whether the traders who are owed money may be paid out of the market's general account.
  - [ ] If there are sufficient funds to pay all traders who are owed money, the settlement engine instructs the collateral engine to pay them out according the above calculated cashflows.
  - [ ] If there are insufficient funds to pay all traders who are owed money, the settlement engine adjusts the amounts according to the position resolution methodology, which for Nicenet is a pro-rated reduction in amounts by the size of the amount.
- [ ] When an instrument expires, the sum of all the settlement cashflows nets to zero across all positions (assumes negative volumes for short positions).

- [ ] check it can't happen before maturity
- [ ] check it can't happen on invalid / other data from the oracle (i.e. a price with the wrong timestamp)
- [ ] check it happens with the first and only the first price that is valid per the oracle definition
- [ ] check mark price is updated
- [ ] check mark to market settlement happens correctly


## Implementation note / boundaries

- The settlement function does not keep a record of any collateral balances
- [ ] The settlement function does not maintain the settlement formula for cashflows to be calculated
- [ ] The settlement function does not actually execute the transfer of funds - it rather instructs the collateral engine to do this.

# Summary

Instruments on Vega may specify a maturity (expiry) date and time, after which open positions are settled and the market no longer operates.

If [mark to market settlement](0003-mark-to-market-settlement) has been undertaken, the final settlement cash flow will be the difference in position value since the most recently run [mark to market settlement](0003-mark-to-market-settlement).


# Guide-level explanation

## Expiry Trigger


# Reference-level explanation

## Cash settled with mark-to-market settlement

Starting at T = maturity, wait until the expiry price specified in the Instrument (see Market Framework and Built-in Product - Futures specs) definition is available (i.e. a valid expiry price for this instrument appears on the internal or external oracle feed). Note this only happens once no matter how many valid prices are printed.

Set the mark price = expiry price

Perform [mark to market settlement](0003-mark-to-market-settlement) 






Cash settlement at expiry when [mark to market settlement](0003-mark-to-market-settlement) has occurred follows the same steps as described in [mark to market settlement](0003-mark-to-market-settlement), with a slight tweak to the formula in step 1:

```product.value(current_price)``` uses for ```current_price``` the expiry price which is supplied by an oracle.

Otherwise, all other steps are the same.

# Pseudo-code / Examples

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

# Test cases

