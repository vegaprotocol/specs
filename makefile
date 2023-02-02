# Set default to run all checks if none specified
.DEFAULT_GOAL := all

all: spellcheck markdownlint names codes references links clean

# Check that all the specifications are named appropriately
.PHONY: names
names:
	@$(MAKE) clone-sources
	npx @vegaprotocol/approbation check-filenames

# Count how many Acceptance Criteria each specification has
.PHONY: codes
codes:
	@$(MAKE) clone-sources
	npx @vegaprotocol/approbation check-codes

TEMP=./.build
.PHONY:clone-sources
clone-sources:
	@mkdir -p $(TEMP)

	@echo "Cloning/updating test repos..."
	@echo "==============================="
	@echo ""
	@cd $(TEMP); \
	echo "- MultisigControl"; \
	git -C MultisigControl pull || git clone https://github.com/vegaprotocol/MultisigControl.git; \
	echo "- Vega"; \
	git -C vega pull || git clone https://github.com/vegaprotocol/vega.git; \
	echo "- Vega_token_v2"; \
	git -C vega_token_v2 pull || git clone https://github.com/vegaprotocol/vega_token_v2.git; \
	echo "- staking_bridge"; \
	git -C staking_bridge pull || git clone https://github.com/vegaprotocol/staking_bridge.git; \
	echo "- system-tests"; \
	git -C system-tests pull || git clone https://github.com/vegaprotocol/system-tests.git
	@echo ""
	@echo "==============================="
	@echo ""

# Which Acceptance Criteria are referenced in which feature files?
# Runs make clone-sources in a shell so that it properly waits for them to run in parallel and finish
.PHONY: references
references:
	@$(MAKE) clone-sources

	cd $(TEMP); npx -y @vegaprotocol/approbation@latest check-references --specs="../*protocol*/*.{md,ipynb}" --tests="./**/*.{js,py,feature}" --categories="../protocol/categories.json" --show-branches --show-mystery --verbose --show-files

# Imperfect, but useful - hence not included in ALL
.PHONY: links
links:
	npx --yes markdown-link-check --config .github/workflows/config/markdownlinkcheckignore.json ./*protocol*/*.md

# check the markdown formatting (/protocol specs only at this time)
.PHONY: markdownlint
markdownlint:
	@./markdownlint.sh

# check the markdown spelling (/protocol specs only at this time)
.PHONY: spellcheck
spellcheck:
	@./spellcheck.sh

clean:
	rm -rf $(TEMP)
