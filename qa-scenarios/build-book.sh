#!/bin/bash
# add some orders the party david is "market making" this creates volume on the book

marketid=$1

# BUY SIDE

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"david\"\n    price: \"9900\"\n    size: \"5\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"david\"\n    price: \"9800\"\n    size: \"2\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"david\"\n    price: \"9700\"\n    size: \"10\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

# SELL SIDE

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"david\"\n    price: \"10100\"\n    size: \"5\"\n    side:Sell\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"david\"\n    price: \"10200\"\n    size: \"2\"\n    side:Sell\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"david\"\n    price: \"10300\"\n    size: \"10\"\n    side:Sell\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed