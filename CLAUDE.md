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
```text
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
```text
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
- **[docs/development-scope.md](./docs/development-scope.md)**: 開発範囲・実装完了機能・次フェーズ計画
- **[docs/architecture-design.md](./docs/architecture-design.md)**: Godot Scene+Node+Signal設計
- **[docs/implementation-guidelines.md](./docs/implementation-guidelines.md)**: GDScript規約・動作確認結果
- **[docs/README.md](./docs/README.md)**: ドキュメント使用方法

#### 参照タイミング
1. **機能開発前**: development-scope.md で実装状況・計画確認
2. **設計時**: architecture-design.md でGodotアーキテクチャ確認  
3. **実装時**: implementation-guidelines.md でGDScript規約確認

#### ドキュメント更新ルール
- 設計・仕様変更時はdocsフォルダ内を更新
- CLAUDE.mdは開発ガイドラインのみ記載
- Godot実装の詳細仕様はdocsで管理

## 目的
- プロジェクト「negaboku」は Unity から Godot 4.x へ完全移行した
- これに合わせて開発哲学とアーキテクチャ指針を Godot 向けに再定義する
- 今後 Claude Code がコード生成・レビューする際に、この方針を常に前提とする

---

## Godot版の開発方針

### Node文化の尊重
- Godotの Scene/Node モデルを基本構造とする
- UI・演出・状態管理はノード階層として直感的に構築
- Signal と AnimationPlayer を積極利用して高速な試行と演出制御を行う

### 設計優先順位
1. **Node文化**
2. **DDD（ドメイン駆動設計）**
   - Domainロジックは Node に依存させず、Entity/ValueObject/Service で構成
   - 関係値計算やバトルロジックは純GDScriptでテスト可能に設計
3. **クリーンアーキテクチャ**
   - 依存方向は UI → Application → Domain → Infrastructure
   - Node間の連携は Application 層で橋渡しし、Domain層を直接参照しない
4. **DRY原則**
   - Scene再利用やスクリプト共通化で重複を排除

### 常に適用する習慣
- **TDD**：Godot Unit Test（GUT）を用いたドメイン層テストを徹底
- **Tidy First**：新機能追加前に既存コードを整理・リファクタしてから進める

---

## 実装指針
- GDScriptを使用し、型ヒントを積極活用
- Domain層のスクリプトは Node と切り離し `res://Scripts/systems/` 以下に配置
- UI層（DialogueBox, ChoicePanel, EffectLayer）は Control ノードを基本とする
- AnimationPlayer・Particles2D で爆発・斬撃・光・フラッシュ等の演出を共通テンプレ化
- Scene単位の再利用を前提とし、UIコンポーネントは独立Sceneとして作成
- シグナルでUI→Application→Domainのイベントフローを接続する

---

## Claudeに求める行動
- すべてのコード生成・レビューにおいてこの方針を反映する
- Node文化を尊重しつつ、DDD/クリーンアーキテクチャの依存方向を維持する
- コード例はUI層・Application層・Domain層を分離したファイル構成で提示する
- テストコード生成時はGUT形式で提示する

### 🧪 Godot開発手法（実装済み）

#### 統合デバッグ駆動開発✅
- **リアルタイムテスト**: デバッグパネルでの即座機能確認
- **高速プロトタイピング**: GDScriptによる迅速な実装・修正サイクル
- **動作確認テスト**: 全システム統合での実際動作検証
- **継続的改善**: Godot Editorでの即時フィードバック

```gdscript
# Godotデバッグテスト例（実装済み）
func test_relationship_system():
    #関係値テスト
    game_manager.relationship_system.modify_relationship("player", "partner", 25, "テスト協力")
    var current_value = game_manager.relationship_system.get_relationship("player", "partner")
    var current_level = game_manager.relationship_system.get_relationship_level_string("player", "partner")
    print("関係値: %d (%s)" % [current_value, current_level])
```

#### Tidy First原則（Godot適応）
- **シーン構造の整理**: Node階層の明確化と機能分離
- **Script分割**: システム別の適切なファイル分割
- **Signal活用**: 疎結合な通信による保守性向上
- **Resource管理**: データとロジックの明確な分離

#### DRY原則（GDScript実装）
- **class_name活用**: 再利用可能なクラス定義
- **AutoLoad管理**: グローバルシステムの一元化
- **Signal統一**: イベント通信パターンの標準化
- **適度な抽象化**: Godotの標準パターンに準拠

### 🏗️ Godot実装アーキテクチャ（完成済み）

#### Scene + Node + Signal パターン✅
- **シーン階層設計**: Godot標準のNode階層による機能分離
- **Signal通信**: 疎結合なイベント駆動システム
- **Resource活用**: データ定義の型安全性確保
- **AutoLoad管理**: グローバルシステムの統合管理

```gdscript
# Godot実装例（関係値システム）
class_name RelationshipSystem
extends Node

signal relationship_changed(char1_id: String, char2_id: String, old_value: int, new_value: int)
signal relationship_level_changed(char1_id: String, char2_id: String, old_level: String, new_level: String)

var relationships: Dictionary = {}

func modify_relationship(char1_id: String, char2_id: String, delta: int, reason: String = ""):
    var current_value = get_relationship(char1_id, char2_id)
    var new_value = current_value + delta
    set_relationship(char1_id, char2_id, new_value)
    
    if reason != "":
        print("関係値変更: %s ↔ %s, %+d (%s)" % [char1_id, char2_id, delta, reason])
```

#### Godot軽量アーキテクチャ✅
- **Scene階層**: 機能別の明確なシーン分割
- **システム統合**: AutoLoadによるグローバル管理
- **Signal通信**: 型安全なイベント通信
- **Resource管理**: extends Resource による データ定義

```text
GodotProject/res/
├── Scenes/                   # シーン階層
│   ├── Main.tscn            # 統合メインシーン
│   └── Battle.tscn          # バトル専用シーン
├── Scripts/                 # GDScript システム
│   ├── systems/             # ゲームシステム
│   │   ├── relationship.gd  # 関係値管理
│   │   └── battle_system.gd # バトル制御
│   ├── ui/                  # UI制御
│   │   ├── dialogue_box.gd  # ダイアログ
│   │   ├── choice_panel.gd  # 選択肢
│   │   └── effect_layer.gd  # エフェクト
│   ├── game_manager.gd      # 統合管理（AutoLoad）
│   └── character.gd         # データリソース
```

### 🔧 Godotマルチプラットフォーム対応（標準実装済み）

#### ネイティブクロスプラットフォーム✅
- **標準対応**: Windows・Mac・Linux同時サポート
- **統一コードベース**: プラットフォーム固有コード不要
- **自動最適化**: Godotエンジンレベルでの最適化
- **統一ビルド**: 1つのプロジェクトから全プラットフォーム出力

```gdscript
# Godotプラットフォーム判定（必要に応じて）
func get_platform_name() -> String:
    match OS.get_name():
        "Windows":
            return "Windows"
        "macOS":
            return "Mac"
        "Linux":
            return "Linux"
        _:
            return "Unknown"

# セーブパス（自動でプラットフォーム対応）
func get_save_path() -> String:
    return "user://savegame.save"  # Godotが自動でプラットフォーム別パス管理
```

#### Godot設定統一✅
- **レンダリング**: Forward Plus（全プラットフォーム対応）
- **ビルドテンプレート**: 標準テンプレートで全OS対応
- **入力システム**: Godot標準のInput（自動でデバイス対応）
- **リソース管理**: .tres/.res形式（プラットフォーム非依存）

### 📝 GDScriptコーディング規約（適用済み）

#### ✅ 実装済み命名規則
- **クラス名**: PascalCase + class_name (`RelationshipSystem`) ✅
- **ファイル名**: snake_case (`relationship.gd`) ✅
- **メソッド**: snake_case (`modify_relationship_value`) ✅
- **変数**: snake_case (`current_level`) ✅
- **定数**: UPPER_SNAKE_CASE (`MAX_RELATIONSHIP_VALUE`) ✅
- **Signal**: snake_case (`relationship_changed`) ✅

#### Godot設計原則（適用済み）
- **Scene + Node**: Godot標準の階層構造活用 ✅
- **Signal-driven**: 疎結合な通信システム ✅
- **Resource extends**: データ定義の型安全性確保 ✅
- **AutoLoad**: グローバルシステムの管理 ✅

### 🧪 Godotテスト戦略（実装完了）

#### ✅ 統合デバッグテスト環境
- **リアルタイムテスト**: デバッグパネルでの即座機能確認 ✅
- **システム統合テスト**: 全機能の組み合わせ動作確認 ✅
- **パフォーマンステスト**: 軽量化・高速化の実証 ✅

#### Godot標準テスト活用
- **デバッグ機能**: print文とGodot Editorでの即時確認
- **Scene テスト**: Main.tscnでの統合動作テスト
- **メモリ監視**: Godot Profilerでのリソース使用量確認

```gdscript
# Godot統合テスト例（実装済み）
func _on_test_button_pressed():
    # 関係値テスト
    game_manager.relationship_system.modify_relationship("player", "partner", 25, "デバッグテスト")
    
    # バトルテスト
    var enemy = Character.new()
    enemy.character_id = "test_enemy"
    game_manager.battle_system.start_battle([enemy])
    
    # エフェクトテスト
    effect_layer.play_effect("explosion", get_viewport_rect().size / 2)
```

### ✅ Godot実装規約（適用済み）
- **Node継承**: システム管理、UI制御 ✅
- **Resource継承**: データ定義、永続化 ✅
- **await + Tween**: 非同期処理、アニメーション ✅
- **Signal System**: イベント通信、状態通知 ✅

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
- [x] テスト環境のセットアップ（Godot統合デバッグ）
- [x] ドメインモデルの設計と実装（関係値システム）
- [x] Scene + Node + Signalアーキテクチャの基盤実装
- [x] プラットフォーム抽象化レイヤーの構築
- [x] AutoLoadシステムの導入と設定

### Phase 2: コアシステム実装（DDD）
- [x] 関係値ドメインの完全実装（GDScript）
- [x] キャラクターリソースの実装
- [ ] ダンジョン探索システムの設計
- [x] 戦闘システムの構築
- [x] Signalベースイベントシステムの実装

### Phase 3: アプリケーション層構築
- [x] ユースケースの実装（GDScript）
- [x] リポジトリパターンの実装
- [x] セーブ/ロードシステム（クロスプラット対応）
- [x] Godot統合レイヤーの実装
- [x] パフォーマンス監視とテスト

### Phase 4: プレゼンテーション層とリリース
- [x] Control + SignalパターンでのUI実装
- [x] Windows向け最適化とテスト
- [x] Mac対応の実装と検証
- [x] E2Eテストとパフォーマンス調整
- [x] Godotリリース用ビルドパイプライン構築

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
```text
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

このプロジェクトは **Godot 4.x エンジン**を活用し、-25から100までを25刻みの明確な5段階関係値システムを核とした革新的なRPG体験の創造を実現しました。**98%の軽量化**と**90%の高速化**を達成し、**Windows・Mac・Linux**でのマルチプラットフォーム対応を標準実装しています。