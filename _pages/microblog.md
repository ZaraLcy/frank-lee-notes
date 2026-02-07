---
layout: home
title: 💬 微誌動態
permalink: /microblog/
---

<link rel="stylesheet" href="{{ '/assets/css/microblog.css' | relative_url }}">

<div class="microblog-container">
  <div class="microblog-header">
    <h1>💬 微誌動態</h1>
    <p class="subtitle">記錄日常的靈感、想法與觀察</p>
  </div>

  <div class="microblog-timeline">
    {% assign micro_posts = site.posts | where: "category", "微誌" | sort: "date" | reverse %}
    
    {% if micro_posts.size > 0 %}
      {% for post in micro_posts %}
        <article class="micro-card">
          <div class="micro-card-header">
            <span class="micro-time">{{ post.date | date: "%Y-%m-%d %H:%M" }}</span>
            <div class="micro-tags">
              {% for tag in post.tags %}
                {% if tag != "微誌" and tag != "隨筆" %}
                  <span class="micro-tag">#{{ tag }}</span>
                {% endif %}
              {% endfor %}
            </div>
          </div>
          
          <div class="micro-card-content">
            {{ post.content | strip_html | truncatewords: 50 }}
          </div>
          
          <div class="micro-card-footer">
            <a href="{{ post.url | relative_url }}" class="micro-read-more">
              閱讀完整內容 →
            </a>
          </div>
        </article>
      {% endfor %}
    {% else %}
      <div class="micro-card" style="text-align: center; padding: 40px;">
        <p style="color: #999; font-size: 1.1em;">還沒有微誌動態</p>
        <p style="color: #999; font-size: 0.9em; margin-top: 10px;">
          使用 <code>bash _templates/new-micro.sh</code> 創建第一則微誌！
        </p>
      </div>
    {% endif %}
  </div>
</div>

<style>
  /* 頁面特定樣式 */
  .page-content {
    padding: 0;
  }
  
  .microblog-container {
    animation: fadeIn 0.5s ease-in;
  }
  
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
</style>
