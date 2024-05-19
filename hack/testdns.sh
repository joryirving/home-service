#!/usr/bin/env bash

echo "BLOCKY PRIMARY external query"
dig +short @192.168.1.2 google.com | sed 's/^/  /'
echo "BIND PRIMARY external query"
dig +short @192.168.1.2 -p 5301 google.com | sed 's/^/  /'
echo "---"
echo "BLOCKY PRIMARY internal query"
dig +short @192.168.1.2 unifi.internal | sed 's/^/  /'
echo "BIND PRIMARY internal query"
dig +short @192.168.1.2 -p 5301 unifi.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY PRIMARY main cluster query"
dig +short @192.168.1.2 echo-server.jory.dev | sed 's/^/  /'
echo "BIND PRIMARY main cluster query"
dig +short @192.168.1.2 -p 5301 echo-server.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY PRIMARY reverse query"
dig +short @192.168.1.2 -x 10.69.1.100 | sed 's/^/  /'
echo "---"

echo "BLOCKY SECONDARY external query"
dig +short @192.168.1.3 google.com | sed 's/^/  /'
echo "BIND SECONDARY external query"
dig +short @192.168.1.3 -p 5301 google.com | sed 's/^/  /'
echo "---"
echo "BLOCKY SECONDARY internal query"
dig +short @192.168.1.3 unifi.internal | sed 's/^/  /'
echo "BIND SECONDARY internal query"
dig +short @192.168.1.3 -p 5301 unifi.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY SECONDARY main cluster query"
dig +short @192.168.1.3 echo-server.jory.dev | sed 's/^/  /'
echo "BIND SECONDARY main cluster query"
dig +short @192.168.1.3 -p 5301 echo-server.jory.dev | sed 's/^/  /'
echo "---"
echo "BLOCKY SECONDARY reverse query"
dig +short @192.168.1.3 -x 10.69.1.100 | sed 's/^/  /'
echo "---"