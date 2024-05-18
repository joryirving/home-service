#!/usr/bin/env bash

echo "BLOCKY external query"
dig +short @192.168.1.4 google.com | sed 's/^/  /'
echo "BIND external query"
dig +short @192.168.1.4 -p 5301 google.com | sed 's/^/  /'
echo "---"
echo "BLOCKY internal query"
dig +short @192.168.1.4 unifi.internal | sed 's/^/  /'
echo "BIND internal query"
dig +short @192.168.1.4 -p 5301 unifi.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY main cluster query"
dig +short @192.168.1.4 echo-server.jory.dev | sed 's/^/  /'
echo "BIND main cluster query"
dig +short @192.168.1.4 -p 5301 echo-server.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY reverse query"
dig +short @192.168.1.4 -x 10.69.1.100 | sed 's/^/  /'
echo "---"