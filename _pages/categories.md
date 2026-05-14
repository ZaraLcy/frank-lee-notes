---
layout: page
title: 文章分類
permalink: /categories/
---

{% assign sorted_categories = site.categories | sort %}

{% for category in sorted_categories %}
{% assign category_name = category[0] %}
{% assign posts = category[1] | sort: "date" | reverse %}

<section class="archive-section" id="{{ category_name | slugify: 'raw' }}">
  <h2>{{ category_name }} <span class="count">{{ posts.size }}</span></h2>
  <ul class="archive-list">
    {% for post in posts %}
      <li>
        <a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y/%m/%d" }}</time>
      </li>
    {% endfor %}
  </ul>
</section>

{% endfor %}
