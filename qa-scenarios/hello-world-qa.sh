#!/bin/bash

clear
killall tendermint
killall vega

echo "Waiting 1 sec"
sleep 1

# This assumes you have tendermint running locally: 
tendermint unsafe_reset_all && tendermint init && tendermint node  2> ./tendermint.stderr.out 1> ./tenderming.stdout.out &
# and fresh Vega: 
rm -rf "$HOME/.vega/"*store && vega node 2> ./vega.stderr.out 1> ./vega.stdout.out &

echo "Waiting 5 sec"
sleep 5

# and that you've created accounts for david and edd:
vegaccount -traderid edd
vegaccount -traderid david
echo "Waiting 1 sec" && sleep 1

# add some orders the party david is "market making" this creates volume on the book
curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"david\"\n    price: \"10100\"\n    size: \"1\"\n    side:Sell\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"david\"\n    price: \"9900\"\n    size: \"1\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"david\"\n    price: \"10200\"\n    size: \"2\"\n    side:Sell\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"david\"\n    price: \"9800\"\n    size: \"2\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"david\"\n    price: \"10300\"\n    size: \"10\"\n    side:Sell\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"david\"\n    price: \"9700\"\n    size: \"10\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

echo ""
echo "Waiting 2 sec" && sleep 2


# Now let's see a trade Edd whould buy something
curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\"\n    partyId:\"edd\"\n    price: \"10500\"\n    size: \"5\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed


echo ""
echo "Waiting 1 sec" && sleep 1 

# Let's see open orders
curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"query {\n  markets(id:\"SM5FP5KTOKZHBPP5Q7U7WJ7BWH2J4IUL\") {\n    id\n    name\n    orders(last: 20) {\n      id\n      party { id }\n      price\n      side\n      size\n      remaining\n    }\n  }\n}\n"}' --compressed


echo ""

# git it a bit of time and then kill stuff
#sleep 1
#killall tendermint
#killall vega








