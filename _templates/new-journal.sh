#!/bin/bash

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}📔 創建工作日誌${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 詢問日期
echo -e "${YELLOW}請選擇日期：${NC}"
echo "1) 今天 ($(date +%Y-%m-%d))"
echo "2) 自訂日期"
echo ""
read -p "請輸入選項 (1-2): " date_choice

case $date_choice in
    1)
        journal_date=$(date +%Y-%m-%d)
        ;;
    2)
        read -p "請輸入日期 (YYYY-MM-DD): " journal_date
        # 簡單驗證日期格式
        if ! [[ $journal_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo -e "${YELLOW}⚠️  日期格式錯誤，使用今天的日期${NC}"
            journal_date=$(date +%Y-%m-%d)
        fi
        ;;
    *)
        echo -e "${YELLOW}無效的選項，使用今天的日期${NC}"
        journal_date=$(date +%Y-%m-%d)
        ;;
esac

# 建立檔案名稱
filename="${journal_date}.md"
filepath="_workjournal/${filename}"

# 檢查檔案是否已存在
if [ -f "$filepath" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  該日期的日誌已存在: ${filepath}${NC}"
    read -p "是否覆蓋？(y/N): " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        exit 0
    fi
fi

# 複製範本
cp "_templates/workjournal.md" "$filepath"

# 替換日期
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/YYYY-MM-DD/${journal_date}/g" "$filepath"
else
    # Linux
    sed -i "s/YYYY-MM-DD/${journal_date}/g" "$filepath"
fi

echo ""
echo -e "${GREEN}✅ 工作日誌已創建！${NC}"
echo -e "${GREEN}📁 檔案位置: ${filepath}${NC}"
echo -e "${GREEN}📅 日期: ${journal_date}${NC}"
echo ""
echo -e "${BLUE}下一步：${NC}"
echo "1. 填寫今日目標"
echo "2. 記錄完成事項"
echo "3. 總結心得與收穫"
echo ""
echo -e "${BLUE}================================${NC}"
