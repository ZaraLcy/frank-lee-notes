#!/usr/bin/env python3
"""
Telegram 微網誌創建腳本
從環境變數讀取 Telegram 訊息，生成微網誌 Markdown 檔案
"""

import os
import re
import json
from datetime import datetime
import pytz
import requests

def parse_message(message):
    """解析 Telegram 訊息，提取標題、標籤和內容"""
    
    # 提取標籤
    tags = re.findall(r'#(\w+)', message)
    
    # 移除標籤，保留純文字內容
    content = re.sub(r'#\w+', '', message).strip()
    
    # 生成標題（取前 30 個字）
    if len(content) > 30:
        title = f"💬 {content[:30]}..."
    else:
        title = f"💬 {content}"
    
    # 確保至少有基礎標籤
    if not tags:
        tags = ['微誌', '隨筆']
    else:
        tags = ['微誌'] + tags
    
    return {
        'title': title,
        'content': content,
        'tags': tags
    }

def create_micro_post():
    """創建微網誌檔案"""
    
    # 讀取環境變數
    message = os.environ.get('TELEGRAM_MESSAGE', '')
    chat_id = os.environ.get('TELEGRAM_CHAT_ID', '')
    message_id = os.environ.get('MESSAGE_ID', '')
    
    if not message:
        print("❌ 未收到訊息內容")
        return False
    
    # 解析訊息
    parsed = parse_message(message)
    
    # 使用台北時區
    tz = pytz.timezone('Asia/Taipei')
    now = datetime.now(tz)
    
    # 生成檔案名稱
    date_str = now.strftime('%Y-%m-%d')
    timestamp_str = now.strftime('%Y%m%d-%H%M%S')
    filename = f"_posts/{date_str}-micro-{timestamp_str}.md"
    
    # 生成 URL（需要根據實際部署調整）
    base_url = "https://zaralcy.github.io/frank-lee-notes"  # 修改為你的實際 URL
    post_date = now.strftime('%Y-%m-%d')
    post_url = f"{base_url}/微誌/{post_date}-micro-{timestamp_str}.html"
    
    # 生成 Front Matter
    front_matter = f"""---
title: "{parsed['title']}"
date: {now.strftime('%Y-%m-%d %H:%M:%S')}
author: Frank Lee
category: 微誌
tags: {json.dumps(parsed['tags'], ensure_ascii=False)}
layout: micro-post
---

{parsed['content']}

> 📱 發佈於 {now.strftime('%Y年%m月%d日 %H:%M')} via Telegram
"""
    
    # 寫入檔案
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(front_matter)
        print(f"✅ 微網誌已創建：{filename}")
        
        # 將 URL 寫入檔案供後續步驟使用
        with open('post_url.txt', 'w') as f:
            f.write(post_url)
        
        # 設定環境變數供後續步驟使用
        os.environ['POST_URL'] = post_url
        
        return True
    except Exception as e:
        print(f"❌ 創建微網誌失敗：{e}")
        return False

if __name__ == '__main__':
    success = create_micro_post()
    exit(0 if success else 1)
