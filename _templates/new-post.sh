#!/bin/bash

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}📝 創建新文章${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 選擇範本類型
echo -e "${YELLOW}請選擇文章類型：${NC}"
echo "1) 通用筆記 (General)"
echo "2) 閱讀心得 (Reading)"
echo "3) 中醫學習 (TCM)"
echo "4) AI 探索 (AI)"
echo "5) 生活觀察 (Life)"
echo ""
read -p "請輸入選項 (1-5): " template_choice

case $template_choice in
    1)
        template="post-general.md"
        category="通用筆記"
        ;;
    2)
        template="post-reading.md"
        category="閱讀心得"
        ;;
    3)
        template="post-tcm.md"
        category="中醫學習"
        ;;
    4)
        template="post-ai.md"
        category="AI 探索"
        ;;
    5)
        template="post-life.md"
        category="生活觀察"
        ;;
    *)
        echo -e "${YELLOW}無效的選項，使用通用範本${NC}"
        template="post-general.md"
        category="通用筆記"
        ;;
esac

# 輸入文章標題
echo ""
read -p "請輸入文章標題（英文，用於檔名）: " title_slug

# 如果沒有輸入，使用預設值
if [ -z "$title_slug" ]; then
    title_slug="new-post"
fi

# 獲取今天的日期
today=$(date +%Y-%m-%d)

# 建立檔案名稱
filename="${today}-${title_slug}.md"
filepath="_posts/${filename}"

# 檢查檔案是否已存在
if [ -f "$filepath" ]; then
    echo -e "${YELLOW}⚠️  檔案已存在: ${filepath}${NC}"
    read -p "是否覆蓋？(y/N): " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        exit 0
    fi
fi

# 複製範本
cp "_templates/${template}" "$filepath"

# 替換日期
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/YYYY-MM-DD/${today}/g" "$filepath"
else
    # Linux
    sed -i "s/YYYY-MM-DD/${today}/g" "$filepath"
fi

echo ""
echo -e "${GREEN}✅ 文章已創建！${NC}"
echo -e "${GREEN}📁 檔案位置: ${filepath}${NC}"
echo -e "${GREEN}📂 類型: ${category}${NC}"
echo ""
echo -e "${BLUE}下一步：${NC}"
echo "1. 編輯文章內容"
echo "2. 修改標題和標籤"
echo "3. 儲存後即可在部落格中看到"
echo ""
echo -e "${BLUE}================================${NC}"
