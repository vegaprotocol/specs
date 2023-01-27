# Set default to run all checks if none specified
.DEFAULT_GOAL := all

all: spellcheck markdownlint names codes links references

# Check that all the specifications are named appropriately
.PHONY: names
names:
	npx @vegaprotocol/approbation check-filenames

# Count how many Acceptance Criteria each specification has
.PHONY: codes
codes:
	npx @vegaprotocol/approbation check-codes

# Which Acceptance Criteria are referenced in which feature files?
.PHONY: references
references:
	npx @vegaprotocol/approbation check-references

# Imperfect, but useful - hence not included in ALL
.PHONY: links
links:
	npx --yes markdown-link-check protocol/*.md
	npx --yes markdown-link-check non-protocol-specs/*.md

# check the markdown formatting (/protocol specs only at this time)
.PHONY: markdownlint
markdownlint:
	@./markdownlint.sh

# check the markdown spelling (/protocol specs only at this time)
.PHONY: spellcheck
spellcheck:
	@./spellcheck.sh
