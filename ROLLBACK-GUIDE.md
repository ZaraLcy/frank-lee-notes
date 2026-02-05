# 🔄 UI 設計還原指南

## 備份資訊

**備份分支**: `backup-original-theme`  
**備份時間**: 2026-02-05 19:20  
**備份內容**: 原始 GitBook 主題樣式（純白背景）

---

## 快速還原步驟

### 方法一：本地還原（推薦）

```bash
# 1. 切換到備份分支
cd /Users/leechuan-yao/git/frank-lee-notes
git checkout backup-original-theme

# 2. 重啟 Docker 查看效果
docker-compose restart

# 3. 如果確定要還原，將 master 重置為備份狀態
git checkout master
git reset --hard backup-original-theme
git push origin master --force
```

### 方法二：僅還原 CSS 檔案

```bash
# 只還原 custom-local.css
git checkout backup-original-theme -- assets/gitbook/custom-local.css

# 提交變更
git add assets/gitbook/custom-local.css
git commit -m "Restore original CSS theme"
git push origin master
```

### 方法三：查看備份內容（不還原）

```bash
# 查看備份分支的檔案
git show backup-original-theme:assets/gitbook/custom-local.css

# 比較與當前版本的差異
git diff master backup-original-theme -- assets/gitbook/custom-local.css
```

---

## 分支說明

### `master` 分支
- 新的溫馨古典風格
- 羊皮紙色背景
- 襯線字體標題
- 暖色調配色

### `backup-original-theme` 分支
- 原始 GitBook 主題
- 純白色背景
- 系統預設字體
- 原始配色

---

## 注意事項

1. **備份分支已推送到 GitHub**
   - 即使本地刪除，GitHub 上仍有完整備份
   
2. **隨時可以還原**
   - 本地測試不滿意：直接切換分支
   - 已推送到 GitHub：使用 `git reset --hard`

3. **保留兩個分支**
   - 建議保留 `backup-original-theme` 分支
   - 可隨時比較兩種風格

---

## Docker 環境注意

切換分支後記得重啟：
```bash
docker-compose restart
```

或強制重建：
```bash
docker-compose down
docker-compose up -d
```

---

## 聯絡支援

如有問題，可參考：
- Git 分支管理：[Git 官方文檔](https://git-scm.com/book/zh-tw/v2)
- Jekyll 主題：[Jekyll Gitbook 主題](https://github.com/sighingnow/jekyll-gitbook)

---

**備份確認**: ✅ 已完成  
**安全性**: 🟢 可隨時還原  
**準備狀態**: 🎨 可以開始實施新設計
