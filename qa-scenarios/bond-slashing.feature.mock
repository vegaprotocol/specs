Feature: Test liquidity provider bond slashing 

# Spec file: ../specs-internal/protocol/0044-lp-mechanics.md

# Test structure	
# Set up a BTCUSD direct futures market	
# LP1 has 1500 USD collateral	
# LP1 commits 1000 USD with some shape	
# Check this is in their bond account	
# Margin for LP1 costs xxx (assume < 500)	
# Empty their general account somehow (use or withdraw)	

# Should get slashed correctly (check bond penalty param) if …		
# 	they don't have a position and they can't maintain their margin for orders	
# how to test?
#     Empty their general account somehow (use or withdraw) then architect a price move up so that their mark to market and margin requirements increase

# Should get slashed correctly (check bond penalty param) if …		
    # they have a position and market moves against them enough	
# how to test?
    # Open a big enough position and make a big enough move

# Should not get slashed if …	
# 	all other things being equal they increase their margin requirement by submitting an amend on the shape

# If they have previously been slashed	
# 	If there is a MTM move in their favour, bond account is topped up first