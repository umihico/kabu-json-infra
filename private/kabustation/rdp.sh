#!/bin/bash
set -euoxv pipefail

printf "%s" "${RDP_PASSWORD}" | pbcopy
windows_hostname=$(cat private/kabustation/windows_hostname.json)
echo "full address:s:${windows_hostname}:3389" > private/kabustation/kabu-json-windows-config.rdp
echo "username:s:Administrator" >> private/kabustation/kabu-json-windows-config.rdp
echo "prompt for credentials:i:1" >> private/kabustation/kabu-json-windows-config.rdp
echo "screen mode id:i:1" >> private/kabustation/kabu-json-windows-config.rdp
open private/kabustation/kabu-json-windows-config.rdp
