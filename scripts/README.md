# Spec checks
A set of scripts that run over specifications and do various things with
the Acceptance Criteria codes. Specifically, they check that:

* the filenames of protocol specs follow a specific pattern
* specs contain appropriately labelled Acceptance Criteria
* acceptance criteria are referenced by feature tests

## File names
Each protocol specification receives a sequence number when it is merged in to master. 
This sequence number is a 0-padded integer, strictly 1 greater than the last merged 
specification. The sequence number is the start of the filename, with the end result
that the `../protocol/` folder lists files in the order they were created.

After the sequence number, separated by a `-`, is a 4 letter code. This is arbitrary,
and can be made up at merge time. It's there as a helpful hint as to what spec `0001` is,
rather that having to keep that in mind.

The end result is that every specification (`.md` or `.ipynb`) should be named something like:
```
0024-EXMP-example-specification
```

## Acceptance Criteria codes
Acceptance Criteria codes use the first two parts of the filename (detailed above), and then
another sequence number (this time, 0 padded to 3 characters). These are assigned to each specific
acceptance criteria that should be validated by a test (in any test suite.l)

## The result
The result of the rules above is that we can easily map which acceptance criteria are covered
in which test suite, and what our coverage for the main features identified in specs are. This
is the task that these scripts solve.

## How to name a spec
1. When your pull request is ready to merge, take a look at the most recent sequence number in the
`protocol` folder. Maybe the last spec was `0088-BLAH-example.md`. Your sequence number is `0089`.
2. Now, make yourself a code based on the filename. It should be unique, and it should be memorable,
so for example if the spec is `system_accounts.md`, it *could* be 'SYSA', or 'SYAC' - whatever feels
reasonable.
3. Rename your file to `0088-SYSA-system_accounts.md`
4. Label the acceptance criteria `0088-SYSA-001`, `0088-SYSA-002` and so on.
5. Merge!

## How to reference acceptance criteria in a spec.
These are more *convention* than a rule, but following these steps will ensure that the scripts in 
this folder pick up your references.

1. When you are writing your feature, take a look at the acceptance criteria.
2. If you're addressing one, reference it at the end of the Feature name, for example if you are 
writing a test that covers `0008-SYSA-001`, call the feature `Verify blah (0008-SYSA-001)`
3. If it covers more than one feature, add it inside the same brackets: `Verify blah (0008-SYSA-001, 0008-SYSA-002)`
4. If a feature test intentionally covers something that isn't explicitly an acceptance criteria
you can signal this with `0008-SYSA-additional-tests`

# Running
Having `nodejs` installed is the only prerequisite. In the root path, run:

```
make all
```

View the [makefile](../makefile) to see how to run each script individually.

# Development

## Rules of thumb
The scripts have been written with the following criteria in mind.

1. No external runtime dependencies
2. Each script should have an entry in the `makefile`
3. No advanced compilation

They're written in node because... it was easy. The language can be changed, as long as it doesn't
add too much overheard for people to run them locally.

## Checks
- Lint with `npm run standard`