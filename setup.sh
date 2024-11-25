#!/bin/bash
set -euoxv pipefail

sh private/kabustation/ssh-windows.sh pwd
sh private/kabustation/ssh-linux.sh tmux new -d -s winssh ssh kabu-json-windows
sh private/kabustation/rdp.sh
sh private/kabustation/ssh-linux.sh
