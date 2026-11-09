#!/usr/bin/env python3
"""Build the installable addon ZIP from the TOC, excluding development files."""
from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parents[1]
toc = root / 'damage.reader.skill.toc'
text = toc.read_text()
version = re.search(r'^## Version: (.+)$', text, re.M).group(1)
assert f'ns.version = "{version}"' in (root / 'Core.lua').read_text()
files = [toc] + [root / line.strip() for line in text.splitlines()
                 if line.strip() and not line.startswith('#')]
files += [root / name for name in ('README.md', 'CLASS_COVERAGE.md', 'COMPLIANCE.md', 'LICENSE')]
output = root / 'dist' / f'damage.reader.skill-{version}.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
    for path in files:
        assert path.is_file(), path
        archive.write(path, 'damage.reader.skill/' + path.relative_to(root).as_posix())
with ZipFile(output) as archive:
    assert archive.testzip() is None
    for path in files:
        assert archive.read('damage.reader.skill/' + path.relative_to(root).as_posix()) == path.read_bytes()
print(f'{output} ({len(files)} files, {output.stat().st_size} bytes); CRC and contents verified')
