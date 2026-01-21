# Modernization Plan (fastladder → Rails 8.1 / SQLite / Hotwire)

このドキュメントは fastladder を **Rails 8.1 + SQLite** で継続運用でき、最終的に **Hotwire** に寄せるための段階的移行計画です。
リライトではなく **小さなPRの積み重ね**で進め、常に動く状態を保ちます。

- Web と crawler の2プロセス構成（foreman で同時起動）
- 目標は「壊さずに上げる」「更新し続けられる」「観測できる」

**最終更新: 2026-01-21**

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

## 5. crawler の近代化（境界化 → テスト可能 → 安全運用） 🔄 進行中

### Goal
crawler を「壊れにくく」「再実行安全」「観測可能」にする。

### Step A: 境界化（まずやる）
- [ ] Fetch（HTTP取得、レート制限、リトライ/バックオフ）
- [ ] Parse（フォーマット差異吸収、正規化）
- [x] Persist（トランザクション、重複排除、index/unique）
- [ ] Report（ログ、失敗の原因がわかる）

### Step B: 安全性
- [ ] idempotency（同じ入力を2回処理しても壊れない）
- [ ] 多重起動対策（ロック/排他/ジョブ設計）
- [x] SQLite の特性を踏まえた書き込み設計（まとめて transaction）

### 完了したPR
- `refactor: add transaction to crawler persist operations`
- `fix: guard feed information update when parsed url is missing`

---

## 6. DB（SQLite）最適化と整合性 📋 未着手

### Goal
SQLite 前提で長期運用に耐える。

### Deliverables
- [ ] 必要な index の追加（N+1も合わせて潰す）
- [ ] unique制約の追加（重複排除の最後の砦）
- [ ] migration を後方互換に（段階的に）

---

## 7. フロントを Hotwire へ段階置換 📋 未着手

### 原則
UI刷新はアップグレード完了後に「小さく」やる。
最終到達点は Turbo/Stimulus（Hotwire）。

### Step A: 画面整理（土台）
- [ ] layout/partials の整理
- [ ] フォーム・フラッシュ・エラー表示の標準化
- [x] HAML から ERB への変換（一部実施）

### Step B: Turbo 化（価値の高い操作から）
- [ ] 購読追加/削除
- [ ] 既読/未読切替
- [ ] 更新結果の差分反映（Turbo Streams）

### Step C: Stimulus 置換（必要な分だけ）
- [ ] 既存JSのうち、操作系をStimulus controllerへ
- [ ] 不要になった資産の削除（別PR）

### 完了したPR
- `refactor: convert mobile/read_feed from haml to erb`

---

## 8. 仕上げ（運用性・ドキュメント・削除） 🔄 進行中

### Deliverables
- [x] README/runbook を最新化（起動、ENV、トラブルシュート）
- [ ] 不要コード/設定の削除（互換レイヤ撤去）
- [ ] リリースノート（移行に伴う変更点・注意点）

### 完了したPR
- `docs: update README with requirements and development guide`
- `docs: update baseline and plan documentation`

---

## マイルストーン（目安）

| マイルストーン | 状態 | 内容 |
|--------------|------|------|
| M1 | ✅ 完了 | 現状把握 + 起動手順の明文化 |
| M2 | ✅ 完了 | CI整備 + 最低限のスモーク/回帰 |
| M3 | ✅ 完了 | 依存更新の健全化（上げられる状態） |
| M4 | ✅ 完了 | Rails 8.1 到達（web/crawler/foremanで動作） |
| M5 | 🔄 進行中 | crawler 境界化 + テスト + 安全運用 |
| M6 | 📋 未着手 | Hotwire 置換（重要操作から） |
| M7 | 🔄 進行中 | 互換レイヤ撤去 + ドキュメント完備 |

---

## 進行ログ

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
