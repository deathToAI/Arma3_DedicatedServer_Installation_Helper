#!/bin/bash
echo "=== Parando todos Headless Clients ==="
pkill -f "arma3server.*-client.*-name=HC1"
pkill -f "arma3server.*-client.*-name=HC2"
pkill -f "arma3server.*-client.*-name=HC3"
echo "Headless Clients finalizados."