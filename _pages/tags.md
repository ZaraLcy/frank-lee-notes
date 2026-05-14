---
layout: page
title: 標籤
permalink: /tags/
---

{% assign sorted_tags = site.tags | sort %}

{% for tag in sorted_tags %}
{% assign tag_name = tag[0] %}
{% assign posts = tag[1] | sort: "date" | reverse %}

<section class="archive-section" id="{{ tag_name | slugify: 'raw' }}">
  <h2>{{ tag_name }} <span class="count">{{ posts.size }}</span></h2>
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
