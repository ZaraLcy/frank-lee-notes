#!/bin/bash

# 圖片優化腳本 - 適合網頁瀏覽並備份原始檔案
# 使用方法: 
#   ./optimize-images.sh              # 處理所有圖片
#   ./optimize-images.sh file1.png    # 只處理指定檔案
#   ./optimize-images.sh *.jpg        # 處理所有 jpg 檔案

# 設定顏色輸出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 設定參數
MAX_WIDTH=1920          # 最大寬度（px）
MAX_HEIGHT=1920         # 最大高度（px）
QUALITY=85              # JPEG 品質 (0-100)
BACKUP_DIR="originals-backup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}圖片優化腳本${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "設定："
echo -e "  最大尺寸: ${YELLOW}${MAX_WIDTH}x${MAX_HEIGHT}px${NC}"
echo -e "  JPEG 品質: ${YELLOW}${QUALITY}%${NC}"
echo -e "  備份目錄: ${YELLOW}${BACKUP_DIR}${NC}"
echo ""

# 建立備份目錄
if [ ! -d "${SCRIPT_DIR}/${BACKUP_DIR}" ]; then
    mkdir -p "${SCRIPT_DIR}/${BACKUP_DIR}"
    echo -e "${GREEN}✓ 已建立備份目錄${NC}"
fi

# 處理檔案計數器
processed=0
skipped=0
failed=0

# 處理圖片函數
process_image() {
    local file="$1"
    local filename=$(basename "$file")
    local backup_path="${SCRIPT_DIR}/${BACKUP_DIR}/${filename}"
    
    # 獲取原始檔案大小（KB）
    local original_size=$(stat -f%z "$file")
    local original_size_kb=$((original_size / 1024))
    
    # 獲取圖片尺寸
    local dimensions=$(sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}')
    local width=$(echo "$dimensions" | sed -n '1p')
    local height=$(echo "$dimensions" | sed -n '2p')
    
    if [ -z "$width" ] || [ -z "$height" ]; then
        echo -e "${RED}✗ 無法讀取 ${filename} 的尺寸${NC}"
        ((failed++))
        return
    fi
    
    # 檢查是否需要優化
    if [ "$width" -le "$MAX_WIDTH" ] && [ "$height" -le "$MAX_HEIGHT" ] && [ "$original_size_kb" -lt 500 ]; then
        echo -e "${YELLOW}⊘ 跳過 ${filename} (${width}x${height}, ${original_size_kb}KB - 已經夠小)${NC}"
        ((skipped++))
        return
    fi
    
    echo -e "${BLUE}處理 ${filename}${NC}"
    echo -e "  原始尺寸: ${width}x${height}, ${original_size_kb}KB"
    
    # 備份原始檔案（如果還沒備份過）
    if [ ! -f "$backup_path" ]; then
        cp "$file" "$backup_path"
        echo -e "  ${GREEN}✓ 已備份到 ${BACKUP_DIR}/${filename}${NC}"
    else
        echo -e "  ${YELLOW}⊘ 備份已存在，跳過${NC}"
    fi
    
    # 使用 sips 調整圖片大小
    if [ "$width" -gt "$MAX_WIDTH" ] || [ "$height" -gt "$MAX_HEIGHT" ]; then
        sips --resampleHeightWidthMax "$MAX_WIDTH" "$file" --out "$file" > /dev/null 2>&1
        echo -e "  ${GREEN}✓ 已調整尺寸${NC}"
    fi
    
    # 如果是 JPEG，調整品質
    if [[ "$filename" =~ \.(jpg|jpeg)$ ]]; then
        sips -s format jpeg -s formatOptions "$QUALITY" "$file" --out "$file" > /dev/null 2>&1
        echo -e "  ${GREEN}✓ 已優化 JPEG 品質${NC}"
    fi
    
    # 如果是 PNG，可以考慮轉換成 JPEG（選擇性）
    # 這裡保留 PNG 格式，但可以取消註解來轉換
    # if [[ "$filename" =~ \.png$ ]]; then
    #     new_filename="${filename%.png}.jpg"
    #     sips -s format jpeg -s formatOptions "$QUALITY" "$file" --out "${SCRIPT_DIR}/${new_filename}" > /dev/null 2>&1
    #     rm "$file"
    #     file="${SCRIPT_DIR}/${new_filename}"
    #     echo -e "  ${GREEN}✓ 已轉換為 JPEG${NC}"
    # fi
    
    # 獲取優化後的檔案大小
    local new_size=$(stat -f%z "$file")
    local new_size_kb=$((new_size / 1024))
    local saved_kb=$((original_size_kb - new_size_kb))
    local saved_percent=$((saved_kb * 100 / original_size_kb))
    
    # 重新獲取尺寸
    dimensions=$(sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}')
    width=$(echo "$dimensions" | sed -n '1p')
    height=$(echo "$dimensions" | sed -n '2p')
    
    echo -e "  ${GREEN}✓ 完成: ${width}x${height}, ${new_size_kb}KB (節省 ${saved_kb}KB, ${saved_percent}%)${NC}"
    echo ""
    
    ((processed++))
}

# 處理圖片
echo -e "${BLUE}開始處理圖片...${NC}"
echo ""

# 檢查是否有指定檔案
if [ $# -gt 0 ]; then
    # 處理指定的檔案
    echo -e "${YELLOW}模式: 處理指定檔案${NC}"
    echo ""
    for file in "$@"; do
        # 如果是相對路徑，轉換為絕對路徑
        if [[ "$file" != /* ]]; then
            file="${SCRIPT_DIR}/${file}"
        fi
        
        # 檢查檔案是否存在
        if [ ! -f "$file" ]; then
            echo -e "${RED}✗ 檔案不存在: $(basename "$file")${NC}"
            ((failed++))
            continue
        fi
        
        # 檢查是否為圖片檔案
        if [[ ! "$file" =~ \.(png|jpg|jpeg|PNG|JPG|JPEG)$ ]]; then
            echo -e "${RED}✗ 不支援的檔案格式: $(basename "$file")${NC}"
            ((failed++))
            continue
        fi
        
        process_image "$file"
    done
else
    # 處理所有圖片檔案
    echo -e "${YELLOW}模式: 處理所有圖片檔案${NC}"
    echo ""
    
    # 處理 PNG 檔案
    for file in "${SCRIPT_DIR}"/*.png; do
        [ -e "$file" ] || continue
        process_image "$file"
    done
    
    # 處理 JPG/JPEG 檔案
    for file in "${SCRIPT_DIR}"/*.jpg "${SCRIPT_DIR}"/*.jpeg "${SCRIPT_DIR}"/*.JPG "${SCRIPT_DIR}"/*.JPEG; do
        [ -e "$file" ] || continue
        process_image "$file"
    done
fi

# 顯示總結
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}處理完成！${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}已處理: ${processed} 個檔案${NC}"
echo -e "${YELLOW}已跳過: ${skipped} 個檔案${NC}"
if [ "$failed" -gt 0 ]; then
    echo -e "${RED}失敗: ${failed} 個檔案${NC}"
fi
echo -e ""
echo -e "備份檔案位置: ${YELLOW}${BACKUP_DIR}/${NC}"
