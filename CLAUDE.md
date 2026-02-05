# CLAUDE.md - Claude Code用プロジェクト指示書

## プロジェクト概要

FastladderはオープンソースのRSS/Atomフィードリーダー。元々は商用サービスとして開発され、個人サーバーやイントラネットでのセルフホスティング用にオープンソース化された。

## 技術スタック

| コンポーネント | バージョン |
|--------------|-----------|
| Ruby | 4.0.1 |
| Rails | 8.1.2 (`config.load_defaults 8.1`) |
| データベース | SQLite3（デフォルト）、MySQL、PostgreSQL対応 |
| フロントエンド | jQuery、Prototype.js（レガシー）、Zepto.js（モバイル） |
| テスト | Minitest、Capybara、Selenium WebDriver |

## ディレクトリ構造

```
app/
├── controllers/
│   ├── api/              # JSON APIエンドポイント (/api/*)
│   ├── api_controller.rb # レガシーAPI
│   └── rpc_controller.rb # クローラー用RPCエンドポイント
├── models/
│   ├── member.rb         # ユーザーモデル
│   ├── feed.rb           # RSS/Atomフィード
│   ├── item.rb           # フィード記事
│   └── subscription.rb   # ユーザーとフィードの関連
└── views/
    ├── reader/           # メインリーダーUI
    └── mobile/           # モバイル版

script/
└── crawler               # バックグラウンドフィードクローラー

docs/
└── rails_8_1_migration.md  # Rails 8.1移行ドキュメント
```

## 開発コマンド

```bash
# mise（Rubyバージョン管理）を使用
mise exec -- bin/rails server      # Webサーバー起動
mise exec -- bin/rails test        # 全テスト実行
mise exec -- bundle exec ruby script/crawler  # クローラー実行

# miseなし（Ruby 4.0.1がPATHにある場合）
bin/rails server
bin/rails test
bundle exec ruby script/crawler
```

## テスト

```bash
# 全テスト
bin/rails test

# カテゴリ別
bin/rails test test/controllers/   # コントローラテスト
bin/rails test test/models/        # モデルテスト
bin/rails test:system              # システム/統合テスト

# テスト数: 232件、481アサーション
```

## データベーススキーマ注意点

重要なユニーク制約:

| テーブル | カラム | 制約 |
|---------|--------|------|
| members | username | UNIQUE |
| members | auth_key | ユニーク制約なし（注意） |
| feeds | feedlink | UNIQUE |
| subscriptions | (member_id, feed_id) | UNIQUE |

## コード規約

### コントローラ

- APIエンドポイントは `render json:` でJSONを返す
- 認証済みユーザーは `current_member` を使用
- 保護されたアクションには `login_required` フィルターを使用

### モデル

- `created_at`/`updated_at` の代わりに `created_on`/`updated_on` を使用（レガシー）
- スコープはモデル内で定義（例: `Feed.crawlable`）

### ビュー

- HAMLテンプレート（`.html.haml`）
- JavaScriptは `app/assets/javascripts/` に配置

## モダナイゼーション方針

### 段階的にモダンなRails 8.1アプリケーションへと進化させます

- Turbo・Hotwireの活用
- レガシーなコードの削除または置き換え
- デザインも2026年現在にふさわしいものに

### 動作に影響のないように少しずつ進めます

- 既存機能を壊さない
- 各変更後にテストを実行
- 小さなコミット単位で進める

## エージェントワークフロー

大きな変更を行う際は以下の順序で進める:

```
rails-architect（設計・計画）
        ↓
plan-reviewer（計画レビュー）
        ↓
db-engineer（DB変更が必要な場合）
        ↓
logic-implementer（実装）
        ↓
ui-specialist（UI/UXゲート）
        ↓
qa-engineer（テスト検証）
        ↓
code-reviewer（最終レビュー）
```

## Gitワークフロー

- メインブランチ: `master`
- フィーチャーブランチ: 説明的な名前（例: `modernized`）
- コミットメッセージ: 現在形、説明的に
- 共著者: `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>`

## ロールバックポイント

大きな変更を行う前にgitタグを作成:

```bash
git tag <説明的な名前>  # 例: rails-8.0-final
```

## 既知の問題

1. **Frozen String Literal警告**（Ruby 4.0）
   - 場所: `test/models/feed_test.rb:66, :75`
   - 状態: 低優先度、表示上の問題のみ

## 重要なファイル

| ファイル | 説明 |
|---------|------|
| `config/application.rb` | Rails設定 |
| `config/settings.yml` | アプリケーション設定 |
| `db/schema.rb` | データベーススキーマ |
| `Gemfile` | Ruby依存関係 |

## APIエンドポイント

- `/api/*` - ユーザー向けJSON API
- `/rpc/*` - クローラーRPCエンドポイント（auth_key必須）

## 外部依存関係

- フィード解析: `feedjira` gem
- HTMLサニタイズ: Rails組み込みサニタイザー
