#!/bin/bash
set -euoxv pipefail

printf "%s" "${RDP_PASSWORD}" | pbcopy
ip=$(cat private/windows/ip.json)
echo "full address:s:${ip}:3389" > private/windows/kabu-json-windows-config.rdp
echo "username:s:Administrator" >> private/windows/kabu-json-windows-config.rdp
echo "prompt for credentials:i:1" >> private/windows/kabu-json-windows-config.rdp
echo "screen mode id:i:1" >> private/windows/kabu-json-windows-config.rdp
open private/windows/kabu-json-windows-config.rdp
