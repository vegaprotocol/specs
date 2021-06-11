## Weight of validators

If there are less than 7 validators, we can only tolerate 1 failure. As such all validators have a weight of 1.

In all other cases, the validator weight is equivalent to the reward. Simply put:

```go

if len(validators) > 7 {
	for _, validator := validators {
		validator.Weight = 1
	}
} else {
	for _, validator := range validators {
		validator.Weight = validator.Reward
	}
}
```

### Interventions

We need to intervene if 1/6 of the parties have more than 1/3rd of the total weight, then we need to reduce the weight proportionately to get back down to 1/3rd.

If half of the validators hold more than 2/3rds of the weight, then we have to intervene in the same way.


The formula to adjust the weight would be:

```go
top, total := 0, 0
for _, val := range validators {
	total += val.Weight
}
for _, val := range topThirdValidators {
	top += val.Weight
}
// adjust weight
for _, val := range topThirdValidators {
	val.Weight = math.Floor(val.Weight * total/(3*top))
}
``` 
