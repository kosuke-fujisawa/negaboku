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
- **ゲームエンジン**: Unity 6000.1.13f1以上（Unity 6）
- **プログラミング言語**: C#
- **ターゲット**: .NET Standard 2.1
- **開発手法**: TDD（テスト駆動開発）- twadaスタイル
- **アーキテクチャ**: DDD + クリーンアーキテクチャ

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

### 💡 開発思想・原則

#### アーキテクチャ設計思想
- **DDD（ドメイン駆動設計）とクリーンアーキテクチャを併用**: ゲームロジックを中心とした設計
- **依存方向の統一**: ドメイン → アプリケーション → UI の一方向依存
- **ドメイン層の独立性**: ゲームロジック（戦闘・関係値・イベント管理）を完結させ、UIや入出力に依存しない設計
- **テスタビリティ重視**: 外部依存を排除したユニットテスト可能な設計

#### 移植性・拡張性
- **初期ターゲット**: Windows環境での安定動作を最優先
- **将来的移植性**: Mac/Linuxへの移植を視野に入れたOS依存処理の抽象化
- **インターフェース駆動**: プラットフォーム固有処理は抽象化インターフェース経由で実装
- **データ駆動設計**: ゲームデータを外部化し、容易な拡張・変更を可能にする

### 🧪 開発手法

#### TDD（テスト駆動開発）- twadaスタイル
- **Red-Green-Refactor**: 失敗するテスト → 通るコード → リファクタリング
- **テストファーストの徹底**: 実装前に必ずテストを作成
- **小さな単位での実装**: 1つのテストに対して最小限の実装
- **継続的リファクタリング**: グリーンになった後の品質向上

```csharp
// テスト例
[Test]
public void 関係値が25増加したとき_普通から友好レベルに変化する()
{
    // Arrange
    var relationship = new RelationshipValue(-25, 100, 25);
    relationship.SetValue(50); // 普通レベル
    
    // Act
    relationship.ModifyValue(25);
    
    // Assert
    Assert.AreEqual(RelationshipLevel.友好, relationship.GetLevel());
}
```

#### Tidy First原則
- **リファクタリングを小さく頻繁に**: 大きな変更前の準備
- **構造の整理を優先**: 機能追加前にコードを理解しやすくする
- **段階的改善**: 一度に全てを変更しない
- **安全な変更**: テストによる安全網の活用

#### DRY原則（Don't Repeat Yourself）
- **重複コードの排除**: 同じロジックの共通化
- **設定の一元化**: 定数やマジックナンバーの統一管理
- **テンプレート化**: 類似パターンの抽象化
- **ただし適度に**: 無理な共通化は避ける

### 🏗️ アーキテクチャ設計

#### DDD（ドメイン駆動設計）
- **ドメインモデル中心**: ゲームルールをコードで表現
- **ユビキタス言語**: ドメインエキスパートと開発者の共通言語
- **境界付きコンテキスト**: システム間の明確な分離
- **集約とエンティティ**: データの整合性を保つ設計

```csharp
// ドメインモデル例
public class RelationshipAggregate
{
    private readonly RelationshipValue _value;
    private readonly List<RelationshipEvent> _events;
    
    public void ModifyRelationship(int amount, string reason)
    {
        var oldLevel = _value.GetLevel();
        _value.ModifyValue(amount);
        var newLevel = _value.GetLevel();
        
        if (oldLevel != newLevel)
        {
            _events.Add(new RelationshipLevelChangedEvent(oldLevel, newLevel, reason));
        }
    }
}
```

#### クリーンアーキテクチャ
- **依存関係の逆転**: 外側が内側に依存、内側は外側を知らない
- **レイヤー分離**: Entities → Use Cases → Interface Adapters → Frameworks
- **ビジネスルールの保護**: フレームワークから独立したドメインロジック
- **テスタブルな設計**: 外部依存を排除したユニットテスト

```
Unity/Scripts/
├── Domain/                    # エンティティとビジネスルール
│   ├── Entities/             # ドメインエンティティ
│   ├── ValueObjects/         # 値オブジェクト
│   └── Services/            # ドメインサービス
├── Application/              # ユースケース
│   ├── UseCases/            # アプリケーションサービス
│   └── Interfaces/          # リポジトリインターフェース
├── Infrastructure/           # 外部システム接続
│   ├── Repositories/        # データ永続化
│   └── Unity/              # Unity固有実装
└── Presentation/            # UI・入力制御
    ├── Controllers/         # MVPのPresenter
    └── Views/              # Unity UI
```

### 🔧 クロスプラットフォーム対応

#### プラットフォーム抽象化
- **条件付きコンパイル**: `#if UNITY_STANDALONE_WIN` の適切な使用
- **インターフェース分離**: プラットフォーム固有処理の抽象化
- **設定ファイル分離**: Windows/Mac用の別設定管理
- **パス処理統一**: `Path.Combine()` など標準ライブラリの活用

```csharp
// プラットフォーム抽象化例
public interface IPlatformService
{
    string GetSaveDataPath();
    void ShowNotification(string message);
}

#if UNITY_STANDALONE_WIN
public class WindowsPlatformService : IPlatformService { }
#elif UNITY_STANDALONE_OSX
public class MacPlatformService : IPlatformService { }
#endif
```

#### Unity設定の統一
- **Scripting Backend**: IL2CPP（両プラットフォーム対応）
- **API Compatibility Level**: .NET Standard 2.1
- **Asset管理**: プラットフォーム別AssetBundle対応
- **入力システム**: New Input System使用（クロスプラット対応）

### 📝 C# コーディング規約

#### 命名規則
- **クラス**: PascalCase (`RelationshipSystem`)
- **メソッド**: PascalCase (`ModifyRelationshipValue`)
- **プロパティ**: PascalCase (`CurrentLevel`)
- **フィールド**: camelCase （privateは`_`プレフィックス `_currentValue`）
- **定数**: UPPER_SNAKE_CASE (`MAX_RELATIONSHIP_VALUE`)
- **インターフェース**: I + PascalCase (`IRelationshipRepository`)

#### 設計原則
- **SOLID原則**: 単一責任、開放閉鎖、リスコフ置換、インターフェース分離、依存性逆転
- **Tell, Don't Ask**: オブジェクトにデータを要求するのではなく、やりたいことを伝える
- **Law of Demeter**: 直接の友達とのみ話す
- **Composition over Inheritance**: 継承より合成を優先

### 🧪 テスト戦略

#### テストピラミッド
- **Unit Tests**: ドメインロジックの詳細テスト（多数）
- **Integration Tests**: システム間連携テスト（中程度）
- **E2E Tests**: ゲームプレイ全体テスト（少数）

#### Unity Test Framework活用
- **Edit Mode Tests**: MonoBehaviourに依存しないロジックテスト
- **Play Mode Tests**: Unity環境でのインテグレーションテスト
- **Performance Tests**: フレームレートやメモリ使用量の監視

```csharp
// Unity Test例
[UnityTest]
public IEnumerator 関係値システム_実際のゲーム環境での動作確認()
{
    // Arrange
    var gameObject = new GameObject();
    var relationshipSystem = gameObject.AddComponent<RelationshipSystem>();
    
    // Act
    relationshipSystem.Initialize();
    yield return new WaitForSeconds(0.1f);
    
    // Assert
    Assert.IsTrue(relationshipSystem.IsInitialized);
}
```

### Unity固有の規約
- **MonoBehaviour**: UI制御、ゲームオブジェクト管理に限定
- **ScriptableObject**: データ定義、設定管理
- **Singleton**: 必要最小限に抑制、DIコンテナ活用を検討
- **Coroutine**: 非同期処理、アニメーション（async/awaitも検討）
- **Event System**: 疎結合なシステム間通信

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

## 🎯 開発範囲（初期モック）

### 必須機能

#### バトルシステム
- **2人パーティ制**: 固定2人編成による戦略的バトル
- **ターン制コマンドバトル**: 明確な戦術選択と結果予測
- **関係値連動技**: 好感度で共闘技・対立技の発動条件が変化
- **敵AIシステム**: シンプルなAI（HP減少でフェーズ変化）
- **実装優先度**: 最高（ゲームの核心システム）

#### 関係値管理システム
- **数値範囲**: -25～100の5段階明確化
- **変動条件**: 戦闘・イベントでの増減ロジック
- **閾値管理**: 特定閾値でイベント分岐・技解放
- **永続化**: セーブデータへの関係値状態保存
- **実装優先度**: 最高（ゲーム差別化要素）

#### イベント管理システム
- **表示機能**: テキスト＋立ち絵表示
- **分岐条件**: 関係値・進行度に応じた動的表示
- **データ駆動**: JSON/CSVによる外部データ管理
- **拡張性**: 新規イベント追加の容易性確保
- **実装優先度**: 高（ストーリー進行の基盤）

### 後から追加する要素

#### 探索・マップ要素
- **現段階**: 選択肢による移動システム（簡易実装）
- **将来拡張**: 実際のマップ探索、ダンジョン構造
- **優先度**: 中（基本システム完成後）

#### 追加コンテンツ
- **DLCキャラクター**: 既存システムでの新キャラ追加
- **追加ストーリー**: イベントシステム拡張での対応
- **優先度**: 低（基本完成後の拡張要素）

#### 高度なUI演出
- **カットイン演出**: 戦闘・イベント時の視覚効果
- **相関図表示**: 関係値の可視化システム
- **優先度**: 低（システム完成後の品質向上要素）

## 🛠️ 実装指針

### コード構成原則

#### Domain層（最重要）
- **戦闘ロジック**: ダメージ計算、技発動条件、勝敗判定
- **関係値モデル**: 関係値変動ロジック、レベル判定
- **イベント条件判定**: 分岐条件の評価ロジック
- **依存関係**: 他レイヤーに一切依存しない純粋なビジネスロジック

#### Application層（制御）
- **バトル進行制御**: 戦闘フロー管理、ターン制御
- **イベント制御**: イベント進行、選択肢処理
- **ユースケース実装**: 具体的な機能実行手順
- **依存関係**: Domainに依存、InfrastructureとUIには依存しない

#### Infrastructure層（データ）
- **データロード**: JSON/CSVからのゲームデータ読み込み
- **セーブ管理**: 進行状況・関係値の永続化
- **外部連携**: ファイルシステム、Unity固有機能への接続
- **依存関係**: Domainのインターフェースを実装

#### UI層（表示）
- **Scene・Prefab**: Unity標準の表示システム活用
- **入力処理**: プレイヤー操作の受付と変換
- **表示制御**: ゲーム状態の視覚化
- **依存関係**: ApplicationとPresentationに依存

### データ形式・管理

#### 外部データ管理
- **イベントデータ**: JSON形式での外部管理
- **キャラクターデータ**: ScriptableObjectとJSON併用
- **スキルデータ**: 技の効果・発動条件の外部化
- **利点**: データ変更でのコンパイル不要、拡張性確保

#### セーブデータ仕様  
- **関係値状態**: 全キャラクター間の関係値マトリックス
- **進行状況**: イベント進行フラグ、解放コンテンツ
- **形式**: JSON形式での可読性とデバッグ性確保

### テスト戦略

#### 重点テスト対象
- **Domain層の単体テスト**: NUnit使用での徹底的テスト
- **関係値計算ロジック**: 境界値テスト、異常値テスト
- **戦闘システム**: 各種条件での動作確認
- **イベント分岐**: 条件組み合わせでの動作検証

#### テスト自動化
- **Unity Test Framework**: Edit Mode/Play Mode併用
- **継続的インテグレーション**: 品質維持のための自動実行
- **カバレッジ目標**: Domain層90%以上、Application層80%以上

## 🚀 開発ロードマップ

### Phase 1: 基盤アーキテクチャ構築（TDD）
- [ ] テスト環境のセットアップ（Unity Test Framework）
- [ ] ドメインモデルの設計と実装（関係値システム）
- [ ] クリーンアーキテクチャの基盤実装
- [ ] プラットフォーム抽象化レイヤーの構築
- [ ] DIコンテナの導入と設定

### Phase 2: コアシステム実装（DDD）
- [ ] 関係値ドメインの完全実装（TDD）
- [ ] キャラクター集約の実装
- [ ] ダンジョン探索ドメインの設計
- [ ] 戦闘システムドメインの構築
- [ ] イベントソーシングの実装

### Phase 3: アプリケーション層構築
- [ ] ユースケースの実装（TDD）
- [ ] リポジトリパターンの実装
- [ ] セーブ/ロードシステム（クロスプラット対応）
- [ ] Unity統合レイヤーの実装
- [ ] パフォーマンス監視とテスト

### Phase 4: プレゼンテーション層とリリース
- [ ] MVP/MVVMパターンでのUI実装
- [ ] Windows向け最適化とテスト
- [ ] Mac対応の実装と検証
- [ ] E2Eテストとパフォーマンス調整
- [ ] リリース用ビルドパイプライン構築

## 🔧 技術仕様

### 開発環境要件
- **Unity**: 6000.1.13f1以上（Unity 6）
- **Visual Studio**: 2022以上 (Windows)
- **Visual Studio Code**: Unity拡張機能
- **.NET**: Standard 2.1
- **Git**: バージョン管理
- **NUnit**: Unity Test Framework（TDD対応）

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