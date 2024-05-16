#!/usr/bin/env bash

echo "blocky external query"
dig +short @192.168.1.122 google.com | sed 's/^/  /'
echo "bind external query"
dig +short @192.168.1.121 google.com | sed 's/^/  /'
echo "-----------------------------"
echo "blocky internal query"
dig +short @192.168.1.122 nas.jory.casa | sed 's/^/  /'
echo "bind internal query"
dig +short @192.168.1.121 nas.jory.casa | sed 's/^/  /'
echo "-----------------------------"
echo "blocky cluster query"
dig +short @192.168.1.122 echo-server.jory.dev | sed 's/^/  /'
echo "bind cluster query"
dig +short @192.168.1.121 echo-server.jory.dev | sed 's/^/  /'
echo "-----------------------------"