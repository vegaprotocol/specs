#!/bin/bash

# require 1 argument = the test file to run
if test "$#" -lt 1 ; then
    echo "error: need test file"
    echo "usage: ./runner.sh [testname]"
    exit 0
fi

# if file does not exists, exit with error
if [ ! -f "$1.sh" ]; then
    echo "error: file not found ($1.sh)"
    exit 0
fi

timestamp=$(date +%Y%m%d-%H%M)

testname=$1
testfile="$1.sh"

marketname=$(./$testfile -market)
marketid=$(cat ~/.vega/markets/*.json | jq -sr "map(select(.name==\"$marketname\")) | .[0].id")

if [ $marketid = "null" ]; then
    echo "error: couldn't find ID for market: $marketname"
    exit 1
fi
echo "found ID for market: $marketname => $marketid"

killall tendermint
killall vega

echo "Waiting 1 sec"
sleep 1

mkdir results.${timestamp}.$testname

# This assumes you have tendermint running locally:
tendermint unsafe_reset_all && tendermint init && tendermint node  2> ./"results.${timestamp}.$testname/tendermint.stderr.out" 1> ./"results.${timestamp}.$testname/tendermint.stdout.out" &
# and fresh Vega:
rm -rf "$HOME/.vega/"*store && vega node 2> ./"results.${timestamp}.$testname/vega.stderr.out" 1> ./"results.${timestamp}.$testname/vega.stdout.out" &

echo "Waiting 5 sec"
sleep 5

# starting the streaming stuff
echo "starting vega streams"
vegastream -orders 2>> "results.${timestamp}.$testname/orders.out" 1>> "results.${timestamp}.$testname/orders.out" &
vegastream -trades 2>> "results.${timestamp}.$testname/trades.out" 1>> "results.${timestamp}.$testname/trades.out" &
vegastream -accounts 2>> "results.${timestamp}.$testname/accounts.out" 1>> "results.${timestamp}.$testname/accounts.out" &
vegastream -transfers  2>> "results.${timestamp}.$testname/transfers.out" 1>> "results.${timestamp}.$testname/transfers.out"&
vegastream -trades 2>> "results.${timestamp}.$testname/trades.out" 1>> "results.${timestamp}.$testname/trades.out" &

echo -e "executing testfile: $testfile"
./$testfile $marketid
echo "cleaning up"

# get it a bit of time and then kill stuff
sleep 1
killall vegastream
killall tendermint
killall vega

echo ""
echo "done, to view output: cat results.${timestamp}.${testname}/*.out"
