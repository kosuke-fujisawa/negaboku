# Godot実装指針書

> **🔄 Godot移行完了**: Unity版の指針をGodot 4.x + GDScriptに適応し、より効率的な開発指針に更新しました。

## Godotデータ管理

### ✅ 実装済みデータシステム
- **関係値データ**: Dictionary 形式での内部管理、JSON 永続化 ✅
- **キャラクターデータ**: extends Resource による型安全管理 ✅
- **セーブシステム**: JSON 形式での可読性・デバッグ性確保 ✅
- **利点**: GDScript の動的型と Resource システムの活用

### セーブデータ仕様（実装済み）
- **関係値状態**: 全キャラクター間の関係値 Dictionary ✅
- **パーティ情報**: キャラクターリソースの配列管理 ✅
- **形式**: `FileAccess` + `JSON.stringify()` による標準実装 ✅

## Godotテスト戦略

### ✅ 実装済み動作確認
- **関係値システム**: リアルタイムデバッグ機能で境界値・異常値テスト完了 ✅
- **バトルシステム**: AI 行動・ターン制御・スキル発動の動作確認済み ✅
- **UIシステム**: ダイアログ・選択肢・エフェクトの統合テスト完了 ✅
- **セーブ・ロード**: JSON 永続化の動作確認済み ✅

### 将来のテスト自動化
- **GDScript Testing**: Godot 標準のテストフレームワーク活用予定
- **統合テスト**: Scene 単位での自動テスト環境構築
- **デバッグ機能**: リアルタイム関係値操作による手動テスト継続

## GDScriptコーディング規約

### ✅ 適用済み命名規則
- **クラス名**: PascalCase + class_name (`RelationshipSystem`) ✅
- **ファイル名**: snake_case (`relationship.gd`) ✅
- **メソッド**: snake_case (`modify_relationship_value`) ✅
- **変数**: snake_case (`current_level`) ✅
- **定数**: UPPER_SNAKE_CASE (`MAX_RELATIONSHIP_VALUE`) ✅
- **Signal**: snake_case (`relationship_changed`) ✅

### Godot設計原則
- **Scene + Node**: Godot 標準の階層構造活用 ✅
- **Signal-driven**: 疎結合な通信システム ✅
- **Resource extends**: データ定義の型安全性確保 ✅
- **AutoLoad**: グローバルシステムの管理 ✅

### ✅ 実装済みGodot固有規約
- **Node継承**: システム管理、UI 制御 ✅
- **Resource継承**: データ定義、永続化 ✅
- **await + Tween**: 非同期処理、アニメーション ✅
- **Signal System**: イベント通信、状態通知 ✅

## パフォーマンス考慮事項

### メモリ管理
- **Object Pooling**: 頻繁に生成・破棄されるオブジェクトの再利用
- **Garbage Collection**: 不要なメモリ割り当ての回避
- **Asset管理**: プラットフォーム別 AssetBundle 対応

### 処理最適化
- **Coroutines**: 重い処理の分散実行
- **Update最適化**: 不要な Update 呼び出しの削減
- **描画最適化**: バッチング、テクスチャ圧縮の活用
