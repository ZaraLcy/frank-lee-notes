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
