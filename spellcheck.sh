#!/bin/bash -x

echo "Installing pyspelling..."

pip3 install pyspelling

echo "Installing aspell..."

brew install aspell

echo "Running the spell checker..."

python3 -m pyspelling --config spellcheck.yaml

echo "Remove dictionary binary..."

rm -r dictionary.dic
