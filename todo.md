# Todo

## 待辦事項

### [ ] 設定 Telegram Webhook Secret Token

為了讓 Telegram webhook 安全驗證生效（防止未授權請求觸發文章發布），需要完成以下三個步驟：

#### 步驟一：產生一個 secret token

建議使用隨機字串，例如用以下指令產生：

```bash
openssl rand -hex 32
```

#### 步驟二：在 Vercel 新增環境變數

前往 Vercel 專案設定 → **Environment Variables**，新增：

| 名稱 | 值 |
|------|-----|
| `TELEGRAM_WEBHOOK_SECRET` | （步驟一產生的字串） |

#### 步驟三：重新設定 Telegram Webhook 並帶入 secret_token

用瀏覽器或 curl 呼叫以下 API（替換 `<TOKEN>`、`<VERCEL_URL>`、`<YOUR_SECRET>`）：

```
https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://<VERCEL_URL>/api/telegram-webhook&secret_token=<YOUR_SECRET>
```

或用 curl：

```bash
curl "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -d "url=https://<VERCEL_URL>/api/telegram-webhook" \
  -d "secret_token=<YOUR_SECRET>"
```

> 完成後，每次 Telegram 傳訊息到 bot，webhook 請求都會帶上 `X-Telegram-Bot-Api-Secret-Token` header，伺服器端會自動驗證，非法請求會被拒絕（401）。
