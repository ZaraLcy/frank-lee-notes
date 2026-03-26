# Fragment & Thread System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Zettelkasten-style fragment library and thread system to the existing Jekyll microblog, enabling Telegram-based capture and web-based visual organization.

**Architecture:** Telegram messages are routed to a new `telegram-fragment` GitHub Actions event, which writes atomic fragment files to `_fragments/`. Threads in `_threads/` reference fragments by ID and are rendered as static Jekyll pages. A Vercel-backed web editor provides drag-and-drop thread organization with a slide-out fragment library drawer.

**Tech Stack:** TypeScript (Vercel), Python 3 (GitHub Actions), Jekyll (Liquid templates), Vanilla JS (editor UI), GitHub Contents API, pytz

---

## File Map

### New files
- `_fragments/.gitkeep` — collection directory
- `_threads/.gitkeep` — collection directory
- `scripts/telegram/create_fragment.py` — parses Telegram message, writes `_fragments/` file
- `tests/test_create_fragment.py` — unit tests for parser
- `.github/workflows/telegram-fragment.yml` — GitHub Actions workflow
- `api/thread-editor.ts` — Vercel serverless function (auth + GitHub API proxy)
- `pages/threads/edit.html` — editor frontend (self-contained HTML/CSS/JS)
- `_layouts/thread.html` — public thread page layout
- `_pages/threads.md` — threads index page
- `assets/css/thread.css` — thread page + editor styles

### Modified files
- `_config.yml` — add `fragments` and `threads` collections
- `api/telegram-webhook.ts` — change event type to `telegram-fragment`, update payload
- `.github/workflows/telegram-bot.yml` — disable (rename to `.disabled`)
- `assets/css/microblog.css` — warm-refined polish

---

## Phase 1: Telegram → Fragment Pipeline

### Task 1: Jekyll Collection Configuration

**Files:**
- Modify: `_config.yml`
- Create: `_fragments/.gitkeep`
- Create: `_threads/.gitkeep`

- [ ] **Step 1: Add collections to `_config.yml`**

Find the existing `collections:` block and add two new entries:

```yaml
collections:
  pages:
    output: true
    permalink: /:collection/:path/
  others:
    output: true
    permalink: /:collection/:path/
  fragments:
    output: false          # fragments have no public pages
  threads:
    output: true
    permalink: /脈絡串/:name/
```

- [ ] **Step 2: Create collection directories**

```bash
mkdir -p _fragments _threads
touch _fragments/.gitkeep _threads/.gitkeep
```

- [ ] **Step 3: Verify Jekyll builds without error**

```bash
bundle exec jekyll build 2>&1 | tail -5
```
Expected: `...done in X seconds.` with no errors.

- [ ] **Step 4: Commit**

```bash
git add _config.yml _fragments/.gitkeep _threads/.gitkeep
git commit -m "feat: add fragments and threads Jekyll collections"
```

---

### Task 2: Fragment Creation Script

**Files:**
- Create: `scripts/telegram/create_fragment.py`
- Create: `tests/test_create_fragment.py`

- [ ] **Step 1: Write failing tests**

Create `tests/test_create_fragment.py`:

```python
import pytest, sys
sys.path.insert(0, 'scripts/telegram')
from create_fragment import parse_fragment_message, generate_fragment_id

class TestParseThought:
    def test_plain_thought(self):
        result = parse_fragment_message("真正的謙遜不是貶低自己，而是清空自我。")
        assert result['type'] == 'thought'
        assert result['content'] == "真正的謙遜不是貶低自己，而是清空自我。"
        assert 'source' not in result

    def test_thought_with_chinese_tags(self):
        result = parse_fragment_message("謙遜是美德 #道家 #哲學")
        assert result['tags'] == ['道家', '哲學']
        assert '道家' not in result['content']

    def test_thought_with_no_tags(self):
        result = parse_fragment_message("一個沒有標籤的想法")
        assert result['tags'] == []

class TestParseQuote:
    def test_quote_with_page(self):
        result = parse_fragment_message("📖 塔羅冥想 p.114\n這是引文內容。")
        assert result['type'] == 'quote'
        assert result['source'] == '塔羅冥想'
        assert result['page'] == '114'
        assert result['content'] == '這是引文內容。'

    def test_quote_without_page(self):
        result = parse_fragment_message("📖 道德經\n致虛極，守靜篤。")
        assert result['type'] == 'quote'
        assert result['source'] == '道德經'
        assert 'page' not in result

    def test_quote_with_chapter(self):
        result = parse_fragment_message("📖 道德經 第十六章\n致虛極，守靜篤。")
        assert result['type'] == 'quote'
        assert result['page'] == '第十六章'

    def test_quote_with_tags(self):
        result = parse_fragment_message("📖 塔羅冥想 p.201\n靈感不是靠意志獲得的。 #靈性")
        assert result['tags'] == ['靈性']
        assert '#靈性' not in result['content']

class TestGenerateId:
    def test_id_format(self):
        frag_id = generate_fragment_id()
        parts = frag_id.split('-')
        assert len(parts) == 4
        assert len(parts[0]) == 8   # YYYYMMDD
        assert len(parts[1]) == 6   # HHMMSS
        assert len(parts[2]) == 3   # milliseconds
        assert len(parts[3]) == 4   # random hex

    def test_ids_are_unique(self):
        ids = [generate_fragment_id() for _ in range(10)]
        assert len(set(ids)) == 10
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
python -m pytest tests/test_create_fragment.py -v 2>&1 | head -20
```
Expected: `ModuleNotFoundError` — script does not exist yet.

- [ ] **Step 3: Implement `scripts/telegram/create_fragment.py`**

```python
#!/usr/bin/env python3
"""Fragment creation script: Telegram message -> _fragments/<id>.md"""

import os, re, json, random, string
from datetime import datetime
import pytz


def generate_fragment_id() -> str:
    tz = pytz.timezone('Asia/Taipei')
    now = datetime.now(tz)
    ms = now.microsecond // 1000
    rand = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))
    return f"{now.strftime('%Y%m%d-%H%M%S')}-{ms:03d}-{rand}"


def parse_fragment_message(message: str) -> dict:
    lines = message.strip().split('\n')
    first_line = lines[0].strip()
    tags = re.findall(r'#([\w\u4e00-\u9fff]+)', message)
    clean_message = re.sub(r'#[\w\u4e00-\u9fff]+', '', message).strip()
    clean_lines = clean_message.split('\n')

    if first_line.startswith('📖'):
        source_line = re.sub(r'^📖\s*', '', clean_lines[0]).strip()
        page_match = re.search(r'\s+(p\.(\d+)|第.+[章節])$', source_line)
        if page_match:
            page = page_match.group(2) if page_match.group(2) else page_match.group(1)
            source = source_line[:page_match.start()].strip()
        else:
            page, source = None, source_line.strip()
        content = '\n'.join(clean_lines[1:]).strip()
        result = {'type': 'quote', 'source': source, 'content': content, 'tags': tags}
        if page:
            result['page'] = page
        return result
    else:
        return {'type': 'thought', 'content': clean_message, 'tags': tags}


def build_front_matter(frag_id: str, parsed: dict, date_str: str) -> str:
    lines = ['---', f'id: {frag_id}', f'type: {parsed["type"]}']
    if parsed['type'] == 'quote':
        lines.append(f'source: "{parsed["source"]}"')
        if 'page' in parsed:
            lines.append(f'page: "{parsed["page"]}"')
    lines += [f'date: {date_str}',
              f'tags: {json.dumps(parsed["tags"], ensure_ascii=False)}',
              '---']
    return '\n'.join(lines)


def create_fragment() -> bool:
    message = os.environ.get('TELEGRAM_MESSAGE', '')
    if not message:
        print("❌ 未收到訊息內容")
        return False
    tz = pytz.timezone('Asia/Taipei')
    now = datetime.now(tz)
    frag_id = generate_fragment_id()
    parsed = parse_fragment_message(message)
    front_matter = build_front_matter(frag_id, parsed, now.strftime('%Y-%m-%d %H:%M:%S'))
    filename = f"_fragments/{frag_id}.md"
    os.makedirs('_fragments', exist_ok=True)
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(f"{front_matter}\n\n{parsed['content']}\n")
        print(f"✅ 片段已建立：{filename}")
        with open('fragment_id.txt', 'w') as f:
            f.write(frag_id)
        return True
    except Exception as e:
        print(f"❌ 建立片段失敗：{e}")
        return False


if __name__ == '__main__':
    exit(0 if create_fragment() else 1)
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
python -m pytest tests/test_create_fragment.py -v
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/telegram/create_fragment.py tests/test_create_fragment.py
git commit -m "feat: add fragment creation script with tests"
```

---

### Task 3: GitHub Actions Workflow for Fragments

**Files:**
- Create: `.github/workflows/telegram-fragment.yml`

- [ ] **Step 1: Create `.github/workflows/telegram-fragment.yml`**

```yaml
name: Telegram Fragment Capture

on:
  repository_dispatch:
    types: [telegram-fragment]

jobs:
  create-fragment:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GH_PAT }}

      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - run: pip install pytz

      - name: Create fragment
        env:
          TELEGRAM_MESSAGE: ${{ github.event.client_payload.message }}
          TELEGRAM_CHAT_ID: ${{ github.event.client_payload.chat_id }}
        run: python scripts/telegram/create_fragment.py

      - name: Commit and push
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"
          git add _fragments/
          if git diff --staged --quiet; then
            echo "No changes to commit"
            exit 1
          fi
          FRAG_ID=$(cat fragment_id.txt)
          git commit -m "📝 New fragment: ${FRAG_ID}"
          git push

      - name: Send success notification
        if: success()
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ github.event.client_payload.chat_id }}
          MESSAGE_ID: ${{ github.event.client_payload.message_id }}
        run: |
          curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
              --arg chat_id "${TELEGRAM_CHAT_ID}" \
              --arg text "✅ 片段已收藏至片段庫" \
              --argjson reply_id "${MESSAGE_ID}" \
              '{chat_id: $chat_id, text: $text, reply_to_message_id: $reply_id}')"

      - name: Send failure notification
        if: failure()
        env:
          TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: ${{ github.event.client_payload.chat_id }}
        run: |
          curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
              --arg chat_id "${TELEGRAM_CHAT_ID}" \
              --arg text "❌ 片段收藏失敗，請檢查 GitHub Actions 日誌" \
              '{chat_id: $chat_id, text: $text}')"
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/telegram-fragment.yml
git commit -m "feat: add GitHub Actions workflow for fragment capture"
```

---

### Task 4: Update Telegram Webhook

**Files:**
- Modify: `api/telegram-webhook.ts`
- Rename: `.github/workflows/telegram-bot.yml` → `telegram-bot.yml.disabled`

- [ ] **Step 1: Update event dispatch in `api/telegram-webhook.ts`**

Replace (lines ~67-75):
```typescript
          event_type: 'telegram-micro-post',
          client_payload: {
            message: messageText,
            chat_id: chatId,
            message_id: messageId,
          },
```

With:
```typescript
          event_type: 'telegram-fragment',
          client_payload: {
            message: messageText,
            chat_id: chatId,
            message_id: messageId,
            message_type: messageText.startsWith('📖') ? 'quote' : 'thought',
          },
```

- [ ] **Step 2: Update the Telegram reply text**

Replace:
```typescript
          text: '⏳ 正在處理你的微網誌...\n預計 30 秒內完成發布',
```
With:
```typescript
          text: '⏳ 正在收藏至片段庫...',
```

- [ ] **Step 3: Disable old workflow**

```bash
mv .github/workflows/telegram-bot.yml .github/workflows/telegram-bot.yml.disabled
```

- [ ] **Step 4: Commit and push**

```bash
git add api/telegram-webhook.ts .github/workflows/telegram-bot.yml.disabled
git commit -m "feat: route Telegram messages to fragment pipeline"
git push origin master
```

- [ ] **Step 5: End-to-end smoke test**

Send to the Telegram bot:
```
📖 塔羅冥想 p.114
服務是隱修之道的核心精神。
```
Expected: GitHub Actions `telegram-fragment` workflow runs; new file in `_fragments/`.

---

## Phase 2: Public Thread Pages

### Task 5: Thread Page Layout and Index

**Files:**
- Create: `_layouts/thread.html`
- Create: `assets/css/thread.css`
- Create: `_pages/threads.md`
- Create: `_threads/sample-thread.md` (test fixture)

- [ ] **Step 1: Create `assets/css/thread.css`**

```css
/* ================================================
   脈絡串公開頁面樣式
   ================================================ */
.thread-page { max-width: 680px; margin: 40px auto; padding: 0 20px; font-family: Georgia, serif; }
.thread-header { margin-bottom: 32px; padding-bottom: 20px; border-bottom: 2px solid #f0e6dc; }
.thread-label { font-size: 11px; color: #a0826d; letter-spacing: 0.1em; text-transform: uppercase; margin-bottom: 8px; }
.thread-title { font-size: 24px; color: #8b5a3c; font-weight: 600; line-height: 1.3; margin: 0 0 10px 0; }
.thread-description { font-size: 14px; color: #a0826d; line-height: 1.7; margin-bottom: 12px; }
.thread-meta { font-size: 11px; color: #b8977e; display: flex; gap: 10px; }
.thread-meta span + span::before { content: '·'; margin-right: 10px; }
.thread-timeline { display: flex; flex-direction: column; }
.thread-fragment { display: flex; gap: 16px; }
.thread-fragment-node { display: flex; flex-direction: column; align-items: center; flex-shrink: 0; width: 12px; }
.thread-fragment-dot { width: 10px; height: 10px; border-radius: 50%; margin-top: 6px; flex-shrink: 0; }
.thread-fragment-dot.dot-quote { background: #d4a574; }
.thread-fragment-dot.dot-thought { background: #c67d4e; }
.thread-fragment-line { width: 1px; flex: 1; background: #f0e6dc; margin-top: 4px; min-height: 20px; }
.thread-fragment:last-child .thread-fragment-line { display: none; }
.thread-fragment-body { flex: 1; padding-bottom: 24px; }
.thread-fragment-source { font-size: 11px; color: #c67d4e; margin-bottom: 6px; }
.thread-fragment-date { font-size: 11px; color: #a0826d; margin-bottom: 6px; }
.thread-fragment-content.content-quote { font-size: 15px; color: #5a4a3a; line-height: 1.85; font-style: italic; border-left: 3px solid #f0e6dc; padding-left: 16px; margin: 0; }
.thread-fragment-content.content-thought { font-size: 15px; color: #5a4a3a; line-height: 1.85; margin: 0; }
.thread-footer { margin-top: 8px; padding-top: 20px; border-top: 1px solid #f0e6dc; display: flex; justify-content: space-between; align-items: center; }
.thread-footer-back { font-size: 13px; color: #c67d4e; text-decoration: none; }
.thread-footer-back:hover { text-decoration: underline; }
.thread-footer-status { font-size: 11px; color: #b8977e; }
@media (max-width: 600px) {
  .thread-page { margin: 20px auto; }
  .thread-title { font-size: 20px; }
  .thread-fragment-content.content-quote, .thread-fragment-content.content-thought { font-size: 14px; }
}
```

- [ ] **Step 2: Create `_layouts/thread.html`**

```html
---
layout: post
---
<link rel="stylesheet" href="{{ '/assets/css/thread.css' | relative_url }}">
<div class="thread-page">
  <div class="thread-header">
    <div class="thread-label">脈絡串</div>
    <h1 class="thread-title">{{ page.title }}</h1>
    {% if page.description %}<p class="thread-description">{{ page.description }}</p>{% endif %}
    <div class="thread-meta">
      <span>{{ page.fragment_ids.size }} 個片段</span>
      <span>持續更新中</span>
      <span>最後更新 {{ page.updated }}</span>
    </div>
  </div>
  <div class="thread-timeline">
    {% for frag_id in page.fragment_ids %}
      {% assign frag = site.fragments | where: "id", frag_id | first %}
      {% if frag %}
      <div class="thread-fragment">
        <div class="thread-fragment-node">
          <div class="thread-fragment-dot dot-{{ frag.type }}"></div>
          <div class="thread-fragment-line"></div>
        </div>
        <div class="thread-fragment-body">
          {% if frag.type == "quote" %}
            <div class="thread-fragment-source">📖 {{ frag.source }}{% if frag.page %} p.{{ frag.page }}{% endif %}</div>
          {% else %}
            <div class="thread-fragment-date">✏️ 想法 · {{ frag.date | date: "%Y-%m-%d" }}</div>
          {% endif %}
          <div class="thread-fragment-content content-{{ frag.type }}">{{ frag.content }}</div>
        </div>
      </div>
      {% endif %}
    {% endfor %}
  </div>
  <div class="thread-footer">
    <a href="{{ '/脈絡串/' | relative_url }}" class="thread-footer-back">← 所有脈絡串</a>
    <span class="thread-footer-status">持續更新中 · 無終點</span>
  </div>
</div>
```

- [ ] **Step 3: Create `_pages/threads.md`**

```markdown
---
layout: home
title: 📚 脈絡串
permalink: /脈絡串/
---
<link rel="stylesheet" href="{{ '/assets/css/thread.css' | relative_url }}">
<div style="max-width:680px;margin:40px auto;padding:0 20px;font-family:Georgia,serif;">
  <div style="margin-bottom:32px;padding-bottom:20px;border-bottom:2px solid #f0e6dc;">
    <h1 style="font-size:22px;color:#8b5a3c;margin-bottom:8px;">📚 脈絡串</h1>
    <p style="font-size:14px;color:#a0826d;">把零散的書摘與想法，串成有脈絡的思考線索。</p>
  </div>
  {% assign threads = site.threads | sort: "updated" | reverse %}
  {% for thread in threads %}
  <a href="{{ thread.url | relative_url }}" style="display:block;text-decoration:none;margin-bottom:16px;">
    <div style="background:linear-gradient(135deg,#fffbf5,#fef8f0);border-left:4px solid #d4a574;border-radius:8px;padding:16px 20px;">
      <div style="font-size:16px;color:#8b5a3c;font-weight:600;margin-bottom:4px;">{{ thread.title }}</div>
      {% if thread.description %}<div style="font-size:13px;color:#a0826d;margin-bottom:8px;">{{ thread.description }}</div>{% endif %}
      <div style="font-size:11px;color:#b8977e;">{{ thread.fragment_ids.size }} 個片段 · 更新於 {{ thread.updated }}</div>
    </div>
  </a>
  {% endfor %}
</div>
```

- [ ] **Step 4: Create test fixture `_threads/sample-thread.md`**

```markdown
---
title: "隱修與服務"
description: "關於放下自我意志、以服務為本的靈性實踐"
layout: thread
created: 2026-03-25
updated: 2026-03-25
fragment_ids: []
---
```

- [ ] **Step 5: Build and verify**

```bash
bundle exec jekyll build 2>&1 | tail -5
# Check output
ls _site/脈絡串/
```
Expected: `_site/脈絡串/` directory exists with `index.html` and `sample-thread/index.html`.

- [ ] **Step 6: Commit**

```bash
git add _layouts/thread.html assets/css/thread.css _pages/threads.md _threads/sample-thread.md
git commit -m "feat: add public thread page layout and threads index"
```

---

## Phase 3: Thread Editor

### Task 6: Thread Editor Backend (Vercel)

**Files:**
- Create: `api/thread-editor.ts`

- [ ] **Step 1: Add `EDITOR_PASSWORD` to Vercel**

In Vercel dashboard → Project Settings → Environment Variables, add:
- Key: `EDITOR_PASSWORD`
- Value: a strong password (keep it safe)

- [ ] **Step 2: Create `api/thread-editor.ts`**

```typescript
import { VercelRequest, VercelResponse } from '@vercel/node';

const GITHUB_OWNER = process.env.GITHUB_OWNER || 'ZaraLcy';
const GITHUB_REPO = process.env.GITHUB_REPO || 'frank-lee-notes';
const GITHUB_TOKEN = process.env.GH_PAT;
const EDITOR_PASSWORD = process.env.EDITOR_PASSWORD;

function isAuthenticated(req: VercelRequest): boolean {
  const cookie = req.headers.cookie || '';
  const match = cookie.match(/editor_session=([^;]+)/);
  if (!match) return false;
  return Buffer.from(match[1], 'base64').toString('utf-8') === EDITOR_PASSWORD;
}

function setSessionCookie(res: VercelResponse, password: string): void {
  const token = Buffer.from(password).toString('base64');
  res.setHeader('Set-Cookie',
    `editor_session=${token}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=86400`);
}

async function ghGet(path: string): Promise<any> {
  const r = await fetch(
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${path}`,
    { headers: { Authorization: `token ${GITHUB_TOKEN}`, Accept: 'application/vnd.github.v3+json' } }
  );
  if (!r.ok) throw new Error(`GitHub GET ${path}: ${r.status}`);
  return r.json();
}

async function ghPut(path: string, content: string, sha: string | null, message: string): Promise<any> {
  const body: any = { message, content: Buffer.from(content, 'utf-8').toString('base64') };
  if (sha) body.sha = sha;
  const r = await fetch(
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${path}`,
    { method: 'PUT', headers: { Authorization: `token ${GITHUB_TOKEN}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' }, body: JSON.stringify(body) }
  );
  if (r.status === 409) throw new Error('CONFLICT: File modified elsewhere. Refresh and retry.');
  if (!r.ok) throw new Error(`GitHub PUT ${path}: ${r.status} — ${await r.text()}`);
  return r.json();
}

async function ghDelete(path: string, sha: string, message: string): Promise<void> {
  const r = await fetch(
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${path}`,
    { method: 'DELETE', headers: { Authorization: `token ${GITHUB_TOKEN}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' }, body: JSON.stringify({ message, sha }) }
  );
  if (!r.ok) throw new Error(`GitHub DELETE ${path}: ${r.status}`);
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', req.headers.origin || '');
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const { action } = req.query;

  if (action === 'login') {
    if (req.method !== 'POST') return res.status(405).end();
    if (!req.body?.password || req.body.password !== EDITOR_PASSWORD)
      return res.status(401).json({ error: '密碼錯誤' });
    setSessionCookie(res, req.body.password);
    return res.status(200).json({ ok: true });
  }

  if (!isAuthenticated(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    switch (action) {

      case 'list-fragments': {
        const files = await ghGet('_fragments');
        const fragments = await Promise.all(
          files.filter((f: any) => f.name.endsWith('.md') && f.name !== '.gitkeep')
               .map(async (f: any) => {
                 const file = await ghGet(`_fragments/${f.name}`);
                 return { id: f.name.replace('.md', ''), sha: file.sha,
                           raw: Buffer.from(file.content, 'base64').toString('utf-8') };
               })
        );
        return res.status(200).json({ fragments });
      }

      case 'list-threads': {
        const files = await ghGet('_threads');
        const threads = await Promise.all(
          files.filter((f: any) => f.name.endsWith('.md') && f.name !== '.gitkeep')
               .map(async (f: any) => {
                 const file = await ghGet(`_threads/${f.name}`);
                 return { slug: f.name.replace('.md', ''), sha: file.sha,
                           raw: Buffer.from(file.content, 'base64').toString('utf-8') };
               })
        );
        return res.status(200).json({ threads });
      }

      case 'save-thread': {
        if (req.method !== 'POST') return res.status(405).end();
        const { slug, content, sha } = req.body;
        const result = await ghPut(`_threads/${slug}.md`, content, sha, `Update thread: ${slug}`);
        return res.status(200).json({ ok: true, sha: result.content?.sha });
      }

      case 'save-fragment': {
        if (req.method !== 'POST') return res.status(405).end();
        const { id, content, sha } = req.body;
        const result = await ghPut(`_fragments/${id}.md`, content, sha, `Update fragment: ${id}`);
        return res.status(200).json({ ok: true, sha: result.content?.sha });
      }

      case 'delete-fragment': {
        if (req.method !== 'POST') return res.status(405).end();
        const { id, sha } = req.body;
        await ghDelete(`_fragments/${id}.md`, sha, `Delete fragment: ${id}`);
        return res.status(200).json({ ok: true });
      }

      default:
        return res.status(400).json({ error: 'Unknown action' });
    }
  } catch (e: any) {
    const isConflict = e.message?.startsWith('CONFLICT');
    return res.status(isConflict ? 409 : 500).json({ error: e.message });
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add api/thread-editor.ts
git commit -m "feat: add thread editor Vercel backend with auth and GitHub API proxy"
```

---

### Task 7: Thread Editor Frontend

**Files:**
- Create: `pages/threads/edit.html`

The editor is a self-contained HTML page (no build step). All data operations go through `api/thread-editor.ts`.

- [ ] **Step 1: Create `pages/threads/` directory**

```bash
mkdir -p pages/threads
```

- [ ] **Step 2: Create `pages/threads/edit.html`**

The file is large (~300 lines). Key sections:

**HTML structure:**
```html
---
layout: null
permalink: /threads/edit/
---
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8">
  <title>脈絡串編輯器</title>
  <!-- CSS: login, sidebar, main area, library drawer, toast -->
</head>
<body>
  <!-- #login-screen: password form -->
  <!-- #app: three-column layout
       .sidebar | .main-area | .library-drawer -->
  <!-- #toast: status notification -->
  <!-- <script>: all editor logic -->
</body>
</html>
```

**Key JavaScript functions to implement:**

| Function | Purpose |
|---|---|
| `login()` | POST to `?action=login`, set session cookie |
| `loadAll()` | Fetch fragments + threads in parallel |
| `parseFrontMatter(raw)` | Parse Jekyll YAML front matter to object |
| `buildFrontMatter(parsed, body)` | Serialize object back to YAML front matter |
| `selectThread(slug)` | Set active thread, re-render list + library |
| `renderThreadList()` | Populate left sidebar |
| `renderFragmentList()` | Render current thread's fragments with drag handles |
| `renderLibrary(query)` | Render library drawer with thread-membership badges |
| `reorderFragment(from, to)` | Swap fragment_ids in thread, call `saveThread()` |
| `addFragmentToEnd(fragId)` | Append ID to thread's fragment_ids, save |
| `addFragmentAtIndex(fragId, idx)` | Insert ID at position, save |
| `removeFragment(fragId)` | Remove ID from thread's fragment_ids, save |
| `saveThread()` | PUT to `?action=save-thread`, handle 409 |
| `saveFragmentContent(id, text)` | PUT to `?action=save-fragment` |
| `createThread()` | Prompt for title; generate slug via `title.toLowerCase().replace(/[^a-z0-9]+/g, '-')` (no pypinyin needed — simple ASCII slug); PUT new thread file |\n| `publishAsPost()` | Deferred to Phase 4 — show "即將推出" toast for now |
| `shareThread()` | Copy public URL to clipboard |
| `toggleLibrary()` | Show/hide right drawer with CSS transition |
| `showToast(msg)` | Display temporary bottom notification |

**Drag-and-drop events:**
- Fragment cards in list: `dragstart` sets `draggingListIdx`; `drop` calls `reorderFragment()`
- Library items: `dragstart` sets `draggingFragId`; drop on list calls `addFragmentAtIndex()` or `addFragmentToEnd()`

**Security note:** Fragment content from GitHub is rendered using `textContent` (not `innerHTML`) wherever possible. The one exception is the fragment list rendering which uses `innerHTML` for the card structure — this is acceptable because content originates from the owner's own Telegram messages, not arbitrary user input.

See the brainstorming session mockups in `.superpowers/brainstorm/` for the full visual design reference.

- [ ] **Step 3: Commit**

```bash
git add pages/threads/edit.html
git commit -m "feat: add thread editor frontend with drag-and-drop UI"
```

- [ ] **Step 4: Push and verify deployment**

```bash
git push origin master
```

After Vercel deploys (~2 min):
1. Visit `https://frank-lee-notes.vercel.app/threads/edit/`
2. Login with `EDITOR_PASSWORD`
3. Confirm fragments and threads load
4. Open library drawer, drag a fragment into the thread
5. Refresh — verify order persisted

---

### Task 8: CSS Polish

**Files:**
- Modify: `assets/css/microblog.css`

- [ ] **Step 1: Apply warm-refined polish**

In `assets/css/microblog.css`, make these targeted updates:

```css
/* More refined card border */
.micro-card {
  border-left-width: 3px;   /* was 4px */
  border-radius: 10px;      /* was 8px */
}

/* Softer hover shadow */
.micro-card:hover {
  box-shadow: 0 6px 16px rgba(139, 90, 60, 0.12);
}

/* Tag letter-spacing */
.micro-tag, .micro-post-tag {
  letter-spacing: 0.03em;
}
```

- [ ] **Step 2: Commit and push**

```bash
git add assets/css/microblog.css
git commit -m "refine: warm-refined CSS polish on microblog cards"
git push origin master
```

---

## Final Verification Checklist

- [ ] Send `📖 測試書名 p.1\n測試引文` to Telegram → `_fragments/` gets a `type: quote` file
- [ ] Send `測試想法 #測試` to Telegram → `_fragments/` gets a `type: thought` file with tag
- [ ] Visit `/脈絡串/` → threads index renders
- [ ] Visit `/脈絡串/sample-thread/` → thread page renders with correct layout
- [ ] Visit `/threads/edit/` → login works
- [ ] Drag fragment from library to thread → order saves to GitHub
- [ ] Reorder fragments → persists after refresh
- [ ] Remove fragment from thread → saves correctly
- [ ] Create new thread → appears in sidebar
- [ ] Click share → URL copied to clipboard
