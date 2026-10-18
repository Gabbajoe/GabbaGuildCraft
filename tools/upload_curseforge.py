#!/usr/bin/env python3
"""Upload a checked release ZIP using the CurseForge author API.

Token is read only from the environment. POSTs are not retried automatically
because a lost response could otherwise create duplicate uploaded files.
"""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import urllib.error
import urllib.request
import zipfile

from build_package import ROOT, version, supported_interfaces

API = 'https://wow.curseforge.com/api'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Do not forward the author token to a redirect target.
        return None


def request_json(path, token, body=None, content_type=None):
    headers = {'X-Api-Token': token, 'Accept': 'application/json', 'User-Agent': 'GabbaGuildCraft-release/1.0'}
    if content_type:
        headers['Content-Type'] = content_type
    request = urllib.request.Request(API + path, data=body, headers=headers)
    opener = urllib.request.build_opener(NoRedirect())
    try:
        with opener.open(request, timeout=120) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Response bodies can contain reflected request data; print status only.
        raise ValueError(f'CurseForge API returned HTTP {error.code} for {path}') from None
    except (urllib.error.URLError, TimeoutError):
        raise ValueError('CurseForge request failed; check network access and the dashboard before retrying') from None


def metadata(root, tag, notes, versions):
    release_version = version(root)
    if tag != 'v' + release_version:
        raise ValueError('Release tag does not match TOC version')
    game_versions = []
    for number in supported_interfaces(root):
        client_version = f'{number // 10000}.{number // 100 % 100}.{number % 100}'
        matches = [entry for entry in versions if entry.get('name') == client_version]
        if len(matches) != 1 or type(matches[0].get('id')) is not int or matches[0]['id'] <= 0:
            raise ValueError(f'Expected one exact CurseForge version ID for {client_version}; got {len(matches)}')
        game_versions.append(matches[0]['id'])
    return {'displayName': f'GabbaGuildCraft {release_version}', 'releaseType': ('beta' if '-beta.' in release_version or '-rc.' in release_version else 'alpha' if '-' in release_version else 'release'),
            'changelog': notes, 'changelogType': 'markdown', 'gameVersions': game_versions}


def multipart(data, archive):
    boundary = 'gabba-' + secrets.token_hex(16)
    marker = boundary.encode()
    content = (b'--' + marker + b'\r\nContent-Disposition: form-data; name="metadata"\r\n'
               b'Content-Type: application/json\r\n\r\n' + json.dumps(data).encode() + b'\r\n'
               b'--' + marker + b'\r\nContent-Disposition: form-data; name="file"; filename="'
               + archive.name.encode('ascii') + b'"\r\nContent-Type: application/zip\r\n\r\n'
               + archive.read_bytes() + b'\r\n--' + marker + b'--\r\n')
    return content, 'multipart/form-data; boundary=' + boundary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--notes', type=Path)
    parser.add_argument('--tag')
    parser.add_argument('--update-file', type=int, help='Correct only supported game versions on an existing CurseForge file.')
    parser.add_argument('--check', action='store_true', help='Check token and exact client-version lookup without uploading.')
    args = parser.parse_args()
    project = os.environ.get('CURSEFORGE_PROJECT_ID', '')
    token = os.environ.get('CURSEFORGE_API_TOKEN', '')
    try:
        if not project.isdigit() or int(project) <= 0 or not token:
            raise ValueError('CURSEFORGE_PROJECT_ID and CURSEFORGE_API_TOKEN must be configured')
        release_version = version(ROOT)
        if args.update_file is not None:
            if args.update_file <= 0 or args.check or args.archive or args.notes or args.tag:
                raise ValueError('--update-file requires a positive file ID and cannot be combined with upload/check arguments')
            data = metadata(ROOT, 'v' + release_version, '', request_json('/game/versions', token))
            boundary = 'gabba-' + secrets.token_hex(16)
            body = (f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\nContent-Type: application/json\r\n\r\n'
                    + json.dumps({'fileID': args.update_file, 'gameVersions': data['gameVersions']})
                    + f'\r\n--{boundary}--\r\n').encode()
            result = request_json(f'/projects/{project}/update-file', token, body, 'multipart/form-data; boundary=' + boundary)
            if result.get('id') != args.update_file:
                raise ValueError('Unexpected file ID in update response; check the dashboard before retrying')
            print(f"Corrected CurseForge file {args.update_file}: game version IDs {data['gameVersions']}")
            return
        if args.check:
            data = metadata(ROOT, 'v' + release_version, '', request_json('/game/versions', token))
            print(f'CurseForge author API reachable; project configured as {project}; client version IDs {data["gameVersions"]}. No upload performed.')
            return
        if args.archive is None or args.notes is None or args.tag is None:
            raise ValueError('--archive, --notes and --tag are required for uploads')
        if args.tag != 'v' + release_version:
            raise ValueError('Release tag does not match TOC version')
        if args.archive.name != f'GabbaGuildCraft-{release_version}.zip':
            raise ValueError('Archive name does not match TOC version')
        with zipfile.ZipFile(args.archive) as package:
            if package.testzip() is not None:
                raise ValueError('ZIP integrity check failed')
            if package.read('GabbaGuildCraft/GabbaGuildCraft.toc') != (ROOT / 'GabbaGuildCraft.toc').read_bytes():
                raise ValueError('Archive TOC does not match checkout')
        data = metadata(ROOT, args.tag, args.notes.read_text(), request_json('/game/versions', token))
        body, content_type = multipart(data, args.archive)
        result = request_json(f'/projects/{project}/upload-file', token, body, content_type)
        if not isinstance(result.get('id'), int) or result['id'] <= 0:
            raise ValueError('Upload response has no file ID; check dashboard before retrying')
        print(f'CurseForge project {project}: uploaded file ID {result["id"]}; moderation may still be pending.')
    except (ValueError, OSError, zipfile.BadZipFile) as error:
        parser.error(str(error))


if __name__ == '__main__':
    main()
