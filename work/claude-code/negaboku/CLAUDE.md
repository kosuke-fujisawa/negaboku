# CLAUDE.md

このファイルは、このリポジトリでClaude Code (claude.ai/code) が作業する際のガイダンスを提供します。

## プロジェクト概要

**Negaboku** は Unity エンジンと C# で開発された関係値重視型ダンジョン探索RPGです。Windows環境を主要ターゲットとし、将来的なMac対応も見据えた設計となっています。2人パーティによる選択肢ベースの探索システムと、-25～100の範囲で25ずつ刻みの5段階関係値システムが特徴です。

### ゲームの特徴
- **2人パーティ固定**: 濃密な関係性構築に集中
- **選択肢ベース探索**: マップではなく選択肢でダンジョンを進行
- **5段階関係値システム**: -25～100を25刻みの明確な5段階
- **関係値連動スキル**: 共闘技と対立技による戦術の多様化
- **Unity製**: クロスプラットフォーム対応可能な設計

### 技術環境
- **プラットフォーム**: Windows（主要）、Mac（将来対応）
- **ゲームエンジン**: Unity 2023.3 LTS以上
- **プログラミング言語**: C#
- **ターゲット**: .NET Standard 2.1

## 🎮 ゲームシステム仕様

### パーティシステム
- **固定2人編成**: 深い関係性の構築に特化
- **初期設定**: 最初の2キャラクターで自動編成
- **編成制限**: 必ず2人での編成が必要

### 関係値システム（5段階）
- **値の範囲**: -25～100（25刻み）
- **関係レベル**: 
  - **100-76**: 親密（最高レベル）
  - **75-51**: 友好（良好な関係）
  - **50-26**: 普通（標準的な関係）
  - **25-1**: 冷淡（やや悪い関係）
  - **0～-25**: 敵対（最悪の関係）
- **実装場所**: `Unity/Scripts/Systems/Relationship/RelationshipSystem.cs`

### ダンジョン探索システム
- **選択肢ベース**: マップ移動ではなく選択肢で進行
- **イベント駆動**: DungeonEventによる物語進行
- **関係値連動**: 選択の結果が関係値に直接影響
- **実装場所**: `Unity/Scripts/Systems/Dungeon/DungeonSystem.cs`

### スキルシステム
- **共闘技**: 高関係値（76以上・親密レベル）で発動可能
- **対立技**: 低関係値（0以下・敵対レベル）で発動可能
- **実装場所**: `Unity/Scripts/Systems/Skill/SkillSystem.cs`

## 🏗️ Unityプロジェクト構造

### Scripts階層
```
Unity/Scripts/
├── Core/                         # コアシステム
│   ├── GameManager.cs           # ゲーム全体管理
│   └── SceneController.cs       # シーン遷移管理
├── Data/                        # データ定義（ScriptableObject）
│   ├── Character/               # キャラクターデータ
│   │   └── CharacterData.cs     
│   ├── Dungeons/                # ダンジョンデータ
│   │   └── DungeonData.cs       
│   └── Skills/                  # スキルデータ
│       └── SkillData.cs         
├── Systems/                     # ゲームシステム
│   ├── Battle/                  # 戦闘システム
│   │   ├── BattleSystem.cs      
│   │   └── BattleCombatant.cs   
│   ├── Dungeon/                 # ダンジョンシステム
│   │   └── DungeonSystem.cs     
│   ├── Relationship/            # 関係値システム
│   │   └── RelationshipSystem.cs
│   ├── Save/                    # セーブシステム
│   │   └── SaveSystem.cs        
│   └── Skill/                   # スキルシステム
│       └── SkillSystem.cs       
├── UI/                          # UIシステム
│   ├── Battle/                  # バトル画面UI
│   ├── Common/                  # 共通UI
│   ├── Dungeon/                 # ダンジョン画面UI
│   └── Menus/                   # メニュー画面UI
├── Characters/                  # キャラクター制御
│   └── PlayerCharacter.cs       
└── Utilities/                   # ユーティリティ
    ├── Constants/               # 定数定義
    ├── Extensions/              # 拡張メソッド
    └── Helpers/                 # ヘルパークラス
```

### Assets構成
```
Unity/
├── Scenes/                      # シーンファイル
├── Resources/                   # リソースファイル
│   ├── Characters/              # キャラクターデータ
│   ├── Dungeons/                # ダンジョンデータ
│   └── Skills/                  # スキルデータ
├── Prefabs/                     # プレファブ
│   ├── Characters/              # キャラクター
│   ├── Effects/                 # エフェクト
│   └── UI/                      # UI部品
└── StreamingAssets/             # 設定ファイル
    └── Config/                  # ゲーム設定
```

## 🛠️ 開発コマンド

### Unity開発環境
```bash
# Unity Editorを開く
# - Unity Hub経由でプロジェクトを開く
# - またはコマンドラインから：
"C:\Program Files\Unity\Hub\Editor\[VERSION]\Editor\Unity.exe" -projectPath "path\to\negaboku\Unity"

# Windows向けビルド
# Unity Editor: File > Build Settings > PC, Mac & Linux Standalone > Target Platform: Windows
# Architecture: x86_64

# Mac向けビルド（将来対応）
# Unity Editor: File > Build Settings > PC, Mac & Linux Standalone > Target Platform: macOS
```

### 開発用ツール
```bash
# Visual Studio / Visual Studio Code
# Unity統合開発環境として使用

# Git管理
git add .
git commit -m "[Unity] 機能追加"
git push origin main
```

## 📋 開発ガイドライン

### C# コーディング規約
- **命名規則**: 
  - クラス: PascalCase (`GameManager`)
  - メソッド: PascalCase (`StartGame`)
  - プロパティ: PascalCase (`CurrentLevel`)
  - フィールド: camelCase （privateは`_`プレフィックス）
  - 定数: UPPER_SNAKE_CASE (`MAX_RELATIONSHIP`)

### Unity固有の規約
- **MonoBehaviour**: UI制御、ゲームオブジェクト管理
- **ScriptableObject**: データ定義、設定管理
- **Singleton**: ゲーム状態管理（GameManager等）
- **Coroutine**: 非同期処理、アニメーション
- **Event System**: システム間通信

### アーキテクチャ原則
1. **MVPパターン**: UI分離による保守性向上
2. **Component System**: Unity標準の拡張可能設計
3. **Data-Driven**: ScriptableObjectによるデータ駆動
4. **Event-Driven**: 疎結合なシステム間通信

## 🎯 関係値システム詳細（5段階）

### 関係値の変動幅
- **大きな協力**: +25（1段階アップ）
- **小さな協力**: +12～13（半段階アップ）
- **中立的行動**: 変化なし
- **小さな対立**: -12～13（半段階ダウン）
- **大きな対立**: -25（1段階ダウン）

### レベル別特徴
1. **親密（100-76）**: 
   - 共闘技が最大威力で発動
   - 特別なイベント選択肢が出現
   - エンディングに大きく影響

2. **友好（75-51）**: 
   - 共闘技が発動可能
   - 協力的な選択肢が増加
   - 戦闘でのサポート効果

3. **普通（50-26）**: 
   - 標準的な相互作用
   - バランスの取れた選択肢
   - 基本スキルのみ使用可能

4. **冷淡（25-1）**: 
   - 協力的な行動が制限
   - 一部の選択肢が封印
   - 戦闘効率の低下

5. **敵対（0～-25）**: 
   - 対立技が発動可能
   - ネガティブイベントが発生
   - 特殊エンディング分岐

## 🚀 開発ロードマップ

### Phase 1: コアシステム実装
- [ ] GameManagerの完全実装
- [ ] 5段階関係値システムのUnity統合
- [ ] 基本UI画面の作成
- [ ] セーブ/ロードシステム実装

### Phase 2: ゲームプレイ実装
- [ ] ダンジョン探索システム
- [ ] 戦闘システムの実装
- [ ] スキルシステムの統合
- [ ] イベントシステムの構築

### Phase 3: プラットフォーム最適化
- [ ] Windows向け最適化
- [ ] Mac対応の準備
- [ ] パフォーマンス最適化
- [ ] リリース準備

## 🔧 技術仕様

### 開発環境要件
- **Unity**: 2023.3 LTS以上
- **Visual Studio**: 2022以上 (Windows)
- **Visual Studio Code**: Unity拡張機能
- **.NET**: Standard 2.1
- **Git**: バージョン管理

### プラットフォーム対応
- **Windows**: x64対応、.NET Standard 2.1
- **Mac**: Intel/Apple Silicon対応（将来）
- **将来対応予定**: Linux、モバイル

### Unity設定
- **Scripting Backend**: IL2CPP
- **API Compatibility Level**: .NET Standard 2.1
- **Target Architecture**: x86_64
- **Color Space**: Linear

## 📝 コミット規約

### コミットメッセージ形式
```
[Unity][システム名] 機能概要

詳細説明（必要に応じて）

関連する関係値への影響や選択肢の追加など
```

### 例
```bash
git commit -m "[Unity][関係値] 5段階関係値システムの実装

-25～100を25刻みの5段階に設定
各段階での特別な効果とスキル発動条件を追加"
```

## 🎮 ゲームプレイテスト

### Unity Editor内テスト
```csharp
// 関係値システムテスト（5段階）
[ContextMenu("Test 5-Level Relationship System")]
void TestRelationshipSystem()
{
    // 段階的な関係値変動テスト
    RelationshipSystem.Instance.ModifyRelationship("char1", "char2", 25);
    Debug.Log($"関係値: {RelationshipSystem.Instance.GetRelationshipValue("char1", "char2")}");
    Debug.Log($"関係レベル: {RelationshipSystem.Instance.GetRelationshipLevel("char1", "char2")}");
}

// 各段階のスキル発動テスト
[ContextMenu("Test Skill Activation by Level")]
void TestSkillActivation()
{
    // 親密レベルでの共闘技テスト
    // 敵対レベルでの対立技テスト
}
```

## 📊 品質管理

### ゲーム品質（5段階システム）
- **関係値バランス**: -25～100の5段階分布
- **段階変動の意味**: 各25ポイントの変化が明確な違いをもたらす
- **スキル発動条件**: 親密（76+）と敵対（0-）での明確な差別化
- **プレイヤビリティ**: 2人パーティでの戦術的深み

## 💾 セーブシステム

### Unity固有の実装
```csharp
[System.Serializable]
public class SaveData
{
    public string playerName;
    public int playTime;
    public GameProgress gameProgress;
    public Character[] party;
    public RelationshipMatrix relationships; // -25～100の5段階値
    // ... その他のデータ
}
```

## 📋 ライセンス管理ガイドライン

### 非商用ライセンスの適用

**Negaboku**は独自の非商用ライセンスを採用しています：

#### ライセンス原則
- **非商用利用限定**: 一切の商用利用を禁止
- **教育・学習目的**: 個人学習と教育機関での使用を推奨
- **オープンソース貢献**: 改変と再配布は同ライセンス下で許可
- **帰属表示義務**: 原作者クレジットとライセンス表示が必要

#### 開発時の注意事項

1. **第三者アセットの管理**
   - Unity Asset Storeアセットのライセンス確認
   - フリー素材の利用条件遵守
   - 商用利用可能素材のみ使用推奨

2. **コード管理**
   - 新規作成ファイルへのライセンス表示
   - 第三者ライブラリの依存関係確認
   - ライセンス互換性の検証

3. **Unity固有の考慮事項**
   - Unity Personal/Pro/Enterpriseライセンスとの整合性
   - Unity製ビルドターゲットでのライセンス表示
   - プラットフォーム固有の法的要件確認

#### コミュニティ対応

- **商用利用相談**: 別途商用ライセンス契約の提案
- **派生作品**: 同ライセンス下での二次創作許可
- **貢献者への配慮**: コントリビューター権利の明確化

#### 法的保護

- **知的財産権**: オリジナルコンテンツの著作権保護
- **商標管理**: プロジェクト名とロゴの使用制限
- **免責事項**: 適切な責任制限条項の設定

### ライセンス更新プロセス

1. **変更検討**: 法的要件や事業戦略の変化に応じた見直し
2. **コミュニティ通知**: 既存ユーザーへの事前告知
3. **文書更新**: LICENSE、README.md、CLAUDE.mdの同期更新
4. **バージョン管理**: ライセンス変更履歴の記録

## 🤖 Claude Code 作業要件

### 応答言語
- **日本語応答必須**: Claude Codeは全ての応答を日本語で行うこと
- **技術文書**: コメント、ドキュメント、コミットメッセージも日本語で統一
- **例外**: コード内の変数名、関数名、ファイル名は英語を使用

### コードレビュープロセス
- **本番マージ前**: 必ずプルリクエスト（PR）を作成すること
- **CodeRabbitレビュー**: @coderabbitai によるレビューを受けること
- **レビュー対応**: 指摘事項は必ず修正してからマージ実行
- **品質保証**: 法的表現、技術仕様、文書整合性の確認

#### プルリクエスト作成手順
1. **フィーチャーブランチ作成**: `feature/機能名` の命名規則
2. **変更内容の詳細説明**: PRでの変更概要と影響範囲を明記
3. **CodeRabbit呼び出し**: `@coderabbitai` メンションでレビュー依頼
4. **レビュー修正**: 指摘事項への対応と再確認
5. **承認後マージ**: すべてのチェックが完了後にマージ実行

### 継続的改善
- **ガイドライン更新**: このファイル自体も同じプロセスを適用
- **品質向上**: レビューフィードバックを次回開発に反映
- **文書同期**: README.md、LICENSE等の関連文書も一貫性を保持

---

このプロジェクトは Unity エンジンを活用し、-25から100までを25刻みの明確な5段階関係値システムを核とした革新的なRPG体験の創造を目指しています。Windows環境での安定動作を最優先とし、将来的なMac対応も見据えた拡張可能な設計を心がけてください。