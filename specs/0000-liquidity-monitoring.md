Feature name: liquidity-monitoring
Start date: 2020-07-14
Specification PR: https://github.com/vegaprotocol/product/pull/322

# Acceptance Criteria

- [ ]
- [ ]
- [ ]

# Summary

WIP

# Guide-level explanation

## Measuring the liquidity

### Liquidity required

Lower bound on liquidity requirement measured as a constant multiple of Open Interest [Do we want to apply some smoothing e.g.: average or max open interest over a rolling window? If so do we want to apply some operation to the measure of liquidity supplied?]

### Liquidity supplied

Committed & supplied Siskas [What are these, do we want to count just the MM-posted liquidity or overall?]

## Trigger for entering an auction

When liquidity supplied < liquidity required

## Trigger for exiting the auction

When liquidity supplied > c * liquidity required,
where c is a constant greater than 1 (part of the market configuration), to reduce the chance of another auction getting triggered soon after.

## What happens during the auction?

[Is there any trading?]

# Reference-level explanation

# Test cases

