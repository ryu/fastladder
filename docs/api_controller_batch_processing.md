# ApiController バッチ処理仕様

## 概要

ApiControllerの`touch`および`crawl`アクションは、複数のsubscription IDを一括処理するバッチAPIです。

## MobileControllerとの仕様差異

| コントローラ | 仕様 | 理由 |
|------------|------|------|
| MobileController | 不正IDでエラーレスポンス（404）を返す | 単一リソース操作のため、厳密なエラーハンドリングが必要 |
| ApiController | 不正IDは無視して処理続行 | バッチ処理のため、部分的な成功を許容 |

## touch アクション

### 目的
複数のsubscriptionを一括で既読化する。

### パラメータ
- `subscribe_id`: カンマ区切りのsubscription ID文字列（例: "1,2,3"）
- `timestamp`: カンマ区切りのUNIXタイムスタンプ（例: "1234567890,1234567891,1234567892"）

### 処理仕様
1. `subscribe_id`と`timestamp`を配列に分割
2. 各IDについて:
   - 現在のユーザーのsubscriptionに存在するIDのみ処理
   - 他ユーザーのIDや存在しないIDは**無視**（エラーにしない）
   - 対応するtimestampがない場合は**スキップ**
3. 有効なsubscriptionについて`has_unread`をfalseに更新し、`viewed_on`を設定
4. 常に`{isSuccess: true}`を返す

### セキュリティ
- `@member.subscriptions.where(id: subscribe_ids)`スコープを使用し、他ユーザーのsubscriptionへのアクセスを防止
- 不正IDが混在しても処理を継続（部分的成功）

## crawl アクション

### 目的
複数のフィードを一括でクロール（更新）する。

### パラメータ
- `subscribe_id`: カンマ区切りのsubscription ID文字列（例: "1,2,3"）

### 処理仕様
1. `subscribe_id`を配列に分割
2. 各IDについて:
   - 現在のユーザーのsubscriptionに存在するIDのみ処理
   - 他ユーザーのIDや存在しないIDは**無視**（nilを結果配列に追加）
   - 有効なIDについてフィードのクロールを実行
3. **最後の有効なクロール結果**を返す（`compact.last`）
4. 全ID不正の場合は`{a: false}`を返す

### 戻り値仕様
```ruby
# 成功時
{ a: true }

# 失敗時（クロール失敗または全ID不正）
{ a: false }
```

### セキュリティ
- `@member.subscriptions.where(id: subscribe_ids)`スコープを使用し、他ユーザーのsubscriptionへのアクセスを防止
- 不正IDが混在しても処理を継続（部分的成功）
- 最後の有効なクロール結果を戻り値とする

## 実装上の注意

### バッチ処理の原則
- 一部のIDが不正でも処理を中断しない
- エラーレスポンスを返さない（常に200 OK）
- 不正IDは静かに無視する

### パフォーマンス
- `@member.subscriptions.where(id: subscribe_ids)`でユーザーのsubscriptionを一括取得
- `index_by(&:id)`でハッシュ化し、O(1)でのアクセスを実現
- N+1クエリを回避

## 変更履歴

- 2026-02-06: IDOR脆弱性修正に伴い仕様を文書化
