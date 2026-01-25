# CLAUDE.md (fastladder modernization)

このリポジトリは Fastladder Open Source (OpenFL) の Rails アプリです。RSS/Atom フィードを収集・表示します。 
本アプリは「Web」と「crawler」の2プロセス構成です（`rails server` と `script/crawler`。foreman でも起動）。 

## 目標（確定）
- Rails: **8.1 系**
- DB: **SQLite**
- フロント: **最終的に Hotwire（Turbo/Stimulus）へ置き換える**
- ただし、移行は段階的に行い、常に動く状態を保つ（大規模リライト禁止）

---

## あなた(Claude)へのゴール
レガシー Rails アプリを **Rails 8.1 / Ruby 最新安定** で継続運用できる形に近代化してください。
最優先は「壊さずに上げる」こと。小さく、安全に、観測可能に。

### “モダン”の定義（このプロジェクト）
優先度順:

1. Rails 8.1 で開発・起動・デプロイ（最低でも同等環境）が可能
2. 依存関係の更新が継続可能（CIで検証、脆弱性検知）
3. 回帰テストが整備され、web/crawler の主要ユースケースが守られる
4. SQLite 前提でパフォーマンスと整合性（index/transaction/locking）に配慮
5. 画面は最終的に Hotwire に寄せる（置換の途中は “暫定UI” を許す）
6. Rails らしい責務分割（境界が明確。変更に強い）

---

## 絶対に守る制約
- 既存仕様を推測で変えない（変えるなら理由・影響・移行手順を明記）
- 1PR = 1テーマ（依存更新とUI刷新を同時にやらない）
- “削除” は参照箇所の特定 + テスト/回帰確認がセット
- crawler は特に慎重に（データ破壊・過剰HTTP・重複処理のリスク）

---

## 作業の進め方（毎回この順）
1. **現状把握**: 対象機能の起動経路（web/crawler）と設定を確認
2. **安全策**: まず回帰確認（テスト or 手動スモーク）を用意
3. **小さく実装**: 互換レイヤを挟んで段階移行（アダプタ歓迎）
4. **検証**: 該当テスト + web 起動 + crawler 1サイクルの確認
5. **片付け**: 互換レイヤの撤去は “次PR” に回す
6. **ドキュメント更新**: README / ENV / 運用手順 を更新

---

## Rails 8.1 へのアップグレード方針
- “飛び級” は避ける（破壊的変更を一度に飲み込まない）
- Gem 更新は `bundle update --conservative` を基本
- 破壊的変更は 3段階:
  1) 互換レイヤ導入
  2) 新方式へ移行
  3) 旧方式を削除

---

## DB: SQLite 方針（重要）
SQLite を前提に設計・改善する。特に以下に注意:
- 書き込みはトランザクションを意識（crawler 側でまとめる）
- インデックスを適切に（feed_id, created_at, unique 制約など）
- N+1 を避ける（includes/preload）
- ロック/同時実行：crawler 多重起動の防止、idempotency（再実行安全）を設計する

---

## crawler（最重要）
crawler は Web とは別プロセスです。 
近代化の第一歩は「crawler の境界を作ってテスト可能にする」こと。

### まず作るべき境界（おすすめ）
- Fetch（HTTP取得、レート制限、リトライ/バックオフ）
- Parse（フォーマット差異吸収、正規化）
- Persist（DB永続化、重複排除、トランザクション）
- Report（ログ、失敗の可観測性）

### crawler のルール
- 外部HTTPはテストでは必ずスタブ（実サイトを叩かない）
- 同じ入力を2回処理しても壊れない（idempotent）
- 失敗は “原因がわかるログ” を残す（例外握りつぶし禁止）

---

## フロント: Hotwire への置換方針
最終的に Turbo/Stimulus に寄せるが、移行は段階的。

### 優先順位
1. まずは Rails 8.1 の標準に寄せる（ERB/partials/layout整理）
2. 重要な操作（購読追加、既読、更新）を Turbo で強化
3. JS依存がある場合は Stimulus へ移設
4. 置換完了後に不要資産（古いJS/CSS、古いテンプレ）を削除

### 禁止事項
- “全部を一気に Hotwire 化” しない（バグが混ざる）
- UI刷新とRailsアップグレードを同じPRでやらない

---

## テスト方針
- 既存が minitest なら minitest 継続、RSpec なら RSpec 継続（混在させない）
- 最初に守るべき回帰ポイント:
  - フィード登録〜取得〜表示
  - crawler 1サイクル（HTTPはスタブ）
  - 主要画面の最低限レンダリング（リグレッション検知）
- 外部HTTP: VCR/WebMock 等で必ずスタブ

---

## 依存関係 / セキュリティ / 品質
- secrets をコミットしない（ENV / credentials）
- CI で最低限:
  - bundle install
  - lint（必要なら rubocop）
  - test
  - （可能なら）`bundle audit` / `brakeman` を段階導入
- 変更の大きい導入（rubocop等）は “別PR” にする

---

## 出力フォーマット（あなたが返すべき内容）
提案や実装のたび、必ず以下をセットで返す:

- 目的（なぜ）
- 変更内容（何を）
- 影響範囲（どこが壊れうるか）
- 検証方法（コマンド/手順）
- ロールバック方法（戻し方）
- 次の一手（次PR候補）

---

## 現状の起動コマンド
- Web: `bundle exec rails server`
- crawler: `bundle exec ruby script/crawler`
- foreman: `foreman start`（web/crawler同時）

---

## 変更前の検証（必須）
変更をコミットする前に、必ず `bin/ci` を実行して全チェックをパスすることを確認する。

```bash
bin/ci
```

このコマンドは以下を順番に実行する:
- Setup（依存関係とDB準備）
- Security: Gem audit（脆弱性チェック）
- Security: Brakeman（静的セキュリティ解析）
- Lint: RuboCop（コードスタイル）
- Tests: Rails（ユニット/統合テスト）
- Tests: System（ブラウザテスト）
- Tests: Seeds（シードデータ検証）

全てパスしないとコミットしない。 

