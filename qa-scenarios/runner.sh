#!/bin/bash

# require 1 argument = the test file to run
if test "$#" -lt 1 ; then
    echo "error: need test file"
    echo "usage: ./runner.sh [testname]"
    exit 0
fi

testname=$(echo $1 | sed -e 's/\.sh$//')

# if file does not exists, exit with error
if [ ! -f "$testname.sh" ]; then
    echo "error: file not found ($1.sh)"
    exit 0
fi

testfile="$testname.sh"
timestamp=$(date +%Y%m%d-%H%M%S)
echo "test name: $testname (run at $timestamp)"

# make sure local machine has all the test market config files (always overwrite)
  cp -f ./qa_market_configs/* ~/.vega/markets

marketname=$(./$testfile -market)
marketid=$(cat ~/.vega/markets/*.json | jq -sr "map(select(.name==\"$marketname\")) | .[0].id")

if [ $marketid = "null" ]; then
    echo "error: couldn't find ID for market: $marketname"
    exit 1
fi
echo "found ID for market: $marketname => $marketid"

killall tendermint 2> /dev/null
killall vega 2> /dev/null
echo "waiting 1 sec for any existing tendermint/vega processes to exit"
sleep 1

mkdir results.${timestamp}.$testname

# This assumes you have tendermint running locally:
{ tendermint unsafe_reset_all && tendermint init && tendermint node & } 2> ./"results.${timestamp}.$testname/tendermint.stderr" 1> ./"results.${timestamp}.$testname/tendermint.stdout"
# and fresh Vega:
rm -rf "$HOME/.vega/"*store && vega node 2> ./"results.${timestamp}.$testname/vega.stderr" 1> ./"results.${timestamp}.$testname/vega.stdout" &

echo "waiting 5 sec for tendermint and vega to start"
sleep 5

# starting the streaming stuff
echo "starting vega streams"
vegastream -orders 2>> "results.${timestamp}.$testname/orders.out" 1>> "results.${timestamp}.$testname/orders.out" &
vegastream -trades 2>> "results.${timestamp}.$testname/trades.out" 1>> "results.${timestamp}.$testname/trades.out" &
vegastream -accounts 2>> "results.${timestamp}.$testname/accounts.out" 1>> "results.${timestamp}.$testname/accounts.out" &
vegastream -transfers  2>> "results.${timestamp}.$testname/transfers.out" 1>> "results.${timestamp}.$testname/transfers.out"&

echo ""
echo -e "executing testfile: $testfile"
./$testfile $marketid

echo ""
echo ""
echo "cleaning up"

# get it a bit of time and then kill stuff
sleep 1
killall vegastream
killall tendermint
killall vega
echo "done, to view output: cat results.${timestamp}.${testname}/*.out"
