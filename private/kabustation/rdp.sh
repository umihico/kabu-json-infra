#!/bin/bash
set -euoxv pipefail

printf "%s" "${RDP_PASSWORD}" | pbcopy
ip=$(cat private/kabustation/ip.json)
echo "full address:s:${ip}:3389" > private/kabustation/kabu-json-windows-config.rdp
echo "username:s:Administrator" >> private/kabustation/kabu-json-windows-config.rdp
echo "prompt for credentials:i:1" >> private/kabustation/kabu-json-windows-config.rdp
echo "screen mode id:i:1" >> private/kabustation/kabu-json-windows-config.rdp
open private/kabustation/kabu-json-windows-config.rdp
