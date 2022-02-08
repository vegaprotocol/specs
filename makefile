all: names codes references

# Check that all the specifications are named appropriately
names:
	node scripts/check-filenames.js

# Count how many Acceptance Criteria each specification has
codes:
	node scripts/check-codes.js 	

# Which Acceptance Criteria are referenced in which feature files?
references:
	node scripts/check-references.js 	

# Imperfect, but useful - hence not included in ALL
links:
	npx markdown-link-check protocol/*.md
	npx markdown-link-check non-protocol-specs/*.md
