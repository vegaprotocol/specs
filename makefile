all: names codes references

# Check that all the specifications are named appropriately
names:
	npx @vegaprotocol/approbation check-filenames

# Count how many Acceptance Criteria each specification has
codes:
	npx @vegaprotocol/approbation check-codes

# Which Acceptance Criteria are referenced in which feature files?
references:
	npx @vegaprotocol/approbation check-references

# Imperfect, but useful - hence not included in ALL
links:
	npx markdown-link-check protocol/*.md
	npx markdown-link-check non-protocol-specs/*.md
