# Vega specs
This repository contains specifications and RFCs for future changes to the system. The process for writing, reviewing
and merging specs is in [WORKFLOW.md](./WORKFLOW.md).

## [Protocol](./protocol/)
This folder contains the protocol specifications. The goal of this folder is to specify how anyone could write an
implementation of Vega that is compatible with [vegaprotocol/vega](https://github.com/vegaprotocol/vega).

## [Non-protocol specs](./non-protocol-specs)
For peripheral things that need to be hashed out through pull requests, we have `non-protocol-specs`. An example of
where this could be useful is the design process for the Liquidity Bots, or the short-lived 'training wheels' for a
limited mainnet.

## [Releases](./releases/)
The canonical source for what features are going in to which release. Progress on these releases is tracked on 
[🎱 Release Board](https://github.com/orgs/vegaprotocol/projects/12).

## [Glossaries](./glossaries/)
These are quick reference points for general terminology we use. Some of the specs are really dense with trading terms 
or blockchain specifics. If something comes up that you don't understand and have to look up, it's likely it will happen
to someone else - add it to the glossary so we have a shared reference point. The advantage of adding it here rather than
letting people go off and search on their own is that we can point out if a specific feature/term is applied differently
due to Vega's design.