# Fastladder v2.0.0 Release Notes

**リリース日**: 2026-01-23

このリリースは Fastladder の大規模な近代化を含みます。Rails 8.1 / Ruby 3.4 へのアップグレード、セキュリティ強化、パフォーマンス改善、そして Hotwire への段階的移行を実施しました。

---

## 動作要件

| 項目 | バージョン |
|-----|-----------|
| Ruby | 3.4.8 |
| Rails | 8.1.2 |
| SQLite | 3.x |
| Node.js | 不要（importmap 使用） |

---

## 主な変更点

### 1. Rails 8.1 / Ruby 3.4 へのアップグレード

- **Ruby**: 3.4.8 へアップグレード
- **Rails**: 8.1.2 へアップグレード
- すべての gem 依存関係を最新の安定版に更新
- 非推奨 API の修正（`render NOTHING` → `head :not_found`、`to_s(:format)` → `to_fs(:format)` 等）

### 2. セキュリティ強化

- **XSS 脆弱性修正**: mobile/read_feed でのパラメータエスケープ漏れを修正
- **CI セキュリティチェック追加**:
  - `bundler-audit`: 依存 gem の脆弱性検査
  - `brakeman`: 静的セキュリティ解析
- **API キー一意性制約**: `members.auth_key` に partial unique index を追加

### 3. crawler の近代化

#### 境界の明確化
- **Fetcher クラス**: HTTP 取得を分離、リトライ/バックオフ/レート制限を実装
- **FeedParser クラス**: RSS 1.0/2.0/Atom の差異を吸収、URL 正規化
- **CrawlerReporter クラス**: 構造化ログ、メトリクス収集

#### 安全性の向上
- **冪等性 (Idempotency)**: 同じ入力を複数回処理しても安全
- **トランザクション**: 永続化操作をトランザクションでラップ
- **楽観的ロッキング**: 多重起動時の競合を防止
- **重複排除**: guid ベースの upsert 処理

### 4. データベース最適化

- **N+1 クエリ修正**:
  - `api#subs`: `with_unread_count` スコープで効率化
  - `api#count_items`: ウィンドウ関数でバッチ取得
  - その他多数のエンドポイントで includes/preload を追加
- **インデックス追加**:
  - `crawl_statuses.feed_id` に unique index
  - `members.auth_key` に partial unique index
- **バグ修正**: `with_unread_count` の NULL `viewed_on` 対応

### 5. Hotwire への段階的移行

#### 導入済み Stimulus コントローラー
| コントローラー | 用途 |
|--------------|------|
| `password_match_controller` | パスワード一致チェック |
| `flash_controller` | フラッシュメッセージ自動消去 |
| `form_validation_controller` | フォームバリデーション |
| `clipboard_controller` | API キーコピー |
| `tab_controller` | タブ切替 |
| `checkbox_group_controller` | 全選択/全解除 |
| `keyboard_nav_controller` | キーボードナビゲーション |
| `hotkey_controller` | ホットキー |

#### その他の UI 改善
- HAML から ERB への全面移行（haml gem 削除）
- レイアウトパーシャルの整理（navigation, flash_messages）
- Flash メッセージキーの統一（`flash[:error]` → `flash[:alert]`）

### 6. レガシーコードの削除

- **削除されたファイル/機能**:
  - `config/initializers/konacha.rb` (未使用テストフレームワーク設定)
  - IE 6/7 ActiveXObject shim (`ie_xmlhttp.js` を 46行→3行に簡素化)
  - IE 7 条件付き CSS
  - Flash チュートリアル、Firefox 2 用コンテンツ

### 7. テストカバレッジの向上

- **新規テストファイル**: 6ファイル
- **拡張テストファイル**: 4ファイル
- **追加テスト数**: 77テスト / 207アサーション
- **モデルカバレッジ**: 100% (10/10)
- **コントローラーカバレッジ**: 100% (20/20)

---

## 破壊的変更

### API の変更

なし。既存の API は互換性を維持しています。

### 設定の変更

- **Turbo Drive**: グローバルで無効化（既存 LDR JavaScript との衝突回避のため）
  - 今後の Hotwire 移行で段階的に有効化予定

### 削除された機能

- **IE 6/7 サポート**: ActiveXObject shim を削除
- **Flash Player コンテンツ**: bookmarklet ページから削除
- **Firefox 2 固有機能**: 削除

---

## アップグレード手順

### 1. 依存関係の更新

```bash
bundle install
```

### 2. データベースマイグレーション

```bash
bundle exec rails db:migrate
```

新しいマイグレーション:
- `AddUniqueIndexToCrawlStatusesFeedId`
- `AddUniqueIndexToMembersAuthKey`

### 3. 起動確認

```bash
# Web サーバー
bundle exec rails server

# crawler
bundle exec ruby script/crawler

# または foreman で同時起動
foreman start
```

### 4. 動作確認

以下の主要フローを確認してください:
1. ログイン/ログアウト
2. フィード購読
3. 記事の閲覧と既読マーク
4. crawler によるフィード更新
5. OPML インポート/エクスポート

---

## 既知の問題

### 今後対応予定

- [ ] Turbo Streams による購読追加/削除の非同期化
- [ ] Stimulus コントローラーの JS テスト追加
- [ ] `rpc#check_digest` メソッドのクエリバグ修正

---

## 貢献者

このリリースは以下の方針で開発されました:
- 「壊さずに上げる」: 小さな PR の積み重ね
- 「更新し続けられる」: CI による回帰テスト担保
- 「観測できる」: 構造化ログとメトリクス

---

## 詳細な変更履歴

詳細な変更履歴は [docs/modernization/plan.md](modernization/plan.md) の進行ログを参照してください。
