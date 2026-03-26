---
layout: home
title: 📚 脈絡串
permalink: /脈絡串/
---
<link rel="stylesheet" href="{{ '/assets/css/thread.css' | relative_url }}">
<div style="max-width:680px;margin:40px auto;padding:0 20px;font-family:Georgia,serif;">
  <div style="margin-bottom:32px;padding-bottom:20px;border-bottom:2px solid #f0e6dc;">
    <h1 style="font-size:22px;color:#8b5a3c;margin-bottom:8px;">📚 脈絡串</h1>
    <p style="font-size:14px;color:#a0826d;">把零散的書摘與想法，串成有脈絡的思考線索。</p>
  </div>
  {% assign threads = site.threads | sort: "updated" | reverse %}
  {% for thread in threads %}
  <a href="{{ thread.url | relative_url }}" style="display:block;text-decoration:none;margin-bottom:16px;">
    <div style="background:linear-gradient(135deg,#fffbf5,#fef8f0);border-left:4px solid #d4a574;border-radius:8px;padding:16px 20px;">
      <div style="font-size:16px;color:#8b5a3c;font-weight:600;margin-bottom:4px;">{{ thread.title }}</div>
      {% if thread.description %}<div style="font-size:13px;color:#a0826d;margin-bottom:8px;">{{ thread.description }}</div>{% endif %}
      <div style="font-size:11px;color:#b8977e;">{{ thread.fragment_ids.size }} 個片段 · 更新於 {{ thread.updated }}</div>
    </div>
  </a>
  {% endfor %}
</div>
