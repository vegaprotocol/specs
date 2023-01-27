#!/bin/bash -x

echo "Installing pyspelling..."

pip3 install pyspelling

echo "Installing aspell..."

brew install aspell

echo "Running the spell checker..."

pyspelling --config spellcheck.yaml
