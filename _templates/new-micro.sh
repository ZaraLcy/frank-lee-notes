#!/bin/bash

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}💬 Plurk 風格短訊息${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# 獲取當前時間
current_date=$(date +%Y-%m-%d)
current_time=$(date +%H:%M:%S)
current_datetime="${current_date} ${current_time}"
timestamp=$(date +%Y%m%d-%H%M%S)

# 選擇輸入方式
echo -e "${YELLOW}請選擇輸入方式：${NC}"
echo "1) 直接輸入短文（建議 280 字以內）"
echo "2) 多行模式（輸入 'END' 結束）"
echo ""
read -p "請選擇 (1-2): " input_mode

echo ""

case $input_mode in
    1)
        # 單行輸入
        read -p "請輸入短訊息內容：" message
        ;;
    2)
        # 多行輸入
        echo -e "${YELLOW}請輸入內容（完成後輸入 'END' 並按 Enter）：${NC}"
        message=""
        while IFS= read -r line; do
            if [ "$line" = "END" ]; then
                break
            fi
            if [ -n "$message" ]; then
                message="${message}
${line}"
            else
                message="$line"
            fi
        done
        ;;
    *)
        echo -e "${YELLOW}無效的選項，使用單行模式${NC}"
        read -p "請輸入短訊息內容：" message
        ;;
esac

# 檢查是否有內容
if [ -z "$message" ]; then
    echo -e "${YELLOW}⚠️  內容為空，已取消${NC}"
    exit 0
fi

# 計算字數
char_count=${#message}

# 提示字數
if [ $char_count -gt 280 ]; then
    echo -e "${YELLOW}⚠️  內容較長（${char_count} 字），建議精簡到 280 字以內${NC}"
else
    echo -e "${GREEN}✓ 內容長度：${char_count} 字${NC}"
fi

# 生成標題（取前 30 個字元，並加入 💬 emoji）
if [ ${#message} -gt 30 ]; then
    title="💬 ${message:0:30}..."
else
    title="💬 $message"
fi

# 詢問 hashtag
echo ""
read -p "標籤（可選，多個用逗號分隔）: " tags_input

# 處理標籤
if [ -n "$tags_input" ]; then
    # 將逗號分隔的標籤轉換為 YAML 陣列格式
    tags="[微誌, 隨筆, $tags_input]"
else
    tags="[微誌, 隨筆]"
fi

# 建立檔案名稱
filename="${current_date}-micro-${timestamp}.md"
filepath="_posts/${filename}"

# 檢查目錄是否存在
if [ ! -d "_posts" ]; then
    mkdir -p "_posts"
fi

# 創建檔案
cat > "$filepath" << EOF
---
title: "${title}"
date: ${current_datetime}
author: Frank Lee
category: 微誌
tags: ${tags}
layout: post
---

${message}

---

*發布於 ${current_datetime}*
EOF

echo ""
echo -e "${GREEN}✅ 短訊息已發布！${NC}"
echo -e "${GREEN}📁 檔案: ${filepath}${NC}"
echo -e "${GREEN}📝 字數: ${char_count}${NC}"
echo -e "${GREEN}🕐 時間: ${current_datetime}${NC}"
echo ""
echo -e "${BLUE}預覽訊息：${NC}"
echo -e "${CYAN}┌────────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC} ${message:0:100}"
if [ ${#message} -gt 100 ]; then
    echo -e "${CYAN}│${NC} ..."
fi
echo -e "${CYAN}└────────────────────────────────┘${NC}"
echo ""
echo -e "${BLUE}在 Docker 環境中查看：${NC}"
echo "http://localhost:4000/frank-lee-notes/"
echo ""
echo -e "${CYAN}================================${NC}"
