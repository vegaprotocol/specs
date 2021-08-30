// Validatores = delegators
// Round 4 for sqrt
// Round 8 for proportion

// For distribution, round down. Rounding errors go to the bank.

package main

import (
	"fmt"
	"math"
)

type validatorSettings struct {
	minVal         uint
	compLevel      float64
	numVal         uint
	delegatorShare float64
	total          uint
}

func setValidatorSettings(numberOfValidators uint) validatorSettings {
	s := validatorSettings{}
	s.minVal = 5
	s.compLevel = 1.1
	s.numVal = numberOfValidators
	s.delegatorShare = 0.883
	return s
}

func validatorScore(valStake uint, s validatorSettings) float64 {
	a := math.Max(float64(s.minVal), float64(s.numVal)/s.compLevel)
	score := math.Min(float64(valStake)/float64(s.total), 1.0/a)
	// Nobody should get a negative score (i.e., pay)
	if score < 0 {
		score = 0
	}
	return score
}

func delegatorScore(delegatorStake, valStake uint) float64 {
	return float64(delegatorStake)
}

func main() {
	fmt.Println("Hello. Let's set up some validators")
	// amount to be distributed
	const totalRewardForEpoch uint = 100000
	var remainingFromRewardForEpoch float64 = float64(totalRewardForEpoch)

	// don't duplicate ids below or else
	validators := []struct {
		id        uint
		numTokens uint
	}{
		{0, 1000},
		{1, 2000},
		{2, 3000},
		{3, 5000},
		{4, 1000},
		{5, 100},
		{6, 100},
		{7, 100},
		{8, 100},
	}

	var numValidators uint = 0
	var totalTokens uint = 0
	var totalTokensPlusDelegated uint = 0
	var min_stake uint = 3000

	for _, val := range validators {
		numValidators++
		totalTokens += val.numTokens
	}
	fmt.Printf("Total tokens validators own = %d\n", totalTokens)

	validatorOwnPlusDelegatedTokens := make([]uint, numValidators)
	validatorTotalDelegatedTokens := make([]uint, numValidators)
	for _, val := range validators {
		validatorOwnPlusDelegatedTokens[val.id] = val.numTokens
		totalTokensPlusDelegated += val.numTokens
	}

	valSettings := setValidatorSettings(numValidators)
	fmt.Println("Got validator settings.")

	delegations := []struct {
		delId     uint
		toValId   uint
		numTokens uint
	}{
		{0, 0, 10},
		{1, 0, 20},
		{2, 8, 100},
		{3, 8, 1000},
	}

	var numDelegators uint = 0

	// I am assuming that the total for a validator is what they have plus all
	// that's delegated to them
	for _, delegator := range delegations {
		validatorTotalDelegatedTokens[delegator.toValId] += delegator.numTokens
		validatorOwnPlusDelegatedTokens[delegator.toValId] += delegator.numTokens
		totalTokensPlusDelegated += delegator.numTokens
		numDelegators++
	}

	fmt.Printf("Total tokens in play = %d\n", totalTokensPlusDelegated)

	valSettings.total = totalTokensPlusDelegated
	validatorScores := make([]float64, numValidators)
	totalValidatorScore := 0.0
	for _, val := range validators {
		valScore := validatorScore(validatorOwnPlusDelegatedTokens[val.id], valSettings)
		totalValidatorScore += valScore
		validatorScores[val.id] = valScore
	}

	// this is what validators get for the epoch but part of it
	// is still due their delegators, this will be dealt with in a bit
	validatorAmounts := make([]float64, numValidators)
	for _, val := range validators {
		validatorAmounts[val.id] = float64(totalRewardForEpoch) * validatorScores[val.id] / totalValidatorScore
		remainingFromRewardForEpoch -= float64(validatorAmounts[val.id])
	}

	fmt.Printf("First sanity check, remaining should be 0 and is=%f\n", remainingFromRewardForEpoch)

	validatorAmountKeep := make([]float64, numValidators)
	var leftOverDueToInsufficientStake float64 = 0.0
	validatorAmountGiveToDelegators := make([]float64, numValidators)
	for _, val := range validators {
		tokensDelegatedToValidator := validatorTotalDelegatedTokens[val.id]
		tokensDelegatedPlusOwned := validatorOwnPlusDelegatedTokens[val.id]
		fractionDelegatorsGet := valSettings.delegatorShare * float64(tokensDelegatedToValidator) / float64(tokensDelegatedPlusOwned)
		validatorAmountGiveToDelegators[val.id] = fractionDelegatorsGet * validatorAmounts[val.id]
		validatorAmountKeep[val.id] = (1.0 - fractionDelegatorsGet) * validatorAmounts[val.id]

		// If the validator has sufficient own_stake, then they get nothing
		// The corrsponding finds are kept, not given to other validators
		// However, they don't need to have those tokens delegated to self, just
		// own them; thus, there's something along the line of
		if val.numTokens < min_stake {
			leftOverDueToInsufficientStake += validatorAmountKeep[val.id]
			validatorAmountKeep[val.id] = 0

		}
	}

	// let's do more accounting
	totalDistributed := 0.0

	// now each delegator gets an amount
	for _, delegator := range delegations {
		totalDelegatedTokensOfChosenValidator := validatorTotalDelegatedTokens[delegator.toValId]
		thisDelegatorProportion := float64(delegator.numTokens) / float64(totalDelegatedTokensOfChosenValidator)
		thisDelegatorAmt := thisDelegatorProportion * validatorAmountGiveToDelegators[delegator.toValId]
		totalDistributed += thisDelegatorAmt
		fmt.Printf("delegator id=%d, gets amt=%f\n", delegator.delId, thisDelegatorAmt)
	}

	// and we print what each validator gets
	for _, val := range validators {
		totalValidatorGets := validatorAmountKeep[val.id]
		totalDistributed += totalValidatorGets
		fmt.Printf("validator id=%d, gets amt=%f\n", val.id, totalValidatorGets)
	}

	fmt.Printf("Second sanity check, we should distribute %d and we distributed=%d\n", totalRewardForEpoch-uint(leftOverDueToInsufficientStake), int(totalDistributed))
}
