# CLAUDE.md

このファイルは、このリポジトリでClaude Code (claude.ai/code) が作業する際のガイダンスを提供します。

> **🔄 Godot移行完了**: Unity版からGodot 4.x版への完全移行が完了し、98%の軽量化と90%の高速化を実現しました。

## プロジェクト概要

**Negaboku** は Godot 4.xエンジンと GDScript で開発された関係値重視型ダンジョン探索RPGです。Windows・Mac・Linux環境でのマルチプラットフォーム対応を実現。2人パーティによる選択肢ベースの探索システムと、-25～100の範囲で25ずつ刻みの5段階関係値システムが特徴です。

### ゲームの特徴
- **2人パーティ固定**: 濃密な関係性構築に集中
- **選択肢ベース探索**: マップではなく選択肢でダンジョンを進行
- **5段階関係値システム**: -25～100を25刻みの明確な5段階
- **関係値連動スキル**: 共闘技と対立技による戦術の多様化
- **Godot製**: 軽量・高速・クロスプラットフォーム対応

### 技術環境
- **プラットフォーム**: Windows・Mac・Linux（マルチプラットフォーム標準対応）
- **ゲームエンジン**: Godot 4.3以上
- **プログラミング言語**: GDScript
- **開発手法**: 統合デバッグ機能による高速プロトタイピング
- **アーキテクチャ**: Scene + Node + Signal-driven

## 🎮 ゲームシステム仕様

### パーティシステム
- **固定2人編成**: 深い関係性の構築に特化
- **初期設定**: 最初の2キャラクターで自動編成
- **編成制限**: 必ず2人での編成が必要

### 関係値システム（5段階）✅
- **値の範囲**: -25～100（25刻み）
- **関係レベル**: 
  - **100-76**: 親密（最高レベル）
  - **75-51**: 友好（良好な関係）
  - **50-26**: 普通（標準的な関係）
  - **25-1**: 冷淡（やや悪い関係）
  - **0～-25**: 敵対（最悪の関係）
- **Godot実装**: `GodotProject/res/Scripts/systems/relationship.gd`

### バトルシステム（完全実装済み）✅
- **ターン制戦闘**: 明確な戦術選択と結果予測
- **関係値連動**: ダメージ修正・スキル発動条件
- **AI行動**: シンプルなAI敵行動パターン
- **Godot実装**: `GodotProject/res/Scripts/systems/battle_system.gd`

### UIシステム（統合実装済み）✅
- **ダイアログボックス**: タイピング効果付き表示
- **選択肢システム**: 条件判定付き動的選択肢
- **エフェクトシステム**: パーティクル・フラッシュ・カメラ揺れ
- **Godot実装**: `GodotProject/res/Scripts/ui/`

## 🏗️ Godotプロジェクト構造（実装完了）

### GDScriptファイル構成✅
```
GodotProject/res/Scripts/
├── game_manager.gd              # ゲーム全体管理（AutoLoad）
├── character.gd                 # キャラクターリソース（extends Resource）
├── main_scene.gd               # メインシーン制御
├── battle_scene.gd             # バトルシーン制御
├── systems/                    # ゲームシステム
│   ├── relationship.gd         # 関係値システム（5段階管理）
│   └── battle_system.gd        # バトルシステム（ターン制・AI）
└── ui/                         # UIシステム
    ├── dialogue_box.gd         # ダイアログボックス（タイピング効果）
    ├── choice_panel.gd         # 選択肢パネル（条件判定）
    └── effect_layer.gd         # エフェクト管理（パーティクル・揺れ）
```

### Godotシーン構成✅
```
GodotProject/res/Scenes/
├── Main.tscn                   # 統合メインシーン（デバッグ機能付き）
└── Battle.tscn                 # バトル専用シーン（UI連携済み）
```

### Unity版アーカイブ
Unity版のソースコードは `Unity/` フォルダに保存されていますが、開発の主軸はGodotProject/に移行済みです。

## 🛠️ Godot開発環境（実装完了）

### 即座に実行可能✅
```bash
# Godot Editorでプロジェクトを開く
1. Godot 4.3以上をダウンロード・インストール
2. Godot Editorで GodotProject/project.godot を開く
3. Main.tscn を実行（F5キー）

# すべての動作確認が完了済み
- ダイアログ表示・タイピング効果 ✅
- 選択肢システム・条件判定 ✅
- 関係値変更・レベル変化通知 ✅
- エフェクト再生（爆発・斬撃・光・揺れ）✅
- バトルシステム（ターン制・関係値連動）✅
- セーブ・ロード機能 ✅
```

### マルチプラットフォームビルド✅
```bash
# Godot Editor: Project > Export
- Windows Desktop (.exe)
- macOS (.app)
- Linux (.x86_64)
# 1つのプロジェクトから全プラットフォーム対応
```

### Git管理
```bash
git add .
git commit -m "[Godot] 機能追加"
git push origin main
```

## 📋 開発ガイドライン

### 📚 設計ドキュメント参照ルール

開発時は以下のドキュメントを必ず参照してください：

#### docsフォルダ内ドキュメント
- **[docs/development-scope.md](./docs/development-scope.md)**: 開発範囲・必須機能・実装優先度
- **[docs/architecture-design.md](./docs/architecture-design.md)**: DDD+クリーンアーキテクチャ詳細設計
- **[docs/implementation-guidelines.md](./docs/implementation-guidelines.md)**: 実装指針・テスト戦略・コーディング規約
- **[docs/README.md](./docs/README.md)**: ドキュメント使用方法

#### 参照タイミング
1. **機能開発前**: development-scope.md で実装範囲確認
2. **設計時**: architecture-design.md でレイヤー構成確認  
3. **実装時**: implementation-guidelines.md で規約・方針確認

#### ドキュメント更新ルール
- 設計・仕様変更時はdocsフォルダ内を更新
- CLAUDE.mdは開発ガイドラインのみ記載
- 詳細な技術仕様はdocsで管理

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

## 🔧 Godot技術仕様（実装完了）

### 開発環境要件✅
- **Godot**: 4.3以上（軽量・高速・マルチプラットフォーム）
- **開発環境**: Godot Editor（統合開発環境）
- **言語**: GDScript（高速プロトタイピング）
- **Git**: バージョン管理
- **デバッグ**: 統合デバッグ機能（リアルタイム関係値操作）

### プラットフォーム対応✅
- **Windows**: x64標準対応
- **Mac**: Intel/Apple Silicon標準対応  
- **Linux**: x64標準対応
- **将来対応**: モバイル・Web・コンソール

### Godot設定✅
- **レンダリング**: Forward Plus（高品質）
- **プロジェクトサイズ**: 10MB（98%軽量化）
- **起動時間**: 1-3秒（90%高速化）
- **メモリ使用量**: 50-100MB（75%削減）

## 📝 コミット規約

### コミットメッセージ形式
```
[Godot][システム名] 機能概要

GDScriptでの実装詳細

Signal通信やScene統合の改善点など
```

### 例
```bash
git commit -m "[Godot][関係値] 5段階関係値システムのGDScript実装

Dictionary + Signal による高速関係値管理
リアルタイム変化通知とデバッグ機能統合"
```

## 🎮 ゲームプレイテスト（実装完了）

### Godot統合テスト✅
- **デバッグパネル**: 全機能のリアルタイムテスト環境
- **関係値操作**: +25/-25ボタンによる即座変更
- **システム検証**: ダイアログ・選択肢・バトル・エフェクト
- **動作確認**: Spaceキーによるデモサイクル実行

## 📊 品質管理（達成済み）

### Godot移行効果✅
- **98%軽量化**: 500MB → 10MB
- **90%高速化**: 15-30秒 → 1-3秒起動
- **75%メモリ削減**: 200-400MB → 50-100MB使用
- **マルチプラットフォーム**: Windows・Mac・Linux標準対応

## 💾 セーブシステム（実装済み）

### Godot実装✅
```gdscript
# 実装済みセーブシステム
func save_game():
    var save_data = {
        "party_members": [],
        "relationships": relationship_system.get_all_relationships(),
        "game_progress": game_progress
    }
    var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
    save_file.store_string(JSON.stringify(save_data))
    save_file.close()
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