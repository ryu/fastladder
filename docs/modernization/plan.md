# Modernization Plan (fastladder → Rails 8.1 / SQLite / Hotwire)

このドキュメントは fastladder を **Rails 8.1 + SQLite** で継続運用でき、最終的に **Hotwire** に寄せるための段階的移行計画です。
リライトではなく **小さなPRの積み重ね**で進め、常に動く状態を保ちます。

- Web と crawler の2プロセス構成（foreman で同時起動）
- 目標は「壊さずに上げる」「更新し続けられる」「観測できる」

**最終更新: 2026-01-24**

---

## 0. 原則（必読）
- 1PR = 1テーマ（依存更新とUI刷新を同時にしない）
- "削除" は参照箇所の特定 + 回帰確認がセット
- crawler は特に慎重（データ破壊・重複・過剰HTTPのリスク）
- 「互換レイヤ → 移行 → 削除」の3段階で進める

---

## 1. 現状把握（最初のPR群） ✅ 完了

### Deliverables
- [x] 現在の Ruby / Rails / Bundler / Node(あれば) / DB / 主要gem を一覧化
- [x] 起動確認手順を README に明文化（web / crawler / foreman）
- [x] 主要機能（フィード登録/取得/表示、既読、更新など）を箇条書きで棚卸し
- [x] crawler の責務・入出力（DB更新、HTTP取得、重複排除）をざっくり図解

### 完了したPR
- `docs: add modernization plan and baseline notes`
- `docs: update README with requirements and development guide`

---

## 2. "壊れたら即わかる"を作る（CI/スモーク） ✅ 完了

### Goal
アップグレードの最短距離は **CIで回帰を担保すること**。

### Deliverables
- [x] CI（GitHub Actions）で `bundle install` → `test` が回る
- [x] 最低限のスモーク:
  - [x] web: 起動してトップ or 主要ページがレンダリング
  - [x] crawler: 1サイクル相当をスタブHTTPで実行（実サイトを叩かない）
- [x] SQLite の test DB セットアップをCIに含める

### Notes
- テスト基盤は minitest を使用（RSpec は使用しない）
- 外部HTTPは WebMock でスタブ

### 完了したPR
- `ci: add test workflow`
- `ci: add linting and security checks (rubocop, bundler-audit, brakeman)`
- `test: add system tests for core user flows`

---

## 3. 依存関係の健全化（小刻みに） ✅ 完了

### Goal
Rails 8.1 を「上げられる状態」にする。

### Deliverables
- [x] 依存更新を "保守的に" 進める（conservative）
- [x] deprecation / warning を減らす（ログを読める状態へ）
- [x] `bundle audit` / `brakeman` は段階導入（別PR）

### 完了したPR
- `chore: update gems conservatively`
- `chore: introduce bundler-audit`
- `chore: introduce brakeman`

---

## 4. Ruby / Rails 8.1 へ段階アップグレード ✅ 完了

### Goal
Rails 8.1 で動作し、アップグレード後も更新が回る。

### Deliverables
- [x] Ruby を target へ（CIで保証）→ Ruby 3.4.8
- [x] Rails を段階的に 8.1 へ → Rails 8.1.2
- [x] 互換レイヤ（必要な場合）の導入と、その撤去計画

### Checklist
- [x] 起動（web/crawler/foreman）
- [x] DB migration / schema 整合
- [x] 主要フローの回帰（手動 + テスト）

---

## 5. crawler の近代化（境界化 → テスト可能 → 安全運用） ✅ 完了

### Goal
crawler を「壊れにくく」「再実行安全」「観測可能」にする。

### Step A: 境界化（まずやる）
- [x] Fetch（HTTP取得、レート制限、リトライ/バックオフ）
- [x] Parse（フォーマット差異吸収、正規化）
- [x] Persist（トランザクション、重複排除、index/unique）
- [x] Report（ログ、失敗の原因がわかる）

### Step B: 安全性
- [x] idempotency（同じ入力を2回処理しても壊れない）
- [x] 多重起動対策（ロック/排他/ジョブ設計）
- [x] SQLite の特性を踏まえた書き込み設計（まとめて transaction）

### 完了したPR
- `refactor: add transaction to crawler persist operations`
- `fix: guard feed information update when parsed url is missing`
- `refactor: add Fetcher class with retry, backoff, and rate limiting`
- `refactor: add FeedParser class for feed parsing boundary`
- `refactor: add CrawlerReporter for structured logging and metrics`

---

## 6. DB（SQLite）最適化と整合性 ✅ 完了

### Goal
SQLite 前提で長期運用に耐える。

### Deliverables
- [x] 必要な index の追加（crawl_statuses.feed_id に unique index）
- [x] N+1 クエリの修正（api#subs, api#count_items, user#index, member#export）
- [x] with_unread_count スコープのバグ修正（NULL viewed_on 対応）
- [x] unique制約の追加（auth_key に partial unique index）
- [x] migration を後方互換に（段階的に）

### 完了したPR
- `perf: add database optimizations for feed queries`
- `perf: fix N+1 queries in API and user controllers`
- `chore: track db/schema.rb in version control`
- `perf: add unique index on members.auth_key for API authentication`
- `fix: make migrations backward compatible and reversible`

---

## 7. フロントを Hotwire へ段階置換 🔄 進行中

### 原則
UI刷新はアップグレード完了後に「小さく」やる。
最終到達点は Turbo/Stimulus（Hotwire）。
**重要**: 既存の LDR JavaScript との衝突を避けるため、段階的に進める。

### Step 0: Hotwire 土台（安全に導入）
- [x] turbo-rails, stimulus-rails, importmap-rails gem 追加
- [x] Turbo Drive をグローバルで無効化（既存JSとの衝突回避）
- [x] importmap 設定
- [x] 隔離されたページで最初の Stimulus controller（サインアップページ）

### Step A: 画面整理（土台）
- [x] layout/partials の整理（navigation, flash_messages を shared に抽出）
- [x] フォーム・フラッシュ・エラー表示の標準化（CSS クラス化、flash キー統一）
- [x] HAML から ERB への変換（全て完了、haml gem 削除）

### Step B: Turbo 化（価値の高い操作から）
- [~] 購読追加/削除（削除は Turbo Stream 対応完了、追加は subscribe.js のまま）
- [x] 既読マーク（touch_all Turbo Stream 対応完了）
- [x] Pin 操作（add/remove/clear Turbo Stream 対応完了）
- [x] 購読設定（rate/folder/visibility Turbo Stream 対応完了）
- [ ] 更新結果の差分反映（Turbo Streams）

### Step C: Stimulus 置換（必要な分だけ）
- [x] tab_controller, checkbox_group_controller（import/fetch ページ）
- [x] keyboard_nav_controller, hotkey_controller（mobile ページ）
- [x] form_validation_controller を import ページに適用
- [x] share_controller（share/index ページ）← LDR JS から独立していたため移行完了
- [~] 既存JSのうち、操作系をStimulus controllerへ（※大部分は LDR JS と深く統合されており、Step B の Turbo 化が先決）
- [x] 不要になった資産の削除

**注記**: reader/index, contents/manage 等の主要ページは legacy LDR JavaScript（lib/ldr.js, lib/api.js 等）と深く統合されている。これらのインライン JS を Stimulus に置換するには、まず API を Turbo Streams 対応にする必要がある（Step B）。share/index は LDR JS から独立していたため Stimulus 化完了。

**ブリッジアプローチ**: turbo_bridge.js を導入し、既存の LDR.API クラスを拡張して Turbo Stream レスポンスを自動的に処理できるようにした。これにより、LDR JS を完全に置換することなく、Turbo Stream の恩恵を受けられる。

### 完了したPR
- `feat: add Hotwire foundation with Turbo Drive disabled`
- `feat: add first Stimulus controller for password validation`
- `feat: add flash message auto-dismiss Stimulus controller`
- `feat: add form validation Stimulus controller for login page`
- `feat: apply form validation to signup page`
- `feat: apply form validation to password change page`
- `feat: add clipboard controller for API key copy`
- `refactor: convert all HAML templates to ERB and remove haml gem`
- `feat: add tab and checkbox-group Stimulus controllers`
- `feat: add keyboard navigation Stimulus controllers for mobile pages`
- `refactor: extract layout partials and standardize flash messages`
- `feat: add form validation to import page`
- `chore: remove unused JavaScript and CSS assets` (2回: 85d873b, fa64118)

---

## 8. 仕上げ（運用性・ドキュメント・削除） 🔄 進行中

### Deliverables
- [x] README/runbook を最新化（起動、ENV、トラブルシュート）
- [x] 不要コード/設定の削除（konacha.rb, IE 7 CSS, render NOTHING）
- [x] リリースノート（移行に伴う変更点・注意点）

### 完了したPR
- `docs: update README with requirements and development guide`
- `docs: update baseline and plan documentation`
- `docs: add release notes for v2.0.0`

---

## マイルストーン（目安）

| マイルストーン | 状態 | 内容 |
|--------------|------|------|
| M1 | ✅ 完了 | 現状把握 + 起動手順の明文化 |
| M2 | ✅ 完了 | CI整備 + 最低限のスモーク/回帰 |
| M3 | ✅ 完了 | 依存更新の健全化（上げられる状態） |
| M4 | ✅ 完了 | Rails 8.1 到達（web/crawler/foremanで動作） |
| M5 | ✅ 完了 | crawler 境界化 + テスト + 安全運用 |
| M6 | 🔄 進行中 | Hotwire 置換（重要操作から） |
| M7 | 🔄 進行中 | 互換レイヤ撤去 + ドキュメント完備 |

---

## 進行ログ

### 2026-01-24 (不要資産クリーンアップ 2)
- **share/index.html.erb 修正**: 冗長な `onsubmit="return false"` を削除
- **share_controller.js 修正**: search() メソッドに event.preventDefault() 追加
- **lib/share/share.js 削除**: share_controller.js で完全に置換されたため不要
- **public/swf/ 削除**: 未使用の Flash チュートリアルファイル（tutorial_ff.swf, tutorial_ie.swf）

### 2026-01-24 (Turbo Bridge: LDR JS と Turbo の統合)
- **turbo_bridge.js 作成**: LDR.API クラスを拡張して Turbo Stream サポート追加
  - 既存の LDR.API.post() メソッドを拡張
  - Turbo Stream 対応エンドポイントへのリクエストに Accept ヘッダー追加
  - Turbo Stream レスポンス時に Turbo.renderStreamMessage() で自動適用
  - JSON レスポンスは従来通り処理（後方互換性維持）
  - 対応エンドポイント: pin/add, pin/remove, pin/clear, touch_all, set_rate, move, set_public, unsubscribe
- **reader/index.html.erb 更新**:
  - javascript_importmap_tags 追加（Turbo をロード）
  - turbo_bridge.js をインクルード
- **メリット**:
  - LDR JS のコードを変更せずに Turbo Stream の恩恵を受けられる
  - 既存機能は完全に維持
  - 段階的な移行が可能

### 2026-01-24 (API Turbo Stream 対応)
- **Api::PinController Turbo Stream 対応**:
  - `add`: ピン追加時に turbo_stream でピン一覧に追加、カウント更新
  - `remove`: ピン削除時に turbo_stream で要素削除、カウント更新
  - `clear`: 全削除時に turbo_stream でリストクリア、カウントをゼロに
  - `_pin.html.erb` 部分テンプレート追加
- **ApiController#touch_all Turbo Stream 対応**:
  - 既読マーク時に turbo_stream で未読カウント表示を更新
  - 複数購読の一括既読マークに対応
- **Api::Subscriptions::RatesController Turbo Stream 対応**:
  - 評価変更時に turbo_stream で星アイコンを更新
- **Api::Subscriptions::FoldersController Turbo Stream 対応**:
  - フォルダ移動時に turbo_stream でフォルダ名表示を更新
  - バルク操作（複数購読の一括移動）に対応
- **Api::Subscriptions::VisibilitiesController Turbo Stream 対応**:
  - 公開/非公開切替時に turbo_stream で状態表示を更新
  - バルク操作（複数購読の一括変更）に対応
- **テスト追加**: 全 Turbo Stream レスポンスの検証
  - Pin コントローラ: 3テスト追加
  - API コントローラ: 2テスト追加
  - Subscription コントローラ: 6テスト追加

### 2026-01-24 (Share ページ Stimulus 移行)
- **share_controller.js 作成**: 購読共有管理ページ用の Stimulus controller（320行）
  - loadSubs: API から購読一覧を取得
  - setupMspace: フォルダ/評価のマルチセレクト生成
  - search, matchesFilter: 購読のフィルタリング（公開/非公開、購読者数、文字列、フォルダ、評価）
  - render, formatRow: 結果テーブルのレンダリング
  - rowMouseDown, rowMouseOver: ドラッグ選択
  - selectAll: 全選択/全解除
  - setQuery, resetMspace: フィルタープリセット
  - showAll: 全件表示（確認ダイアログ付き）
  - setMemberPublic: メンバー公開設定の切替
  - setPublic: 選択した購読の一括公開/非公開
  - searchDebounced: 入力遅延検索
  - escapeHtml: XSS 対策
- **share/index.html.erb 更新**:
  - 30+ の `<script>` 参照を削除（lib/share/share.js, ldr.js 等）
  - インラインの onclick を data-action に置換
  - data-controller="share" + data-share-target で Stimulus 化
  - data-share-api-key-value で ApiKey を渡す
- **テスト追加**: share_test.rb（システムテスト）

### 2026-01-24 (Turbo Stream: 購読削除 + モバイル Pin)
- **subscription_controller.js 作成**: Delete ボタン用の Stimulus controller
  - POST /api/feed/unsubscribe を fetch で呼び出し
  - Turbo Stream レスポンスで自動 DOM 更新、JSON フォールバックで手動削除
  - ローディング状態表示（Deleting...）
- **Api::SubscriptionsController#destroy 拡張**: Turbo Stream 対応
  - `respond_to` で turbo_stream / json / any フォーマットを分岐
  - turbo_stream.remove で該当 li 要素を削除
- **subscribe/confirm.html.erb 更新**:
  - li 要素に id="subscription-{id}" と data-controller="subscription" 追加
  - Delete ボタンを data-action="click->subscription#delete" に変更
- **テスト追加**: Turbo Stream レスポンスの検証
- **pin_controller.js 作成**: モバイルページの Pin 機能用 Stimulus controller
  - POST でピン作成、JSON レスポンスでインラインフィードバック
  - ページ遷移なしで "Pinned!" 表示
- **MobileController#pin 拡張**: JSON レスポンス対応
  - already_pinned フラグで重複検知を通知
- **ルート追加**: POST /mobile/:item_id/pin
- **mark_read_controller.js 作成**: モバイルページの既読マーク用 Stimulus controller
  - POST で既読化、成功後にリダイレクト
  - フィードバック表示（"Marking..." → "Done! Redirecting..."）
- **MobileController#mark_as_read 拡張**: JSON レスポンス対応
- **ルート追加**: POST /mobile/:feed_id/read
- **モバイル Pins ページ新設**: /pins でピン一覧表示
  - pin_remove_controller.js: ピン削除用 Stimulus controller（Turbo Stream 対応）
  - MobileController#pins, #remove_pin アクション追加
  - 既存の /pins リンク（mobile/index）が動作するように
- **contents/guide.html.erb 修正**: 壊れた keyboard shortcut リンクを修正
  - `<% link_to %>` (出力なし) を説明テキストに置換
  - キーボードショートカットは reader で `?` を押すと表示される旨を記載
- **システムテスト追加**: モバイルページ用
  - mobile/index、/pins ページのレンダリング検証

### 2026-01-24 (マイグレーション後方互換性 + Stimulus 移行調査)
- **バグ修正**: 009_add_items_index.rb の down メソッド修正（`remove_index :items_search_index` → `remove_index :items, name: :items_search_index`）
- **可逆性確保**: 20240816071421_items_medium_text_body.rb を `change` から `up`/`down` に変更
- **モデル依存除去**: 20140601154904_add_guid_to_items.rb から `Item.find_each` を raw SQL に置換
- **構文統一**: レガシー `def self.up`/`def self.down` を modern `def up`/`def down` に統一（001-009）
- 全マイグレーションがロールバック/再適用可能に
- **Stimulus 移行調査**: 主要ページ（reader, manage, share）のインライン JS を調査
  - 結論: 大部分は LDR JS と深く統合されており、API の Turbo 化が先決
- **import ページ改善**: form_validation_controller を適用、ファイル入力対応追加
- **form_validation_controller 拡張**: ファイル入力（type="file"）の検証に対応
- **不要資産削除**:
  - `lib/round_corner.js` - 未使用（subscribe.js に重複）
  - `lib/reader/widgets.js` - 日本語版（widgets_en.js のみ使用）
  - `reader.js`, `share.js` - 未使用の Sprockets manifest
  - `guide.css` - common.css と重複
  - `lite.css` - 未使用（モバイルは sakura.css）

### 2026-01-23 (37signals スタイル「7アクション」リファクタリング)
- **新規 RESTful コントローラー作成**:
  - Api::SubscriptionsController（show, create, update, destroy）
  - Api::Subscriptions::RatesController（update）
  - Api::Subscriptions::NotificationsController（update）
  - Api::Subscriptions::VisibilitiesController（update）
  - Api::Subscriptions::FoldersController（update）
  - Api::Feed::DiscoveriesController（create）
  - Api::Feed::FaviconsController（create）
- Api::FeedController 簡素化（add_tags, remove_tags のみ残存）
- レガシールート後方互換維持（/api/feed/subscribe 等は新コントローラにルーティング）
- テスト追加: 新コントローラ用統合テスト作成
- POST /account/password ルート追加（既存コントローラのPOST処理に対応）

### 2026-01-23 (37signals スタイル Concern 導入)
- Feed::Crawlable Concern 作成（クロールロジック分離）
- Feed::FaviconFetchable Concern 作成（favicon取得ロジック分離）
- BulkSubscriptionUpdates Controller Concern 作成（バルク操作共通化）
- Subscription#apply_settings メソッド追加（設定一括適用）
- Member#find_folder_by_name_or_id メソッド追加
- **方針**: Service Object 不使用、ドメインロジックはモデルに、Concern で整理

### 2026-01-23 (リリースノート作成)
- docs/RELEASE_NOTES.md を作成
- v2.0.0 としてリリース内容を文書化
- 破壊的変更、アップグレード手順、既知の問題を記載

### 2026-01-23 (テスト追加: 77テスト/207アサーション)
- settings_test.rb 新規作成（Settings モデル設定テスト: 7テスト）
- account_controller_test.rb 新規作成（パスワード/APIキー: 10テスト）
- export_controller_test.rb 新規作成（OPML エクスポート: 8テスト）
- contents_controller_test.rb 新規作成（ガイド/設定ページ: 6テスト）
- reader_controller_test.rb 新規作成（リーダーエントリ: 4テスト）
- share_controller_test.rb 新規作成（共有ページ: 3テスト）
- mobile_controller_test.rb 拡張（モバイル UI 全機能: 13テスト）
- rpc_controller_test.rb 拡張（API 認証/エンドポイント: 14テスト）
- subscribe_controller_test.rb 拡張（購読フロー: 8テスト）
- user_controller_test.rb 拡張（公開プロフィール/RSS/OPML: 11テスト）
- user/index.rss.builder: to_s(:rfc822) → to_fs(:rfc2822) 修正（Rails 8+ 対応、RFC 2822 は RFC 822 の後継規格）

### 2026-01-23 (不要コード削除)
- config/initializers/konacha.rb 削除（未使用テストフレームワーク設定）
- `render NOTHING` → `head :not_found` に修正（Rails 5+ 非推奨 API）
- share/index.html.erb から IE 7 条件付き CSS を削除
- ie_xmlhttp.js 簡素化（46行→3行、IE 6/7 ActiveXObject shim 削除）
- bookmarklet ページ簡素化（Flash チュートリアル、IE 検出、Firefox 2 用コンテンツ削除）

### 2026-01-23 (DB最適化: unique制約)
- members.auth_key に partial unique index 追加
- API キー重複をDB レベルで防止
- NULL 許容（auth_key 未設定のユーザー）

### 2026-01-23 (レイアウト/パーシャル整理)
- shared/_navigation.html.erb 作成（ナビゲーションを抽出）
- shared/_flash_messages.html.erb 作成（フラッシュメッセージを抽出）
- Flash メッセージのインラインスタイルを CSS に移動
- flash[:error] → flash[:alert] に統一
- MembersController の deprecated errors.map 構文を修正
- フォームバリデーションエラー用の CSS クラス追加

### 2026-01-23 (Stimulus移行: モバイルページ)
- hotkey_controller.js 追加（シンプルなキー操作トリガー）
- keyboard_nav_controller.js 追加（j/k/p/v/s キーボードナビゲーション）
- mobile/index.html.erb を hotkey controller に移行
- mobile/read_feed.html.erb を keyboard-nav controller に移行
- インライン JavaScript を Stimulus controller に置換

### 2026-01-23 (Stimulus移行: インポートページ)
- tab_controller.js 追加（タブ切替）
- checkbox_group_controller.js 追加（全選択/全解除）
- import/fetch.html.erb を Stimulus controller に移行
- インライン JavaScript を削除

### 2026-01-23 (DB最適化)
- crawl_statuses.feed_id に unique index 追加
- N+1 修正:
  - api#subs: with_unread_count スコープ使用
  - api#count_items: ROW_NUMBER() ウィンドウ関数でバッチ取得
  - api#lite_subs: favicon includes 追加
  - user#index: feed includes 追加
  - member#public_subs, member#export: feed includes 追加
- with_unread_count スコープのバグ修正（NULL viewed_on の場合に全アイテムをカウント）
- db/schema.rb をバージョン管理に追加
- .gitignore 整理（.claude/ を ignore、copilot-instructions.md を track）

### 2026-01-23 (ドキュメント整理)
- Hotwire 完了 PR リストを更新
- 進行ログを整理

### 2026-01-22 (HAML→ERB)
- 全 HAML ファイルを ERB に変換（6ファイル）
- haml gem を削除
- 変換対象: layout, sessions/new, members/new, account/apikey, mobile/index, contents/configure

### 2026-01-22 (Hotwire Step 6)
- clipboard_controller.js 追加
- API キーページにコピーボタン追加
- クリップボード API + フォールバック対応

### 2026-01-22 (Hotwire Step 5)
- パスワード変更ページに form_validation + password_match 適用
- 新パスワードと確認の一致チェック
- HTML の軽微な修正（typo、タグ閉じ忘れ）

### 2026-01-22 (Hotwire Step 4)
- form_validation をサインアップページに適用
- password_match と form_validation の複数 controller 連携
- 全フィールドに必須チェック追加

### 2026-01-22 (Hotwire Step 3)
- form_validation_controller.js 追加（フォームバリデーション）
- ログインページに適用
- 空フィールドチェック、インラインエラー表示、ローディング状態

### 2026-01-22 (Hotwire Step 2)
- flash_controller.js 追加（フラッシュメッセージ自動消去）
- notice: 5秒、alert: 8秒で自動消去
- 閉じるボタンで手動消去も可能
- 全ページに適用（レイアウト更新）

### 2026-01-22 (Hotwire Step 1)
- 最初の Stimulus controller 追加（password_match_controller.js）
- サインアップページでパスワード一致チェックのリアルタイムバリデーション
- 既存機能への影響なし（全テストパス）

### 2026-01-22 (Hotwire 土台)
- Hotwire gem 追加（turbo-rails, stimulus-rails, importmap-rails）
- Turbo Drive をグローバルで無効化（既存 LDR JavaScript との衝突回避）
- importmap 設定、Stimulus controllers ディレクトリ構成
- 既存機能への影響なし（全テストパス）

### 2026-01-22 (後半)
- Idempotency 実装完了
  - CrawlStatus.fetch_crawlable_feed に楽観的ロッキング実装（SQLite 対応）
  - 古い CRAWL_NOW 状態のリセット機能（30分以上経過したスタンバイクロール）
  - upsert_item メソッド追加（guid ベースの重複排除）
  - 一意性違反時のリトライロジック（レースコンディション対応）
- Idempotency テスト追加（10 tests）
  - CrawlStatus の原子的ロック取得テスト
  - Crawler の upsert 操作テスト
  - 重複処理の冪等性テスト

### 2026-01-22
- Fetcher クラス追加（lib/fastladder/fetcher.rb）
  - リトライ + 指数バックオフ（一時的障害の再試行）
  - レート制限（サーバーへの配慮）
  - エラー分類（リトライ可能 vs 不可能）
  - FetchResult による統一的な結果インターフェース
- Fetcher テスト追加（25 tests）
- Crawler を Fetcher 使用に更新（依存性注入対応）
- FeedParser クラス追加（lib/fastladder/feed_parser.rb）
  - RSS 1.0/2.0/Atom のフォーマット差異吸収
  - 相対URL → 絶対URL 変換（リンク、画像）
  - ParseResult/ParsedItem による正規化済みデータ構造
  - ActiveRecord 非依存（テスト容易化）
- FeedParser テスト追加（15 tests）
- Crawler を FeedParser 使用に更新（依存性注入対応）
- CrawlerReporter クラス追加（lib/fastladder/crawler_reporter.rb）
  - 構造化ログ（JSON / human-readable 切替可能）
  - メトリクス収集（成功/失敗数、アイテム数、エラー分類）
  - イベント報告（crawl/fetch/parse/items の各ライフサイクル）
  - Metrics クラスで統計集約
- CrawlerReporter テスト追加（22 tests）
- Crawler を CrawlerReporter 使用に更新（依存性注入対応）

### 2026-01-21
- ドキュメント整備: README.md を更新、baseline.md を最新化
- FactoryBot を fixtures に統一（テストデータ管理の簡素化）
- RuboCop 設定を plugins 構文に更新
- XSS 脆弱性を修正（mobile/read_feed）
- HAML から ERB へ変換（mobile/read_feed）
- モデルテストを追加（CrawlStatus, Folder, SimpleOpml, Favicon）

### 以前の作業
- Rails 8.1.2 / Ruby 3.4.8 へアップグレード完了
- CI 整備（GitHub Actions: test, lint, security）
- crawler にトランザクション追加
- システムテスト追加
