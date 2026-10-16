#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    echo "Usage: $0 list | {dark|light} {NAME|reset}" >&2
}

if [[ $# == 1 && $1 == list ]]; then
    MODE=list
    CHOICE=''
elif [[ $# == 2 && ( $1 == dark || $1 == light ) ]]; then
    MODE="$1"
    CHOICE="$2"
    if [[ ! $CHOICE =~ ^[a-z][a-z0-9-]*$ ]]; then
        usage
        exit 1
    fi
else
    usage
    exit 1
fi

export ROOT MODE CHOICE
python3 - <<'PY'
import os
from pathlib import Path

root = Path(os.environ['ROOT'])
mode, choice = os.environ['MODE'], os.environ['CHOICE']
# Discover palette files dynamically, including hyphenated names such as vanilla-latte.
directory = root / 'experiments' / 'backgrounds'

def fail(message):
    raise SystemExit(f'Error: {message}')

try:
    if not directory.is_dir():
        fail(f'Missing experiment directory: {directory}')
    if mode == 'list':
        for appearance in ('dark', 'light'):
            names = sorted(p.stem[len(appearance) + 1:]
                           for p in directory.glob(f'{appearance}-*.css') if p.is_file())
            print(f'{appearance}: {", ".join(names)} (or reset)')
        raise SystemExit(0)

    theme = root / 'theme.css'
    # Decode bytes explicitly to preserve existing line endings outside our block.
    source = theme.read_bytes().decode('utf-8')
    spans = {}
    for appearance in ('dark', 'light'):
        start = f'/* NORD REFINED BACKGROUND {appearance.upper()} START */'
        end = f'/* NORD REFINED BACKGROUND {appearance.upper()} END */'
        if source.count(start) != source.count(end) or source.count(start) > 1:
            fail(f'Incomplete or duplicate {appearance} background markers.')
        if start in source:
            left, right = source.index(start), source.index(end)
            if right < left:
                fail(f'Reversed {appearance} background markers.')
            spans[appearance] = (left, right + len(end))
    if len(spans) == 2:
        a, b = sorted(spans.values())
        if a[1] > b[0]:
            fail('Overlapping background markers.')

    block = ''
    if choice != 'reset':
        experiment = directory / f'{mode}-{choice}.css'
        if not experiment.is_file():
            fail(f'Unknown experiment or missing file: {experiment}. Run {root / "scripts/apply-background.sh"} list.')
        css = experiment.read_text().rstrip()
        block = (f'/* NORD REFINED BACKGROUND {mode.upper()} START */\n'
                 f'{css}\n'
                 f'/* NORD REFINED BACKGROUND {mode.upper()} END */')

    if mode in spans:
        left, right = spans[mode]
        if not block:
            # Remove only the separator and final newline owned by this block.
            if left > 0 and source[left - 1] == '\n':
                left -= 1
            if source[right:right + 1] == '\n':
                right += 1
        updated = source[:left] + block + source[right:]
    elif block:
        updated = source + '\n' + block + '\n'
    else:
        updated = source
    if updated != source:
        theme.write_bytes(updated.encode('utf-8'))
    print(f'{mode} background: {choice}')
except (OSError, UnicodeError) as error:
    fail(str(error))
PY
