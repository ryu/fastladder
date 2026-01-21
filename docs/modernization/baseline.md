# Baseline Notes (fastladder 現状把握)

このドキュメントは、近代化（Rails 8.1 / SQLite / Hotwire）を安全に進めるための
「現状スナップショット」です。
推測は書かず、事実のみを記録します。

**最終更新: 2026-01-21**

---

## 1. ローカル環境情報

### OS / 実行環境
- OS: macOS / Linux
- CPU: arm64 / x86_64
- Shell: zsh / bash
- Ruby version manager: mise / rbenv / asdf

### ツール
- Ruby: 3.4.8 (.ruby-version)
- Bundler: 2.6+
- Rails: 8.1.2
- SQLite: 3.x

---

## 2. アプリの起動経路

### 2.1 Web

- 起動コマンド: `bin/rails server`
- 確認URL: http://localhost:3000/reader/
- 結果: 表示できる

### 2.2 crawler

- 起動コマンド: `bundle exec ruby script/crawler`
- 起動ログ:
  - Booting FeedFetcher...
  - fetch: (subscribed feed URL)
  - HTTP status: 200
  - parsed: N items
- 備考:
  - Ctrl+C で停止すると "trapped. Terminating..." と表示されて終了する

### 2.3 foreman

- 起動コマンド: `foreman start`
- Procfile:
  - web: `./bin/rails s`
  - crawler: `bundle exec ruby script/crawler`
- 確認URL: http://localhost:5000

---

## 3. 依存関係スナップショット

### Gem / DB
- DB設定: SQLite（development / test / production）
- MySQL / PostgreSQL も config/database.yml.* で対応可能
- Docker Compose は MySQL を使用

### CI / 品質ツール
- GitHub Actions: `.github/workflows/test.yml`
- RuboCop: `.rubocop.yml` (rubocop-rails, rubocop-minitest, rubocop-performance)
- Brakeman: セキュリティスキャン
- bundler-audit: Gem 脆弱性チェック

---

## 4. DB スナップショット

- DB種別: SQLite (default)
- DBファイル:
  - development: db/development.sqlite3
  - test: db/test.sqlite3
  - production: db/production.sqlite3

---

## 5. テスト / 回帰ポイント

### テスト実行

- 実行: `bin/rails test`
- 結果:
  - 263 runs, 555 assertions
  - 0 failures, 0 errors, 0 skips

### システムテスト

- 実行: `bin/rails test:system`
- 結果:
  - 11 runs, 53 assertions
  - 0 failures, 0 errors, 0 skips

### テストデータ

- fixtures: `test/fixtures/*.yml`
- TestDataHelper: `test/support/test_data_helper.rb`
- FactoryBot: 削除済み（fixtures に統一）

### Web スモーク
- /reader/ が表示できる
- サインアップ/サインイン/サインアウトが動作する

### crawler
- 購読フィードを fetch / parse / persist できる
- WebMock でスタブ化されたテストが存在する

---

## 6. CI ステップ

`bin/ci` で以下を実行:

1. Setup (`bin/setup --skip-server`)
2. Security: Gem audit (`bundle-audit`)
3. Security: Brakeman
4. Lint: RuboCop
5. Tests: Rails (`bin/rails test`)
6. Tests: System (`bin/rails test:system`)
7. Tests: Seeds (`db:seed:replant`)

---

## 7. 既知のレガシー課題（事実ベース）

- フロントエンドは jQuery + 独自 JS（Hotwire 未導入）
- 一部の HAML テンプレートが残存（ERB への移行中）
- crawler の境界化は一部実施済み（トランザクション追加）

---

## 8. 次のマイルストーンへの前提

- SQLite 前提で web / crawler / test が動作することを確認済み
- Rails 8.1.2 で起動・テスト可能
- CI が全ステップ通過
