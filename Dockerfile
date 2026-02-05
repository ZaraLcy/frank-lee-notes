# Jekyll Gitbook Docker 環境
FROM ruby:3.2

# 設定工作目錄
WORKDIR /app

# 安裝必要的系統依賴
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# 複製 Gemfile
COPY Gemfile* ./

# 安裝 Ruby gems
RUN bundle install

# 複製整個項目
COPY . .

# 暴露 Jekyll 預設端口
EXPOSE 4000

# 啟動 Jekyll 開發伺服器
# --host 0.0.0.0 允許從容器外部訪問
# --livereload 啟用即時重載
# --force_polling 在 Docker 環境中確保檔案變更檢測正常工作
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--force_polling"]
