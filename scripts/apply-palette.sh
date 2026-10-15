#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHOICE="${1:-}"

case "$CHOICE" in
    slate|sage|steel|custom|reset) ;;
    *)
        echo "Usage: $0 {slate|sage|steel|custom|reset}"
        exit 1
        ;;
esac

export ROOT CHOICE

python3 - <<'PY'
import os
from pathlib import Path

root = Path(os.environ["ROOT"])
choice = os.environ["CHOICE"]

theme_path = root / "theme.css"

start = "/* NORD REFINED PALETTE START */"
end = "/* NORD REFINED PALETTE END */"

source = theme_path.read_text()

# Ensure an existing experiment is properly delimited.
if (start in source) != (end in source):
    raise SystemExit("Error: Incomplete palette markers.")

if start in source:
    before = source.split(start, 1)[0]
    after = source.split(end, 1)[1]
else:
    before = source
    after = ""

# Remove the previously applied experiment.
updated = before.rstrip() + "\n" + after

if choice != "reset":
    palette_path = root / "experiments" / f"palette-{choice}.css"
    palette = palette_path.read_text()

    updated = (
        before.rstrip()
        + "\n\n"
        + start + "\n"
        + palette.rstrip() + "\n"
        + end + "\n"
        + after
    )

theme_path.write_text(updated)
print(f"Applied palette: {choice}")
PY