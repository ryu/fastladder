# Baseline Notes (fastladder 現状把握)

このドキュメントは、近代化（Rails 8.1 / SQLite / Hotwire）を安全に進めるための
「現状スナップショット」です。
推測は書かず、事実のみを記録します。

---

## 1. ローカル環境情報

### OS / 実行環境
- OS: macOS
- CPU: arm64
- Shell: zsh
- Ruby version manager: mise

### ツール
- Ruby: 3.4.8
- Bundler: 4.0.1
- Rails: 8.1.2
- SQLite: （sqlite3 --version の結果を書く）

---

## 2. アプリの起動経路

### 2.1 Web

- 起動コマンド: `bundle exec rails s`
- 確認URL: http://localhost:3000/reader/
- 結果: 表示できた

### 2.2 crawler

- 起動コマンド: `bundle exec ruby script/crawler`
- 起動ログ:
  - Booting FeedFetcher...
  - fetch: https://tech.findy.co.jp/feed
  - HTTP status: 200
  - parsed: 30 items
- 備考:
  - Ctrl+C で停止すると "trapped. Terminating..." と表示されて終了する

### 2.3 foreman

- Procfile:
  - web: `./bin/rails s`
  - crawler: `bundle exec ruby script/crawler`

---

## 3. 依存関係スナップショット

### Gem / DB
- DB設定: SQLite（development / test / production）
- Gemfile に mysql2 / pg が含まれており、当初 bundle install が mysql2 の
  native extension ビルドで失敗した
- mysql2 / pg を任意依存に変更後、bundle install は成功

---

## 4. DB スナップショット

- DB種別: SQLite
- DBファイル:
  - development: db/development.sqlite3
  - test: db/test.sqlite3
  - production: db/production.sqlite3

---

## 5. テスト / 回帰ポイント

### テスト実行

- 実行: `bundle exec rails test`
- 結果:
  - 232 runs, 481 assertions
  - 0 failures, 0 errors, 0 skips
- Warning:
  - test/models/feed_test.rb:66, 75
  - "literal string will be frozen in the future"

### Web スモーク
- /reader/ が表示できる

### crawler
- 実フィードを fetch / parse まで実行できる（HTTP 200, 30 items）

---

## 6. 既知のレガシー課題（事実ベース）

- Gemfile に mysql2 / pg がトップレベル依存として含まれていた
- Ruby の将来挙動に関する warning がテスト時に出ている

---

## 7. 次のマイルストーンへの前提

- SQLite 前提で web / crawler / test が動作することを確認済み
- Rails 8.1.2 で起動・テスト可能
