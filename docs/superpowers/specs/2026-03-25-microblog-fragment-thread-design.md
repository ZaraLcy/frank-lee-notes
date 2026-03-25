# 微網誌優化設計：片段庫與脈絡串系統

**日期：** 2026-03-25
**狀態：** 設計確認

---

## 概覽

在現有 Telegram → Jekyll 微網誌發文流程的基礎上，新增一套「片段庫＋脈絡串」系統，讓使用者能夠：

1. 透過 Telegram 快速收集書摘和片段想法
2. 在網頁編輯器中將片段組織成有序的脈絡串
3. 片段可跨多條脈絡串共用（Zettelkasten 概念）
4. 脈絡串永遠是動態的，隨時可更動，有獨立公開 URL

---

## 視覺設計方向

**暖色系精緻化**：保留現有的溫暖書卷氣（棕色系 `#8b5a3c`、米色背景），在字型、間距與細節上精緻化。不引入新的色彩系統。

---

## 資料結構

### 片段（Fragment）

存放於 `_fragments/`，每個片段一個 Markdown 檔案：

```
_fragments/
  20260325-120754.md
  20260318-093012.md
```

**Front matter 格式：**

```yaml
---
id: 20260325-120754
type: quote          # quote（書摘）或 thought（想法）
source: "塔羅冥想"   # 書名（type: quote 時才有）
page: 114            # 頁碼（選填）
date: 2026-03-25 12:07:54
tags: ["靈性", "服務"]
---

片段內容文字
```

### 脈絡串（Thread）

存放於 `_threads/`，每條脈絡串一個 Markdown 檔案：

```
_threads/
  hermit-service.md
  taoism-notes.md
```

**Front matter 格式：**

```yaml
---
title: "隱修與服務"
description: "關於放下自我意志、以服務為本的靈性實踐"
created: 2026-03-20
updated: 2026-03-25
fragment_ids:
  - 20260325-120754
  - 20260320-081200
  - 20260318-093012
---
```

片段順序由 `fragment_ids` 的陣列順序決定。

---

## Telegram 輸入語法

所有 Telegram 訊息一律進入片段庫（不直接指定脈絡串）。脈絡串的組織在網頁編輯器中完成。

**個人想法**（直接發送）：
```
真正的謙遜不是貶低自己，而是清空自我讓更大的東西流過。
```
→ 建立 `type: thought` 的片段

**書摘**（第一行以 📖 開頭）：
```
📖 塔羅冥想 p.201
靈感不是靠意志獲得的，是人盡力後所得到的上界贈禮。
```
→ 建立 `type: quote` 的片段，自動解析書名與頁碼

**標籤**（選填，加在訊息任何位置）：
```
📖 道德經 第十六章
致虛極，守靜篤。 #道家 #哲學
```

---

## 網頁編輯器介面

路徑：`/threads/edit`（需要 GitHub token 認證）

### 版面結構

```
┌──────────────┬─────────────────────────────┬──────────────────┐
│  左側邊欄     │      主要編輯區域             │  右側片段庫抽屜   │
│              │                             │  （可展開/收起）  │
│  脈絡串列表  │  選中的脈絡串標題＋描述        │                  │
│  ─────────  │  ──────────────────────      │  搜尋欄          │
│  隱修與服務  │                             │  篩選：全部/書摘  │
│  道家思想    │  ⠿ 片段 1（可拖曳排序）       │       /想法      │
│  塔羅與原型  │  ⠿ 片段 2                   │  ─────────────  │
│              │  ⠿ 片段 3                   │  片段 A          │
│  + 新增串    │                             │  所屬：串1, 串2   │
│              │  [拖曳放置區]               │                  │
│              │                             │  片段 B          │
│              │  [發布為文章] [分享]         │  尚未加入任何串   │
└──────────────┴─────────────────────────────┴──────────────────┘
```

### 互動細節

- **排序**：拖曳片段卡片上的 ⠿ 手柄重新排列順序
- **新增片段**：從右側抽屜拖曳片段到主區域的目標位置
- **片段庫抽屜**：點右上角「片段庫 ▶」展開，再點收起
- **跨串顯示**：抽屜中每個片段下方標示所屬脈絡串（深色 = 當前串，淺色 = 其他串，虛線 = 尚未加入任何串）
- **已加入提示**：當前串已有的片段在抽屜中顯示為灰色並標示「✓ 已在此串」
- **編輯片段內容**：點擊片段卡片可展開編輯模式
- **編輯串標題/描述**：點擊標題處可直接編輯
- **儲存機制**：透過 GitHub API commit 變更至 `_threads/` 或 `_fragments/`，觸發 Jekyll rebuild（約 30 秒後生效）

---

## 公開脈絡串頁面

路徑：`/脈絡串/<slug>`（如 `/脈絡串/hermit-service`）

### 設計原則

- 暖色系，與現有微誌頁面一致
- **時間軸節點**：圓點＋細線串起所有片段
- **書摘**：斜體＋左側細線，顯示來源（📖 書名 頁碼）
- **個人想法**：正體，顯示日期
- 頁尾說明「持續更新中 · 無終點」，不顯示「完成」狀態

---

## 系統架構

### Telegram 路由

所有 Telegram 訊息進入同一個 webhook，由 webhook 判斷路由：

```
Telegram 訊息
     ↓
api/telegram-webhook.ts
     ├─ 訊息以 / 開頭 → 忽略（指令）
     ├─ 訊息以 📖 開頭 → dispatch event: telegram-fragment（type: quote）
     └─ 其他 → dispatch event: telegram-fragment（type: thought）

（原有 telegram-micro-post 事件類型移除，統一改為 telegram-fragment）
```

**GitHub Actions workflow（新）**：

```yaml
on:
  repository_dispatch:
    types: [telegram-fragment]
# 執行 scripts/telegram/create_fragment.py
# 寫入 _fragments/YYYYMMDD-HHMMSSfff.md（含毫秒避免衝突）
```

原有 `telegram-bot.yml`（micro-post）停用，原功能整合至新的 fragment 流程（微誌動態頁面改為展示所有 `type: thought` 的片段，或維持現有 `_posts/` 並行，待 Phase 2 決定）。

### Fragment ID 格式

使用毫秒時間戳加 4 位隨機碼避免衝突：

```
20260325-120754-823-a4f2
```

Front matter 中的 `id` 欄位與檔名一致。Thread 的 `fragment_ids` 使用此完整 ID。

### 網頁編輯器架構

```
瀏覽器（/threads/edit）
     ↓ HTTPS
api/thread-editor.ts（Vercel）
     ↓ 持有 GH_PAT（server-side，不暴露給瀏覽器）
GitHub API（讀寫 _threads/ 和 _fragments/）
```

**認證方式**：編輯器頁面受 `EDITOR_PASSWORD` 環境變數保護（simple password check in Vercel function）。使用者在頁面輸入密碼，Vercel function 驗證後以 session cookie 維持狀態。GitHub token 僅存在 Vercel server-side，不傳至瀏覽器。

**並發衝突處理**：每次 commit 前先取得目標檔案的最新 SHA，若 commit 時 SHA 不符（409 錯誤），向使用者顯示「有新的變更，請重新整理後再儲存」，不靜默覆蓋。

---

## Jekyll Collection 設定

在 `_config.yml` 新增：

```yaml
collections:
  pages:
    output: true
    permalink: /:collection/:path/
  others:
    output: true
    permalink: /:collection/:path/
  fragments:
    output: false          # 片段不需要獨立公開頁面
  threads:
    output: true
    permalink: /脈絡串/:name/
```

---

## 互動細節補充

### 從脈絡串移除片段

- 滑鼠懸停片段卡片時，右上角顯示 ✕ 按鈕
- 點擊 ✕ 將該片段從當前脈絡串移除（僅移除引用，不刪除片段本身）
- 片段仍保留在片段庫中

### 刪除片段

- 在片段庫中，滑鼠懸停顯示「⋯」選單
- 選單含「刪除片段」選項，確認後從 `_fragments/` 移除檔案
- 若片段已被脈絡串引用，顯示警告：「此片段被 N 條脈絡串使用，刪除後將從中移除」

### 發布為文章

- 點擊「發布為文章」，在 `_posts/` 建立一篇新 post
- 內容為脈絡串的標題、描述，加上所有片段依序排列
- 在 thread front matter 加入 `published_post: <post-slug>` 標記
- 此為單向操作，不會反向同步

### 分享連結

- 點擊「分享」複製公開 URL 至剪貼簿（`/脈絡串/<slug>`）
- 顯示「已複製連結」提示

---

## 標籤解析規範

`create_fragment.py` 中的標籤解析需支援中文字符：

```python
# 正確：使用 Unicode word characters
tags = re.findall(r'#([\w\u4e00-\u9fff]+)', message)

# 輸入：「真正的謙遜 #道家 #哲學」
# 輸出：["道家", "哲學"]
```

`source` 欄位僅在 `type: quote` 時寫入 front matter；`type: thought` 的檔案完全省略 `source` 和 `page` 欄位。

---

## Thread Slug 命名規則

建立新脈絡串時：
- 編輯器自動以拼音轉換中文標題為 slug（使用 `pypinyin` 套件）
- 例：「隱修與服務」→ `yin-xiu-yu-fu-wu`
- 若使用者偏好，可在建立時手動覆寫 slug

---

## 新增的工作項目

1. **`_config.yml`**：新增 `fragments` 和 `threads` collection 設定
2. **`api/telegram-webhook.ts`**：移除 micro-post 路由，改為統一 fragment 路由
3. **`.github/workflows/telegram-fragment.yml`**：新增 fragment 處理 workflow
4. **`scripts/telegram/create_fragment.py`**：建立片段檔案，支援 quote/thought 辨識與中文標籤
5. **`api/thread-editor.ts`**：server-side GitHub API proxy，含密碼驗證與 SHA 衝突檢查
6. **脈絡串編輯器前端**（`/threads/edit`）：左側欄、主區域拖曳排序、右側片段庫抽屜
7. **公開脈絡串頁面 layout**（`_layouts/thread.html`）：時間軸式片段展示
8. **`microblog.css` 精緻化**：暖色系細節優化
