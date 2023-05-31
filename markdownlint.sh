#!/bin/bash -x

echo "Installing markdownlint-cli..."

npm install -g markdownlint-cli --yes

echo "Running markdownlint-cli..."

markdownlint --ignore-path .github/workflows/config/markdownlintignore --config .github/workflows/config/markdownlint.json .
