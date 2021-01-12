PLACEHOLDER FROM OTHER SPEC - WIP / IGNORE! 

NOT STARTED


PROBABLY NONSENSE




SERIOUSLY, NO...




I HOPE YOU KNOW WHAT YOU'RE DOING




If any of filters do not match (or are of the wrong type) the message is ignored and not passed as a valid data point to whatever defined the source.

Also if the specified field is of the wrong type, the data is not passed as a valid data point, but this should create a warning event i.e. "data event passed filter but format of XX field doesn't match data soruce definition" as the format may have changed and it could be necessary for a [market, in the case of settlement] governance action to change the data source.

Need to specify what filters we'll allow and data types.

We support some ability to have arbitrary feeds.
We need to support selecting messages from a stream (e.g. by datetime or by field). Using comparisons (e.g. greater than or equal to a timestamp) and exact equals.
Don't allow nesting of filters
All filters are AND (so all filters must match for a message)


If any of filters do not match (or are of the wrong type) the message is ignored and not passed as a valid data point to whatever defined the source.

Also if the specified field is of the wrong type, the data is not passed as a valid data point, but this should create a warning event i.e. "data event passed filter but format of XX field doesn't match data soruce definition" as the format may have changed and it could be necessary for a [market, in the case of settlement] governance action to change the data source.