# Specifications

A specification outlines **our best understanding at the moment of how the software should be built**. We want it to be as complete as possible so that when developers are reading a specification they can understand the complete context and future intentions of a component, even if the first developed version is an MVP.

- If a component is being built as a stand-in for a proper implementation, then the MVP should be written as a specification file.

While we are producing the detailed specifications for the Vega trading core, the RFC process (see Notes) would be too heavyweight, so we're starting off by directly editing specifications. When the core specifications are more stable, we will adopt the RFC process.

## Pre-specification analysis

Some specification tasks will first require an analysis phase to investigate alternative ways of specifying the feature. Very early research and development of a feature will happen in the [research repo](https://github.com/vegaprotocol/research) and this will be reflected in a published paper in that repo.  The analysis  tickets in the product repo are to initiate and capture any discussion required before proceeding on to writing up the specification file. Analysis tasks should be created when required and all subject matter experts, relevant solution architects and engineers should be notified in the discussion.

Analysis tasks should be prioritised by those taking the lead on specifying the relevant feature. They may also be prioritised as a result of the engineering OKR goals, coordinated across the team.

## The process for a new component

1. Create a ticket in the [spec-writing board](https://github.com/orgs/vegaprotocol/projects/78).
1. When you are ready to commence the spec writing task, move the ticket to a status of _workflow::task-in-progress_.
1. Create a merge request _from the ticket_ - this will ensure they are linked and the ticket is automatically closed when merged.
1. Copy `0000-template.md` to `specs/0000-my-feature.md`, (e.g. `specs/0000-example-manager.md`.
1. Fill in the details, including the acceptance criteria.
1. Submit a merge request to start soliciting feedback. Ensure that the appropriate team members are notified.
1. Build consensus and integrate feedback.
1. Assign a sequence number and make up a 4 letter code for your feature, (e.g. `specs/0001-EXMP-example-manager.md`)
1. Merge to master - this will automatically close the associated ticket.

## The process for changes to existing component

1. Create an ticket in the [spec-writing board](https://github.com/orgs/vegaprotocol/projects/78). Label this appropriately, including whether it is a _spec-bug_ or _blocking-code_ and assign to a milestone and individual if appropriate. _Only use the already created labels_ (see below for the defined list and raise a merge request against this file if you want to edit these).
1. This ticket will be prioritised by the person it is assigned to, in collaboration with the engineering team.
1. When you are ready to commence the spec writing task, move the ticket to a status of _workflow::task-in-progress_.
1. Create a merge request from this ticket with a brief description of the changes you need to make.
1. Using the automatically created branch, start editing the document. Make sure to edit acceptance criteria if appropriate.
1. Build consensus and integrate feedback.
1. Merge to master - this will automatically close the associated ticket.

## The specification lifecycle

- When a specification is merged to a [milestone branch](README.md#specification-branches), it is ready for development and if this requires any engineering implementation, a new _implement_ ticket must be created in the [implement board](https://github.com/orgs/vegaprotocol/projects/42). The person responsible for creating this ticket is the person who has taken the lead on the specification task. See below for further information on implementation lifecycle.
- Scoping of specifications to milestones will be done in both _spec-design_ and _implement_ tickets rather than in the specification files.
- When a specification is merged into the `master` branch it details the specification of the protocol as deployed by the validators into mainnet.

[![diagram 1](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG4gICAgbG9vcCBEZXNpZ25cbiAgICAgICAgU3BlY2lmaWNhdGlvbiB0YXNrLT4-TWVyZ2UgcmVxdWVzdDogV3JpdGUgc3BlY2lmaWNhdGlvblxuTWVyZ2UgcmVxdWVzdC0-PlNwZWNpZmljYXRpb24gdGFzazogSW50ZWdyYXRlIGZlZWRiYWNrICAgIFxuICAgIGVuZFxuTWVyZ2UgcmVxdWVzdC0-PkltcGxlbWVudGF0aW9uIHRhc2s6IFNjb3BlIG5leHQgcmVsZWFzZVxuICAgICAgICBNZXJnZSByZXF1ZXN0IC0tPj5NZXJnZSByZXF1ZXN0OiBDbG9zZSB0aWNrZXRcbiAgICAgICAgSW1wbGVtZW50YXRpb24gdGFzayAtLT4-SW1wbGVtZW50YXRpb24gdGFzazogTmV3IHRpY2tldCAiLCJtZXJtYWlkIjp7fSwidXBkYXRlRWRpdG9yIjpmYWxzZX0)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG4gICAgbG9vcCBEZXNpZ25cbiAgICAgICAgU3BlY2lmaWNhdGlvbiB0YXNrLT4-TWVyZ2UgcmVxdWVzdDogV3JpdGUgc3BlY2lmaWNhdGlvblxuTWVyZ2UgcmVxdWVzdC0-PlNwZWNpZmljYXRpb24gdGFzazogSW50ZWdyYXRlIGZlZWRiYWNrICAgIFxuICAgIGVuZFxuTWVyZ2UgcmVxdWVzdC0-PkltcGxlbWVudGF0aW9uIHRhc2s6IFNjb3BlIG5leHQgcmVsZWFzZVxuICAgICAgICBNZXJnZSByZXF1ZXN0IC0tPj5NZXJnZSByZXF1ZXN0OiBDbG9zZSB0aWNrZXRcbiAgICAgICAgSW1wbGVtZW50YXRpb24gdGFzayAtLT4-SW1wbGVtZW50YXRpb24gdGFzazogTmV3IHRpY2tldCAiLCJtZXJtYWlkIjp7fSwidXBkYXRlRWRpdG9yIjpmYWxzZX0)

## Reviewing Specifications

When a pull request is open, this is a request for feedback from the author of the specification. It is the author's responsibility to solicit feedback from the appropriate development teams or system architects, but anyone is free to browse the open merge requests and pitch in.

## Implementing a specification

When a specification is merged to `master`, it is ready for development. Not all specification updates will imply the need for an implementation task (for example, a spec bug). If an implementation task is required, a new _implement_ ticket must be created in the [implement board](https://github.com/orgs/vegaprotocol/projects/42). The person responsible for creating this ticket is the person who has taken the lead on the specification task, in collaboration with the engineering team.

These issues will be prioritised on a weekly basis through a collaborative Slack meeting.

The relevant team can then break the specification down in to technical tasks in their own task system.

Issues should be created in the Product issue list to define a particular scope for an upcoming release/milestone. The specification should be as complete as it can be, while the issue may be a smaller piece on the way to implementing the first specification.

- Implementation tickets will be handled by the relevant team and linked back to the product tickets
- At the completion of implementation, the product ticket should be closed.
- Future work will be scoped in a new ticket
- Any changes to the specification should be done in new merge requests.

[![diagram 2](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5cbkltcGxlbWVudCB0YXNrLT4-RGV2ZWxvcG1lbnQ6IEVuZ2luZWVycyBsaW5rIHRvIHRoZWlyIG93biB0aWNrZXRzXG5EZXZlbG9wbWVudC0tPj5EZXZlbG9wbWVudDogIEVuZ2luZWVycyBjcmVhdGUgb3duIHRpY2tldHNcbkltcGxlbWVudCB0YXNrLT4-RGV2ZWxvcG1lbnQ6IFJldmlldyBhY2NlcHRhbmNlIGNyaXRlcmlhIGFnYWluc3QgdGVzdHNcbkltcGxlbWVudCB0YXNrLT4-RGV2ZWxvcG1lbnQ6IFFBXG5JbXBsZW1lbnQgdGFzay0-PkRldmVsb3BtZW50OiBSZWxlYXNlIiwibWVybWFpZCI6e30sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5cbkltcGxlbWVudCB0YXNrLT4-RGV2ZWxvcG1lbnQ6IEVuZ2luZWVycyBsaW5rIHRvIHRoZWlyIG93biB0aWNrZXRzXG5EZXZlbG9wbWVudC0tPj5EZXZlbG9wbWVudDogIEVuZ2luZWVycyBjcmVhdGUgb3duIHRpY2tldHNcbkltcGxlbWVudCB0YXNrLT4-RGV2ZWxvcG1lbnQ6IFJldmlldyBhY2NlcHRhbmNlIGNyaXRlcmlhIGFnYWluc3QgdGVzdHNcbkltcGxlbWVudCB0YXNrLT4-RGV2ZWxvcG1lbnQ6IFFBXG5JbXBsZW1lbnQgdGFzay0-PkRldmVsb3BtZW50OiBSZWxlYXNlIiwibWVybWFpZCI6e30sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)

## Notes

The workflow for this is partially based on the [Rust RFC process](https://github.com/rust-lang/rfcs), adapted for an earlier stage software design process.

It is being adopted as a replacement for using GitHub issues, which is where past product specifications have been written up.
