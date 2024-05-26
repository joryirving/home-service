#!/usr/bin/env bash

echo "BLOCKY PRIMARY external query"
dig +short @192.168.1.2 google.com | sed 's/^/  /'
echo "---"
echo "BLOCKY PRIMARY internal query"
dig +short @192.168.1.2 unifi.internal | sed 's/^/  /'
echo "---"
echo "BLOCKY PRIMARY main cluster query"
dig +short @192.168.1.2 echo-server.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY PRIMARY reverse query"
dig +short @192.168.1.2 -x 10.69.1.100 | sed 's/^/  /'
echo "---"

echo "BLOCKY SECONDARY external query"
dig +short @192.168.1.3 google.com | sed 's/^/  /'
echo "---"
echo "BLOCKY SECONDARY internal query"
dig +short @192.168.1.3 unifi.internal | sed 's/^/  /'
echo "---"
echo "BLOCKY SECONDARY main cluster query"
dig +short @192.168.1.3 echo-server.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY SECONDARY reverse query"
dig +short @192.168.1.3 -x 10.69.1.100 | sed 's/^/  /'
echo "---"

echo "UNIFI external query"
dig +short @192.168.1.1 google.com | sed 's/^/  /'
echo "---"
echo "UNIFI internal query - (this should fail)"
dig +short @192.168.1.1 unifi.jory.dev | sed 's/^/  /'
echo "---"
echo "UNIFI main cluster query"
dig +short @192.168.1.1 echo-server.jory.dev | sed 's/^/  /'
echo "---"
