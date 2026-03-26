import { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Vercel Serverless Function
 * 接收 Telegram Webhook 並觸發 GitHub Actions
 */

// GitHub 配置（使用環境變數）
const GITHUB_OWNER = process.env.GITHUB_OWNER || 'ZaraLcy';
const GITHUB_REPO = process.env.GITHUB_REPO || 'frank-lee-notes';
const GITHUB_TOKEN = process.env.GH_PAT;
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_SECRET_TOKEN = process.env.TELEGRAM_WEBHOOK_SECRET;
const ALLOWED_CHAT_ID = process.env.TELEGRAM_ALLOWED_CHAT_ID;

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // 只接受 POST 請求
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // 驗證 Telegram Secret Token
  const incomingSecret = req.headers['x-telegram-bot-api-secret-token'];
  if (!TELEGRAM_SECRET_TOKEN || incomingSecret !== TELEGRAM_SECRET_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const update = req.body;

    // 驗證是否為有效的 Telegram 更新
    if (!update.message || !update.message.text) {
      return res.status(200).json({ ok: true, message: 'Ignored non-text message' });
    }

    const message = update.message;
    const chatId = message.chat.id;
    const messageText = message.text;
    const messageId = message.message_id;

    // 驗證 Chat ID 白名單
    if (!ALLOWED_CHAT_ID || String(chatId) !== ALLOWED_CHAT_ID) {
      console.warn(`拒絕未授權的 chat_id: ${chatId}`);
      return res.status(200).json({ ok: true }); // 回傳 200 避免 Telegram 重試
    }

    // 忽略指令訊息（如 /start）
    if (messageText.startsWith('/')) {
      return res.status(200).json({ ok: true, message: 'Ignored command' });
    }

    console.log(`收到訊息：${messageText}`);

    // 同時觸發 micro-post 和 fragment 兩個工作流（真正並行）
    const dispatchUrl = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/dispatches`;
    const dispatchHeaders = {
      'Authorization': `token ${GITHUB_TOKEN}`,
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
    const basePayload = { message: messageText, chat_id: chatId, message_id: messageId };

    const [githubResponse, fragmentResponse] = await Promise.all([
      fetch(dispatchUrl, {
        method: 'POST',
        headers: dispatchHeaders,
        body: JSON.stringify({ event_type: 'telegram-micro-post', client_payload: basePayload }),
      }),
      fetch(dispatchUrl, {
        method: 'POST',
        headers: dispatchHeaders,
        body: JSON.stringify({ event_type: 'telegram-fragment', client_payload: basePayload }),
      }),
    ]);

    if (!githubResponse.ok) {
      const errorText = await githubResponse.text();
      console.error('GitHub API 錯誤（micro-post）：', errorText);
      throw new Error(`GitHub API error: ${githubResponse.status}`);
    }

    if (!fragmentResponse.ok) {
      console.error(`Fragment dispatch 失敗 [${fragmentResponse.status}]：`, await fragmentResponse.text());
      // 非致命錯誤，不中斷主流程
    }

    console.log('✅ GitHub Actions 已觸發（micro-post + telegram-fragment）');

    // 發送即時反饋給用戶
    await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          chat_id: chatId,
          text: '⏳ 正在處理你的微網誌...\n預計 30 秒內完成發布',
          reply_to_message_id: messageId,
        }),
      }
    );

    return res.status(200).json({ ok: true, message: 'Workflow triggered' });
  } catch (error) {
    console.error('錯誤：', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
