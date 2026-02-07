# Telegram Bot 整合文件

本目錄包含 Telegram Bot 與微網誌系統的整合。

## 📁 檔案結構

```
scripts/telegram/
├── create_micro_post.py    # 創建微網誌的 Python 腳本
├── requirements.txt         # Python 依賴
└── README.md               # 本文件

.github/workflows/
└── telegram-bot.yml        # GitHub Actions workflow

api/
└── telegram-webhook.ts     # Vercel Serverless Function
```

## 🚀 快速開始

請參閱完整設定指南：
📖 [Telegram Bot 設定完整指南](../../.gemini/antigravity/brain/cfcd3a21-5f54-4ca6-a970-9a2b09c8eda8/telegram-bot-setup-guide.md)

## 🔧 本地測試

### 測試 Python 腳本

```bash
# 設定環境變數
export TELEGRAM_MESSAGE="測試訊息 #測試"
export TELEGRAM_CHAT_ID="123456789"
export MESSAGE_ID="1"

# 執行腳本
python scripts/telegram/create_micro_post.py
```

## 📝 使用方式

1. 在 Telegram 發送訊息給你的 Bot
2. 等待約 30 秒
3. 收到發布成功的回覆
4. 訪問網站查看新文章

### 訊息格式

```
這是一則微網誌內容 #標籤1 #標籤2
```

支援：
- ✅ 純文字訊息
- ✅ 多行訊息
- ✅ Hashtag 標籤
- ⏳ 圖片（待實作）

## 🔒 環境變數

### GitHub Secrets

| 變數名 | 用途 |
|--------|------|
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API Token |
| `TELEGRAM_CHAT_ID` | 你的 Telegram Chat ID |
| `GH_PAT` | GitHub Personal Access Token |

### Vercel 環境變數

| 變數名 | 用途 |
|--------|------|
| `GITHUB_OWNER` | GitHub 用戶名 |
| `GITHUB_REPO` | 儲存庫名稱 |
| `GH_PAT` | GitHub Token |
| `TELEGRAM_BOT_TOKEN` | Bot Token |

## 🐛 故障排除

常見問題請參閱[設定指南的故障排除章節](../../.gemini/antigravity/brain/cfcd3a21-5f54-4ca6-a970-9a2b09c8eda8/telegram-bot-setup-guide.md#-故障排除)

## 📚 技術細節

### 工作流程

1. Telegram 發送訊息
2. Telegram Webhook → Vercel Function
3. Vercel Function 觸發 GitHub Repository Dispatch
4. GitHub Actions 執行 workflow
5. Python 腳本生成 `.md` 檔案
6. Git commit & push
7. Bot 回覆成功訊息

### 依賴

- Python 3.11+
- requests
- pytz
- Node.js 18+ (Vercel)
- @vercel/node

## 🔄 更新日誌

- 2026-02-08: 初始版本，支援文字訊息
