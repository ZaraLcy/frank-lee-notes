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

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // 只接受 POST 請求
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
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

    // 忽略指令訊息（如 /start）
    if (messageText.startsWith('/')) {
      return res.status(200).json({ ok: true, message: 'Ignored command' });
    }

    console.log(`收到訊息：${messageText}`);

    // 觸發 GitHub Actions
    const githubResponse = await fetch(
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/dispatches`,
      {
        method: 'POST',
        headers: {
          'Authorization': `token ${GITHUB_TOKEN}`,
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          event_type: 'telegram-micro-post',
          client_payload: {
            message: messageText,
            chat_id: chatId,
            message_id: messageId,
          },
        }),
      }
    );

    if (!githubResponse.ok) {
      const errorText = await githubResponse.text();
      console.error('GitHub API 錯誤：', errorText);
      throw new Error(`GitHub API error: ${githubResponse.status}`);
    }

    console.log('✅ GitHub Actions 已觸發');

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
