#!/usr/bin/env python3
"""Local thread editor server. Run from repo root: python scripts/editor/server.py"""

import json
import os
import re
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import yaml  # PyYAML

REPO_ROOT = Path(__file__).parent.parent.parent
FRAGMENTS_DIR = REPO_ROOT / '_fragments'
THREADS_DIR = REPO_ROOT / '_threads'
EDITOR_HTML = Path(__file__).parent / 'editor.html'
PORT = 8765


# ── Front-matter helpers ────────────────────────────────────────────────────

def parse_front_matter(raw: str) -> tuple[dict, str]:
    """Split Jekyll front matter from body. Returns (fm_dict, body_str)."""
    if not raw.startswith('---'):
        return {}, raw
    parts = raw.split('---', 2)
    if len(parts) < 3:
        return {}, raw
    fm = yaml.safe_load(parts[1]) or {}
    return fm, parts[2]


def serialize_front_matter(fm: dict, body: str) -> str:
    """Serialize front matter dict + body back to Jekyll file string."""
    fm_str = yaml.dump(fm, allow_unicode=True, default_flow_style=False,
                       sort_keys=False).strip()
    return f"---\n{fm_str}\n---\n\n{body.strip()}\n"


# ── File helpers ─────────────────────────────────────────────────────────────

def read_collection(directory: Path, skip_gitkeep: bool = True) -> list[dict]:
    items = []
    for path in sorted(directory.glob('*.md')):
        if skip_gitkeep and path.name == '.gitkeep':
            continue
        raw = path.read_text(encoding='utf-8')
        fm, body = parse_front_matter(raw)
        items.append({'slug': path.stem, 'raw': raw, 'fm': fm, 'body': body.strip()})
    return items


# ── HTTP handler ─────────────────────────────────────────────────────────────

class EditorHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # suppress default access log
        pass

    def send_json(self, data: dict, status: int = 200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, path: Path):
        content = path.read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def read_body(self) -> dict:
        length = int(self.headers.get('Content-Length', 0))
        return json.loads(self.rfile.read(length)) if length else {}

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip('/')

        if path in ('', '/'):
            self.send_html(EDITOR_HTML)
            return

        if path == '/api/fragments':
            items = read_collection(FRAGMENTS_DIR)
            self.send_json({'fragments': items})

        elif path == '/api/threads':
            items = read_collection(THREADS_DIR)
            self.send_json({'threads': items})

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip('/')
        body = self.read_body()

        try:
            if path == '/api/threads/save':
                slug = body['slug']
                content = body['content']
                target = THREADS_DIR / f'{slug}.md'
                target.write_text(content, encoding='utf-8')
                self.send_json({'ok': True})

            elif path == '/api/fragments/save':
                frag_id = body['id']
                content = body['content']
                # Validate ID format to prevent path traversal
                if not re.match(r'^[\w\-]+$', frag_id):
                    self.send_json({'error': 'Invalid fragment id'}, 400)
                    return
                target = FRAGMENTS_DIR / f'{frag_id}.md'
                target.write_text(content, encoding='utf-8')
                self.send_json({'ok': True})

            elif path == '/api/fragments/create':
                # Create a new fragment from the editor (not Telegram)
                import random, string
                from datetime import datetime
                import pytz
                tz = pytz.timezone('Asia/Taipei')
                now = datetime.now(tz)
                ms = now.microsecond // 1000
                rand = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))
                frag_id = f"{now.strftime('%Y%m%d-%H%M%S')}-{ms:03d}-{rand}"
                content = body.get('content', '').strip()
                frag_type = body.get('type', 'thought')
                source = body.get('source', '')
                page = body.get('page', '')
                tags = body.get('tags', [])
                fm: dict = {'id': frag_id, 'type': frag_type}
                if frag_type == 'quote' and source:
                    fm['source'] = source
                    if page:
                        fm['page'] = page
                fm['date'] = now.strftime('%Y-%m-%d %H:%M:%S')
                fm['tags'] = tags
                raw = serialize_front_matter(fm, content)
                (FRAGMENTS_DIR / f'{frag_id}.md').write_text(raw, encoding='utf-8')
                self.send_json({'ok': True, 'id': frag_id})

            elif path == '/api/fragments/delete':
                frag_id = body['id']
                if not re.match(r'^[\w\-]+$', frag_id):
                    self.send_json({'error': 'Invalid fragment id'}, 400)
                    return
                target = FRAGMENTS_DIR / f'{frag_id}.md'
                if target.exists():
                    target.unlink()
                self.send_json({'ok': True})

            elif path == '/api/threads/create':
                slug = body['slug']
                title = body['title']
                description = body.get('description', '')
                if not re.match(r'^[a-z0-9\-]+$', slug):
                    self.send_json({'error': 'Invalid slug'}, 400)
                    return
                from datetime import date
                today = date.today().isoformat()
                fm = {'title': title, 'description': description,
                      'layout': 'thread', 'created': today, 'updated': today,
                      'fragment_ids': []}
                raw = serialize_front_matter(fm, '')
                target = THREADS_DIR / f'{slug}.md'
                if target.exists():
                    self.send_json({'error': 'Thread already exists'}, 409)
                    return
                target.write_text(raw, encoding='utf-8')
                self.send_json({'ok': True, 'slug': slug})

            else:
                self.send_response(404)
                self.end_headers()

        except Exception as e:
            self.send_json({'error': str(e)}, 500)

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()


if __name__ == '__main__':
    FRAGMENTS_DIR.mkdir(exist_ok=True)
    THREADS_DIR.mkdir(exist_ok=True)
    server = HTTPServer(('127.0.0.1', PORT), EditorHandler)
    print(f'✅ 脈絡串編輯器啟動：http://localhost:{PORT}')
    print('   停止：Ctrl+C')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\n⏹ 已停止')
