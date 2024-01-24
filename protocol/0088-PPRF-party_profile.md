# On-chain Party Profile

The on-chain party profile feature allows users to associate a unique alias and free-form metadata with a public key they own. This data is stored on-chain and is exposed to anyone through APIs.


## Updating a party profile

Any user with a public key is able to update their party profile by submitting a signed `UpdatePartyProfile` transaction.

To prevent spam attacks, the number of transactions which can be sent in an epoch per party is restricted and a parties total balance across all assets (expressed in quantum) must exceed `spam.protection.updatePartyProfile.min.funds`. Refer to the [spam protection specification](./0062-SPAM-spam_protection.md#party-profile-spam) for further details on these restrictions.

An `UpdatePartyProfile` has the following fields.

- `alias`: an optional string which can be as an alternative identifier for the public key in any dApp (e.g. in competition leaderboards).
- `metadata`: an optional list of metadata key value pairs to further describe a public key.

If metadata is specified, the metadata must adhere to the following rules:

- no more than 10 key value pairs can be specified
- a key must be no longer than 32 characters
- a value must be no longer than 255 characters

If an alias is specified, it must adhere to the following rules:

- the alias must be no longer than 32 characters
- the alias must be unique (i.e. the alias must not already be associated with an existing party profile)

**Note:**
In order to validate uniqueness of an alias, core must keep a record of the aliases associated with each party. If a party is no longer active.

### Acceptance Criteria

- If a party updates there profile with an alias of a length greater than 32 characters, the transaction is rejected. (<a name="0088-PPRF-001" href="#0088-PPRF-001">0088-PPRF-001</a>)
- If a party updates there profile with an alias which is already associated with another key, the transaction is rejected. (<a name="0088-PPRF-002" href="#0088-PPRF-002">0088-PPRF-002</a>)
- If a party update there profile with metadata with more then 10 key pairs, the transaction is rejected. (<a name="0088-PPRF-003" href="#0088-PPRF-003">0088-PPRF-003</a>)
- If a party update there profile with metadata with a key of  a length more than 32 characters, the transaction is rejected. (<a name="0088-PPRF-004" href="#0088-PPRF-004">0088-PPRF-004</a>)
- If a party update there profile with metadata with a value of a length more than 255 characters, the transaction is rejected. (<a name="0088-PPRF-005" href="#0088-PPRF-005">0088-PPRF-005</a>)
