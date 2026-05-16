#!/usr/bin/env bash
# Headless test runner. Optional arg: a test target (file or dir) relative to res://.
# Examples:
#   ./tests/run.sh                       # all tests
#   ./tests/run.sh tests/test_smoke.gd   # one file
set -euo pipefail

cd "$(dirname "$0")/.."

# First run after a fresh checkout / new class_name must import the project
# so GdUnit4 can resolve its own types and our class_names.
if [ ! -d ".godot" ]; then
	godot --headless --import --path . >/dev/null 2>&1 || true
fi

target="${1:-tests/}"

godot --headless --path . \
	-s addons/gdUnit4/bin/GdUnitCmdTool.gd \
	-a "res://${target}" \
	--ignoreHeadlessMode
