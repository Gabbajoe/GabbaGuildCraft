#!/usr/bin/env python3
"""Build a reproducible WoW ZIP independently of the checkout folder name."""
import argparse
import hashlib
from pathlib import Path, PurePosixPath
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = (
    'GabbaGuildCraft.toc', 'Locale.lua', 'Groups.lua', 'Export.lua', 'HTML.lua', 'Effects.lua',
    'Recipes.lua', 'UI.lua', 'Minimap.lua', 'Assets/Minimap.tga',
    'README.md', 'README.en.md', 'CHANGELOG.md', 'LICENSE',
)



def version(root=ROOT):
    match = re.search(r'^## Version: (\d+\.\d+\.\d+(?:-(?:dev|alpha|beta|rc)\.\d+)?)$',
                      (root / 'GabbaGuildCraft.toc').read_text(), re.MULTILINE)
    if not match:
        raise ValueError('TOC must contain major.minor.patch with an optional dev/alpha/beta/rc suffix')
    return match.group(1)


def supported_interfaces(root=ROOT):
    match = re.search(r'^## Interface: (\d+(?:,\s*\d+)*)$', (root / 'GabbaGuildCraft.toc').read_text(), re.MULTILINE)
    if not match:
        raise ValueError('Missing TOC interface')
    values = [int(value.strip()) for value in match.group(1).split(',')]
    if len(values) != len(set(values)) or any(value // 10000 != 1 for value in values):
        raise ValueError('Only the Classic Era client for WoW Classic Hardcore is supported')
    return values


def package_files(root=ROOT):
    supported_interfaces(root)
    files = list(RUNTIME)
    toc_files = [line.strip() for line in (root / 'GabbaGuildCraft.toc').read_text().splitlines()
                 if line.strip() and not line.lstrip().startswith('#')]
    if any(name not in files for name in toc_files):
        raise ValueError('TOC references a file missing from the package manifest')
    if len(set(files)) != len(files):
        raise ValueError('Duplicate package entry')
    for name in files:
        path = PurePosixPath(name)
        if path.is_absolute() or '..' in path.parts or '\\' in name:
            raise ValueError('Unsafe package path: ' + name)
        target = root / name
        if target.is_symlink() or not target.resolve().is_relative_to(root.resolve()):
            raise ValueError('Package path escapes checkout: ' + name)
        if not target.is_file():
            raise ValueError('Missing package file: ' + name)
    return sorted(files)


def build(root, output_dir, tag=None):
    release_version = version(root)
    if tag is not None and tag != 'v' + release_version:
        raise ValueError(f'Tag {tag!r} does not match TOC version v{release_version}')
    files = package_files(root)
    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / f'GabbaGuildCraft-{release_version}.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for name in files:
            info = zipfile.ZipInfo('GabbaGuildCraft/' + name, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            package.writestr(info, (root / name).read_bytes(), compresslevel=9)
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise ValueError('ZIP integrity check failed')
    checksum = archive.with_suffix('.zip.sha256')
    checksum.write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
    return release_version, archive, checksum, len(files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT / "dist")
    parser.add_argument('--tag', help='Require tag to match TOC version, e.g. v1.0.0')
    parser.add_argument('--github-output', type=Path, help='Append release paths to GitHub step outputs')
    args = parser.parse_args()
    try:
        release_version = version(ROOT)
        notes = ROOT / 'curseforge' / f'CHANGELOG-{release_version}.md'
        if args.tag and not notes.is_file():
            raise ValueError('Missing release notes: ' + str(notes))
        release_version, archive, checksum, count = build(ROOT, args.output_dir, args.tag)
        if args.github_output:
            with args.github_output.open('a') as output:
                output.write(f'version={release_version}\narchive={archive.resolve()}\n')
                output.write(f'checksum={checksum.resolve()}\nnotes={notes.resolve()}\n')
    except ValueError as error:
        parser.error(str(error))
    print(archive, '-', count, 'files,', archive.stat().st_size, 'bytes')


if __name__ == '__main__':
    main()
