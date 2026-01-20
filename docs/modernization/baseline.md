# Baseline Notes (fastladder 現状把握)

このドキュメントは、近代化（Rails 8.1 / SQLite / Hotwire）を安全に進めるための「現状スナップショット」です。  
**推測で進めない**ために、まず事実をここに集めます。

- Web と crawler の2プロセス構成（foreman で同時起動） 
- 目的：アップグレードの踏み台と回帰ポイントを明確にする

---

## 1. ローカル環境情報
### 1.1 OS / 実行環境
- OS:
- CPU:
- Shell:
- Ruby version manager（mise/rbenv/asdf など）:

### 1.2 ツール
- Ruby:
- Bundler:
- Rails:
- Node（使っていれば）:
- Yarn/pnpm（使っていれば）:
- SQLite:

> コマンド例
- `ruby -v`
- `bundle -v`
- `bundle exec rails -v`
- `node -v`（あれば）
- `sqlite3 --version`

---

## 2. アプリの起動経路（重要）
### 2.1 Web
- 起動コマンド: `bundle exec rails server` 
- ポート:
- トップURL:
- ヘルスチェック（最低限見るページ）:
  - [ ] トップが表示できる
  - [ ] 主要画面が表示できる（例: フィード一覧など）

### 2.2 crawler
- 起動コマンド: `bundle exec ruby script/crawler` 
- 実行サイクル（常駐/単発/ループ）:
- 入力（何を元に動く？）:
- 出力（DBのどこを更新？）:
- エラー時の挙動（リトライ/停止/ログ）:

### 2.3 foreman
- 起動コマンド: `foreman start` 
- Procfile の役割:
- 環境変数の読み込み方法（.env など）:

---

## 3. 依存関係スナップショット
### 3.1 Gem
- Ruby / Rails:
- DB関連:
- HTTPクライアント:
- フィードパーサ:
- 認証/セッション:
- キャッシュ:
- ジョブ/スケジューラ:
- テスト:
- デプロイ/運用:

> 取得メモ（貼り付ける）
- `bundle exec ruby -e 'puts RUBY_VERSION'`
- `bundle exec rails -v`
- `bundle list | head -n 80`（長ければ一部でOK）

### 3.2 JS/CSS（あれば）
- 資産管理（Sprockets/webpacker/importmap/jsbundling等）:
- CSS（sass/tailwind/手書き）:
- 画面のJS依存（既読トグル等）:

---

## 4. DBスナップショット（SQLite）
- DBファイルの場所:
- schema 管理方式（schema.rb / structure.sql）:
- Migration の状態（古い順の課題があれば）:
- 主なテーブル（ざっくり）:
  - feeds:
  - items/entries:
  - subscriptions:
  - users/sessions:
  - その他:

### 4.1 整合性と性能の注意点（後で埋める）
- unique制約（重複防止）:
- 重要index:
- N+1が疑われる画面:

---

## 5. 主要ユースケース（回帰ポイント）
「壊れたら困るもの」を先に書く。CI/テストの最優先対象。

### Web
- [ ] フィードを追加できる
- [ ] フィード一覧が表示される
- [ ] フィードの中身（エントリ）が表示される
- [ ] 既読/未読の切り替えができる
- [ ] 更新/リロード（最新取得の反映）ができる
- [ ] （あれば）ログイン/ログアウトができる

### crawler
- [ ] 1サイクル実行できる（外部HTTPはスタブ可能）
- [ ] 既存データを壊さない
- [ ] 同じ入力を2回処理しても重複しない（idempotent）

---

## 6. 既知のレガシー課題（事実ベース）
- Rails 古さ由来の課題:
- Ruby 古さ由来の課題:
- 依存gemの問題:
- crawler の不安要素（多重起動/重複/例外握りつぶし等）:
- テストの不足:
- ドキュメント不足:

---

## 7. アップグレードの踏み台（案）
※ここは後で「実測」してから確定する（推測で決めない）

- Ruby target:
- Rails target: 8.1.x
- 段階アップグレード案:
  - Step 1:
  - Step 2:
  - Step 3:

---

## 8. 次に作るもの（M2への入口）
- [ ] CIで `bundle install` → `test` を回す
- [ ] web のスモーク（最低1ページ）
- [ ] crawler のスモーク（HTTPスタブで1サイクル）
- [ ] 失敗時に原因が追えるログの整備（段階導入）

