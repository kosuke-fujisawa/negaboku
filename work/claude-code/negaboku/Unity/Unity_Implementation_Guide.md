# Unity版 人間関係値ローグライクRPG - 実装ガイド

## 概要

TypeScriptで作成したプロトタイプをUnityとC#で再実装。Windows/Mac対応で将来の拡張性を考慮した設計。

## 完成した実装

### ✅ 実装完了システム

1. **プロジェクト構造** - モジュール化されたフォルダ構成
2. **キャラクターシステム** - ScriptableObjectベースのデータ駆動設計
3. **関係値システム** - リアルタイム関係値管理とイベント通知
4. **バトルシステム** - ターン制コンポーネントシステム
5. **セーブ/ロードシステム** - クロスプラットフォーム対応
6. **ダンジョンシステム** - 選択肢ベース探索システム
7. **スキルシステム** - 関係値による動的解放システム
8. **ゲーム管理システム** - 統合ゲームマネージャーとシーン管理

## アーキテクチャ特徴

### 🎯 設計原則

- **Singleton Pattern**: ゲーム状態管理
- **ScriptableObject**: データ駆動設計
- **Event-Driven**: 疎結合なシステム間通信
- **Component System**: Unity標準の拡張可能設計

### 🔧 拡張性対応

- **モジュール化**: 各システムは独立したモジュール
- **インターフェースベース**: 依存関係の抽象化
- **データ駆動**: 外部設定ファイル対応準備
- **プラットフォーム対応**: Windows/Mac固有処理の抽象化

## システム詳細

### 1. キャラクターシステム

**ファイル**: `CharacterData.cs`, `PlayerCharacter.cs`

- ScriptableObjectによるキャラクターデータ定義
- レベル成長システムとステータス計算
- 初期関係値設定とスキル管理
- セーブ/ロード対応

### 2. 関係値システム

**ファイル**: `RelationshipSystem.cs`

- 0-100の関係値管理
- 5段階の関係レベル（敵対→親密）
- バトルイベントによる動的変化
- 共闘技・対立技の使用条件判定

### 3. バトルシステム

**ファイル**: `BattleSystem.cs`, `BattleCombatant.cs`

- ターン制戦闘システム
- ステータス効果管理
- 関係値による威力修正
- AI行動決定システム

### 4. スキルシステム

**ファイル**: `SkillSystem.cs`, `SkillData.cs`

- 通常技・共闘技・対立技の3分類
- 関係値とレベルによる動的解放
- 威力修正とボーナス計算
- パーティ連携システム

### 5. ダンジョンシステム

**ファイル**: `DungeonSystem.cs`, `DungeonData.cs`

- 選択肢ベースの探索システム
- 条件分岐とイベントシステム
- 宝箱・トラップ・ボス戦
- 段階的ダンジョン解放

### 6. セーブシステム

**ファイル**: `SaveSystem.cs`

- クロスプラットフォーム対応
- 10スロット + 自動セーブ
- 暗号化機能（簡易）
- バージョン互換性チェック

### 7. ゲーム管理

**ファイル**: `GameManager.cs`, `SceneController.cs`

- 統合ゲーム状態管理
- 非同期シーン遷移
- システム間連携
- 自動セーブ機能

## プラットフォーム対応

### Windows特化機能
- Documents/My Games/でのセーブデータ管理
- Windows固有のパフォーマンス設定
- エクスプローラー連携

### Mac特化機能
- Application Support/でのセーブデータ管理
- macOS固有のパフォーマンス設定
- Finder連携

### 将来拡張対応
- Linux対応準備
- モバイル対応準備
- VR/AR対応準備
- クラウドセーブ対応準備

## 使用方法

### 1. プロジェクト設定

```csharp
// GameManager設定
[SerializeField] private GameConfiguration gameConfig;
[SerializeField] private List<CharacterData> allCharacterData;
```

### 2. キャラクター作成

```csharp
// ScriptableObjectでキャラクターデータ作成
var characterData = ScriptableObject.CreateInstance<CharacterData>();
characterData.characterName = "アキラ";
characterData.baseHP = 100;
```

### 3. ゲーム開始

```csharp
// 新しいゲーム開始
GameManager.Instance.StartNewGame("プレイヤー名");

// パーティ設定
var partyIds = new List<string> { "char_001", "char_002", "char_003", "char_004" };
GameManager.Instance.SetParty(partyIds);
```

### 4. セーブ/ロード

```csharp
// セーブ
GameManager.Instance.SaveGame(1);

// ロード
GameManager.Instance.LoadGame(1);
```

## パフォーマンス最適化

### メモリ管理
- Object Pooling準備
- 非同期ロード対応
- メモリ最適化コマンド

### 非同期処理
- Coroutineベースの処理
- フレーム分散処理
- UI応答性確保

## デバッグ機能

### エディタ拡張
- Context Menuでのデバッグ機能
- 関係値表示機能
- セーブディレクトリ表示

### ログ出力
- システム初期化ログ
- エラーハンドリング
- パフォーマンス計測

## 今後の拡張予定

### 短期
- UI実装
- アニメーション システム
- サウンドシステム

### 中期
- マルチプレイヤー対応
- ローカライゼーション
- アチーブメントシステム

### 長期
- クラウド連携
- VR/AR対応
- ストリーミング対応

## まとめ

TypeScriptプロトタイプから、Unityの特徴を活かした拡張性の高いC#実装への移行が完了。Windows/Mac対応と将来の機能拡張に対応できる堅牢な基盤が構築されました。