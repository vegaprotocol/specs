Feature: Test settlement at expiry for built-in futures

# Scenario: A market with an expired product should have a status of `TRADING_TERMINATED`.
# Scenario: A `TRADING_TERMINATED` market should settle all accounts when a valid, matching oracle event occurs
# Scenario: A `TRADING_TERMINATED` market should move to `SETTLED` after settlement is complete
# Scenario: A valid, matching oracle event should not change the status of a market with any status other than `TRADING_TERMINATED`
# Scenario: The balance of a `TRADING_TERMINATED` market's insurance balance should move to the on chain treasury. 
# Scenario: The correct balances end up with the correct people at settlement
