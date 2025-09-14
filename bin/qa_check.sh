#!/usr/bin/env bash

export MIX_ENV=test

echo "### Running code formatting..."
mix format

echo "### Running tests..."
mix test

echo "### Running compilation warnings..."
mix compile --warnings-as-errors

echo "### Running Dialyzer..."
mix dialyzer --quiet-with-result