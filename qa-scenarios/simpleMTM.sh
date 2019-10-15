#!/bin/bash

# create accounts for david and edd:
echo "creating accounts"
vegaccount -traderid david
vegaccount -traderid edd -amount 10000
echo "Waiting 1 sec" && sleep 1

# set your market
marketid="GDVRC6MR5A255GTNVYL4T7F2FUTUPV3U"

# Build the book with David market making
echo -e "building the order book using: build-book.sh"
./build-book.sh
echo "order book is built"

echo ""
echo "Waiting 2 sec" && sleep 2

# Place an order to buy, that will trade
echo "placing an order"
curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"edd\"\n    price: \"10500\"\n    size: \"5\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed

# Now Edd is long 5 and David is short 5 @ entry-price = 10,100 (best offer gets taken). TODO - one day I'll be able to get this from a curl command too.

echo ""
echo "Waiting 2 sec" && sleep 2

# Add a new trade which changes the mark price

curl 'http://localhost:3004/query' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Connection: keep-alive' -H 'DNT: 1' -H 'Origin: http://localhost:3004' --data-binary '{"query":"mutation {\n  orderSubmit(\n    marketId: \"'"$marketid"'\"\n    partyId:\"edd\"\n    price: \"10200\"\n    size: \"1\"\n    side:Buy\n    timeInForce:GTC\n  ) {\n    reference\n  }\n}"}' --compressed
