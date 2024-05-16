#!/usr/bin/env bash

echo "blocky external query"
dig +short @192.168.1.2 google.com | sed 's/^/  /'
echo "bind external query"
dig +short @192.168.1.123 google.com | sed 's/^/  /'
echo "-----------------------------"
echo "blocky internal query"
dig +short @192.168.1.2 nas.jory.casa | sed 's/^/  /'
echo "bind internal query"
dig +short @192.168.1.123 nas.jory.casa | sed 's/^/  /'
echo "-----------------------------"
echo "blocky cluster query"
dig +short @192.168.1.2 echo-server.jory.dev | sed 's/^/  /'
echo "bind cluster query"
dig +short @192.168.1.123 echo-server.jory.dev | sed 's/^/  /'
echo "-----------------------------"