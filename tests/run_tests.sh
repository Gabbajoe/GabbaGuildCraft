#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for file in ./*.lua tests/*.lua; do "${LUAC:-luac}" -p "$file"; done
"${LUA:-lua}" tests/run.lua
"${LUA:-lua}" tests/ui.lua
