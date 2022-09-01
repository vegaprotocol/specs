# Vega specs
This repository contains specifications and RFCs for future changes to the system. The process for writing, reviewing
and merging specs is in [WORKFLOW.md](./WORKFLOW.md).

## [Protocol](./protocol/)
This folder contains the protocol specifications. The goal of this folder is to specify how anyone could write an
implementation of Vega that is compatible with [vegaprotocol/vega](https://github.com/vegaprotocol/vega). 

### Protocol spec IDs
repository are assigned a numerical ID based on merge order, and then a 4 letter code, which results in a unique identifier
for each specification (e.g. the first merged spec is [0001-MKTF](./protocol/0001-MKTF-market_framework.md). These codes 
are then used to assign a unique Acceptance Criteria ID to each Acceptance Criteria, which can be used to cross reference
detailed requirements to test implementations.

## [Non-protocol specs](./non-protocol-specs)
For peripheral things that need to be hashed out through pull requests, we have `non-protocol-specs`. An example of
where this could be useful is the design process for the Liquidity Bots, or the short-lived 'training wheels' for a
limited mainnet.

## [Glossaries](./glossaries/)
These are quick reference points for general terminology we use. Some of the specs are really dense with trading terms 
or blockchain specifics. If something comes up that you don't understand and have to look up, it's likely it will happen
to someone else - add it to the glossary so we have a shared reference point. The advantage of adding it here rather than
letting people go off and search on their own is that we can point out if a specific feature/term is applied differently
due to Vega's design.

## [User interface](./user-interface)
Acceptance criteria for user interfaces (aka Front ends, apps and websites) used to document user requirements.

# Test codes & coverage
Specifications should contain _Acceptance Criteria_ - testable scenarios that can be used to demonstrate that the feature is implemented as designed.
The criteria are then labelled with a code in the form `0000-CODE-000`, where the first two segments are the [unique identifier for the specification](#protocol-spec-ids) and the last segment is an integer for the criteria. Using [vegaprotocol/approbation](https://github.com/vegaprotocol/approbation) we produce a coverage matrix.

# Disclaimer 
Throughout the `specs` repo we are using terms which in other contexts will have other meanings for example implying certain legal rights. Remember this is a blockchain project; entirely code based. Just as mathematics borrows terms from the real world (like "open" / "closed" when discussing topological properties of sets) in mathematics a set can be both open and closed at the same time which will not happen to a door in the meat-space. So: things in the `specs` repo mean what their assigned meaning within the spec repo is. Nothing more. 

In particular we introduce a term `equity-like share`: please remember: this is a blockchain and is entirely code-based; there are no dividends and no legally enforceable rights; don't expect a pretty share certificate coming in the post.   