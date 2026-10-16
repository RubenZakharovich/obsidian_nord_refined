#!/usr/bin/env python3
"""Integration checks in an isolated copy; never mutate the active theme."""
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
initial = (ROOT / 'theme.css').read_bytes()

with tempfile.TemporaryDirectory(prefix='nord-background-test-') as temporary:
    root = Path(temporary)
    shutil.copytree(ROOT / 'scripts', root / 'scripts')
    shutil.copytree(ROOT / 'experiments', root / 'experiments')
    theme = root / 'theme.css'
    theme.write_bytes(initial)

    def run(*args, script='apply-background.sh', success=True):
        result = subprocess.run(['bash', str(root / 'scripts' / script), *args],
                                capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stderr
        return result.stdout

    def block(mode):
        match = re.search(
            rf'/\* NORD REFINED BACKGROUND {mode.upper()} START \*/.*?'
            rf'/\* NORD REFINED BACKGROUND {mode.upper()} END \*/',
            theme.read_text(), re.S)
        return match.group() if match else None

    heading = re.search(r'/\* NORD REFINED PALETTE START \*/(.*?)/\* NORD REFINED PALETTE END \*/',
                        initial.decode(), re.S).group(1)
    assert heading.strip() == (root / 'experiments/palette-custom.css').read_text().strip()
    assert 'softer' in run('list') and 'muted' in run('list')
    listing = run('list')
    for name in ('original', 'cool', 'warm', 'muted', 'vanilla-latte', 'mocha-frappe', 'oat-milk'):
        assert name in listing
    for mode in ('dark', 'light'):
        run(mode, 'reset')
    baseline = theme.read_bytes()
    candidates = 0
    for mode in ('dark', 'light'):
        other = 'light' if mode == 'dark' else 'dark'
        run(other, 'deeper' if other == 'dark' else 'warm')
        preserved = block(other)
        for css in sorted((root / 'experiments/backgrounds').glob(f'{mode}-*.css')):
            candidates += 1
            name = css.stem[len(mode) + 1:]
            run(mode, name)
            assert css.read_text().strip() in block(mode)
            assert block(other) == preserved
            applied = theme.read_bytes()
            run(mode, name)
            assert theme.read_bytes() == applied
            assert heading in theme.read_text()
            for appearance in ('dark', 'light'):
                assert theme.read_text().count(f'/* NORD REFINED BACKGROUND {appearance.upper()} START */') == 1
                assert theme.read_text().count(f'/* NORD REFINED BACKGROUND {appearance.upper()} END */') == 1
        run(mode, 'reset')
        assert block(mode) is None and block(other) == preserved
        run(other, 'reset')
        assert theme.read_bytes() == baseline
    print(f'PASS: all {candidates} candidates (light switches preserve Deeper), idempotence, independent selection/reset, exact base restoration, headings preserved')

    run('dark', 'softer')
    run('light', 'warm')
    backgrounds = (block('dark'), block('light'))
    for choice in ('slate', 'sage', 'steel', 'reset', 'custom'):
        run(choice, script='apply-palette.sh')
        assert (block('dark'), block('light')) == backgrounds
    assert heading in theme.read_text()
    print('PASS: every heading operation preserves both backgrounds; custom headings restored in test copy')

    for args in ((), ('dark',), ('dark', 'missing'), ('light', '../warm'),
                 ('wrong', 'warm'), ('list', 'extra'), ('dark', 'warm', 'extra')):
        before = theme.read_bytes()
        run(*args, success=False)
        assert theme.read_bytes() == before
    for bad in ('/* NORD REFINED BACKGROUND DARK START */',
                block('dark') + '\n' + block('dark'),
                '/* NORD REFINED BACKGROUND DARK END */\n/* NORD REFINED BACKGROUND DARK START */'):
        theme.write_bytes(bad.encode())
        run('dark', 'warm', success=False)
        assert theme.read_bytes() == bad.encode()
    theme.unlink()
    run('dark', 'warm', success=False)
    print('PASS: invalid arguments, missing files, incomplete/duplicate/reversed markers fail without writes')

assert (ROOT / 'theme.css').read_bytes() == initial
print('PASS: live theme unchanged; original background state and custom headings retained')
