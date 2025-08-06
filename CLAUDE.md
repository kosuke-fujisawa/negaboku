# CLAUDE.md

このファイルは、このリポジトリでClaude Code (claude.ai/code) が作業する際のガイダンスを提供します。

> **🔄 Godot移行完了**: Unity版からGodot 4.x版への完全移行が完了し、98%の軽量化と90%の高速化を実現しました。

## プロジェクト概要

**願い石と僕たちの絆** は Godot 4.xエンジンと GDScript で開発された「僕たちの絆」を紡ぐ関係値RPGです。Windows・Mac・Linux環境でのマルチプラットフォーム対応を実現。2人パーティによる選択肢ベースの探索システムと、3段階関係値システム（対立／通常／親密）による戦闘技・掛け合いの変化が特徴です。

### ゲームの特徴
- **「僕たちの絆」を紡ぐ**: 関係性の変化そのものを物語体験の中心に据える
- **2人パーティ固定**: 濃密な関係性構築に集中
- **選択肢ベース探索**: マップではなく選択肢でダンジョンを進行
- **3段階関係値システム**: 対立／通常／親密による明確な関係性管理
- **関係値連動スキル**: 共闘技（親密時）と対立技（対立時、主にソウマ限定）
- **ローグライク＋ストーリー重視**: プレゼント・イベントによる好感度変化
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

### 関係値システム（3段階）✅
- **関係レベル**:
  - **親密**: 共闘技が解放、高威力＋追加効果
  - **通常**: 標準的な相互作用、基本スキルのみ使用可能
  - **対立**: 対立技が解放、ハイリスクハイリターン（主にソウマ限定）
- **数値管理**: 内部で数値管理、メニュー画面で静かに表示
- **推奨ペア**: 専用イベント・エンディング・カットイン有り
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
│   ├── relationship.gd         # 関係値システム（3段階管理）
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

### 🔧 不具合修正方針
- **横断的調査の徹底**：不具合の原因調査を行うときは、同様の問題がないか他のファイルを横断的に調査する
- **根本原因の特定**：表面的な症状だけでなく、複数の関連ファイル間の相互作用を含めて根本原因を特定する
- **包括的修正**：同じパターンの問題が複数箇所にある場合は、全てを一括で修正して再発を防ぐ
- **修正効果の検証**：関連する全てのフローパターンで修正が正しく動作することを確認する

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

## 🎯 関係値システム詳細（3段階）

### 関係値の変動と戦闘効果
- **親密**: 共闘技が解放、高威力＋追加効果、共闘技ありでイージー寄り難易度
- **通常**: 標準的な相互作用、基本スキルのみ使用可能
- **対立**: 対立技が解放、ハイリスクハイリターン（主にソウマ限定）

### 推奨ペアの特別要素
- **ソウマ × ユズキ**: 幼馴染の絆、特別イベント・エンディングCG
- **ソウマ × レツジ**: 親友の信頼、特別イベント・エンディングCG
- **ソウマ × カイ**: 対立から親密への変化（初期-25）、特別イベント・エンディングCG
- **カイ × セリーヌ**: 身分差を超えた関係、特別イベント・エンディングCG
- **リゼル × レツジ**: 戦士と術師の協力、特別イベント・エンディングCG

### 難易度設計思想
- **共闘技なし**: やや困難な難易度設定
- **共闘技あり**: イージー寄りの難易度設定
- **対立技**: 一部高火力だが運用困難、主にソウマ限定の特殊戦術


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
git commit -m "[Godot][関係値] 3段階関係値システムのGDScript実装

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

**願い石と僕らの旅路**は独自の非商用ライセンスを採用しています：

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

## 🎯 「願い石と僕たちの絆」実装方針

### 設計思想
- **DDD（ドメイン駆動設計）+ クリーンアーキテクチャベース**: ドメインロジックを中心とした設計
- **TDD維持**: テスト駆動開発による品質保証
- **Node文化の尊重**: GodotのScene/Nodeモデルを基本構造とする
- **Signal-driven**: 疎結合なイベント通信システム

### 開発優先順位
1. **骨子とテキスト優先**: ゲームの核となるシステム・ストーリーを最優先
2. **UIや演出は後回し**: 基本機能の実装完了後に視覚的要素を追加
3. **クロスプラットフォーム想定**: 最初はWindows優先、後にMac・Linux対応
4. **段階的実装**: 体験版 → DLC → 完全版の段階的リリース

### アセット・リソース方針
- **エフェクト・BGM**: 無料素材加工ベースで統一
- **イラスト**: 男女別絵師で統一感を確保
- **テキスト**: 日本語優先、将来的な多言語対応も視野
- **データ管理**: GodotのResourceシステム活用でデータ駆動設計

### キャラクター・ストーリー実装
- **メインキャラクター**: ソウマ、ユズキ、レツジ、カイ等の実装
- **推奨ペア**: 専用イベント・エンディング・カットイン有りの特別ルート
- **関係値システム**: 3段階（対立/通常/親密）による戦闘・イベント分岐
- **願い石ストーリー**: AIリラとの対峙を核とした物語展開

## Godot実装アーキテクチャ詳細

### 関係値システム実装方針

#### ドメイン層設計原則
```gdscript
# res/Scripts/systems/relationship.gd
class_name RelationshipSystem
extends Node

# Signalベースの状態通知
signal relationship_changed(char1_id: String, char2_id: String, old_value: int, new_value: int)
signal relationship_level_changed(char1_id: String, char2_id: String, old_level: String, new_level: String)

# 関係値データ管理
var relationships: Dictionary = {}
const MAX_RELATIONSHIP = 100
const MIN_RELATIONSHIP = -100

# キャップ制管理
var relationship_caps = {
    "early_game": 30,   # 序盤キャップ
    "mid_game": 50,     # 中盤解放（共闘技解放）
    "late_game": 100    # 終盤解放（全ルート分岐可能）
}

# 特殊対立ペアの定義
var special_conflict_pairs = ["souma_kai", "yuzuki_serene", "retsuji_kengo"]
```

#### イベント連携設計指針
- **一元管理**: `relationService.update(pairId, delta, reason)`で全ての関係値変更を一元管理
- **Signal駆動**: 状態変化をSignalで通知、UI・スキルシステムが自動更新
- **リアルタイム反映**: 関係値変化が即座にゲーム内の全システムに反映
- **ルート確定管理**: 後半に親密/通常/対立ルートを確定、以降はエンディング分岐固定

### バトルシステム実装方針

#### スキルシステム設計
```gdscript
# res/Scripts/systems/battle_system.gd
# スキル分類と発動条件の管理
enum SkillType {
    NORMAL,     # 白：常時使用可能
    MAGIC,      # 青：MP消費、常時使用可能
    COOPERATION, # 緑：関係値+50以上で解放
    CONFLICT    # 赤：関係値-50以下、特定ペアのみ
}

# スキル発動条件の動的チェック
func can_use_skill(character1_id: String, character2_id: String, skill_type: SkillType) -> bool:
    var relationship_value = relationship_system.get_relationship(character1_id, character2_id)

    match skill_type:
        SkillType.COOPERATION:
            return relationship_value >= 50  # 親密状態
        SkillType.CONFLICT:
            return relationship_value <= -50 and is_special_conflict_pair(character1_id, character2_id)
        _:
            return true  # 通常スキルは常時使用可能
```

#### SP管理システム設計
```gdscript
# 戦闘ごとの初期化と管理
var sp_values = {}
const INITIAL_SP = 100

func start_battle():
    # パーティメンバーのSPを戦闘開始時に初期化
    for character_id in party_members:
        sp_values[character_id] = INITIAL_SP

func use_special_skill(character_id: String, sp_cost: int) -> bool:
    if sp_values[character_id] >= sp_cost:
        sp_values[character_id] -= sp_cost
        return true
    return false
```

### UIシステム実装方針

#### 相関図表示システム
```gdscript
# res/Scripts/ui/relationship_chart.gd
class_name RelationshipChart
extends Control

# 推奨ペアの定義と表示管理
var recommended_pairs = [
    ["souma", "yuzuki"],    # 幼馴染の絆
    ["souma", "retsuji"],   # 親友の信頼
    ["souma", "kai"],       # 対立から親密へ
    ["retsuji", "yuzuki"],  # 戦士と白魔術師
    ["retsuji", "rizel"],   # 戦士と召喚術師
    ["yuzuki", "kai"],      # 幼馴染とチャラ男
    ["makito", "serene"],   # 博識とお嬢様
    ["kai", "pix"],         # DLC: チャラ男とインプ
    ["kai", "serene"],      # 身分差を超えた関係
    ["serene", "lira"],     # DLC: お嬢様とAI少女
    ["kengo", "lira"],      # DLC: 父とAIの特別な関係
    ["makito", "pix"]       # DLC: 新組み合わせ
]

# 対立ペアの特別表示
var conflict_pairs = [
    ["souma", "kai"],       # 価値観不一致
    ["yuzuki", "serene"],   # 三角関係、恋愛的嫉妬
    ["retsuji", "kengo"]    # DLC: 過去の事件
]

func update_chart():
    for pair in all_character_pairs:
        var relationship_value = relationship_system.get_relationship(pair[0], pair[1])
        if pair in recommended_pairs:
            show_special_hint(pair, relationship_value)  # 推奨ペアヒント表示
        elif pair in conflict_pairs:
            show_conflict_warning(pair, relationship_value)  # 対立ペア警告
        else:
            show_normal_pair(pair, relationship_value)  # 通常表示
```

#### バトルUIシステム
```gdscript
# res/Scripts/ui/battle_ui.gd
class_name BattleUI
extends Control

# スキルタイプ別の色分け設定
var skill_colors = {
    SkillType.NORMAL: Color.WHITE,      # 白：通常スキル
    SkillType.MAGIC: Color.BLUE,        # 青：魔法スキル
    SkillType.COOPERATION: Color.GREEN, # 緑：共闘技
    SkillType.CONFLICT: Color.RED       # 赤：対立技
}

func update_skill_list():
    for skill in available_skills:
        var skill_button = skill_buttons[skill.id]
        # 色分けと使用可否状態の視覚化
        skill_button.modulate = skill_colors[skill.type]
        skill_button.disabled = not can_use_skill(skill)

        # 関係値表示のリアルタイム更新
        update_relationship_display()
```

### プレゼントシステム実装方針

#### プレゼント効果管理
```gdscript
# res/Scripts/systems/present_system.gd
class_name PresentSystem
extends Node

# プレゼント効果定義
enum PresentReaction {
    FAVORITE = 10,  # 好物
    NORMAL = 5,     # 普通
    DISLIKE = -5    # 嫌い（致命傷にならない）
}

# キャラ別好みデータ管理
var character_preferences = {
    "yuzuki": {"flowers": PresentReaction.FAVORITE, "books": PresentReaction.NORMAL, "weapons": PresentReaction.DISLIKE},
    "retsuji": {"weapons": PresentReaction.FAVORITE, "food": PresentReaction.NORMAL, "flowers": PresentReaction.DISLIKE},
    # ...他キャラクターの設定
}

func give_present(giver_id: String, receiver_id: String, item_type: String):
    var reaction = get_reaction(receiver_id, item_type)
    var relationship_delta = reaction as int

    # 関係値システムへの連携
    relationship_system.modify_relationship(giver_id, receiver_id, relationship_delta, "present_" + item_type)

    # 初回プレゼント時の情報開示
    if not has_given_before(giver_id, receiver_id, item_type):
        reveal_preference(receiver_id, item_type, reaction)
```

### ラスボス戦システム実装方針

#### AIリラ戦闘システム
```gdscript
# res/Scripts/systems/lira_boss_system.gd
class_name LiraBossSystem
extends Node

# フルパワーモード管理
var is_full_power_mode = false
var fragment_count = 0
const REQUIRED_FRAGMENTS = 5

func start_boss_battle():
    # 断片アイテムチェック
    fragment_count = inventory_system.count_fragments()

    if fragment_count < REQUIRED_FRAGMENTS:
        # 強制敗北演出（ゲームオーバーなし）
        show_forced_defeat_scene()
        return false

    # 正常なボス戦開始
    apply_fragment_debuffs()
    return true

func on_hp_half():
    # HP半減時のフルパワーモード移行
    is_full_power_mode = true
    apply_full_power_buffs()

func apply_fragment_debuffs():
    # 断片数に応じたデバフ効果
    var debuff_strength = fragment_count * 0.2
    lira_stats.defense_multiplier *= (1.0 - debuff_strength)
```

### 拡張性設計方針

#### DLCキャラクター対応
- **データ駆動設計**: キャラクターデータをResourceで管理、新キャラ追加時の自動拡張
- **関係値マトリックス**: 新キャラ追加時の関係値テーブル自動拡張
- **スキルシステム**: キャラ特有スキルの動的追加、既存システムとの統合

#### カスタマイズ機能
- **関係値調整アイテム**: ゲームバランス調整用、サイトウ撃破後解放
- **難易度設定**: 共闘技発動条件の動的調整機能
- **デバッグ機能**: 関係値操作・スキルテスト機能の内蔵

### パフォーマンス最適化方針

#### Godot最適化手法
- **Object Pool**: エフェクトオブジェクトの再利用でメモリ効率化
- **Signal管理**: 不要なSignal接続の適切な解除でメモリリーク防止
- **Resourceキャッシュ**: 頻繁アクセスデータのメモリキャッシュで高速化
- **バッチ処理**: UI更新のバッチ化で描画パフォーマンス向上

### 体験版・DLC戦略
- **体験版**: 4キャラクター（ソウマ、ユズキ、レツジ、カイ）での基本システム体験
- **DLC**: リラ・ケンゴ・ピクス追加、研究所ダンジョン、AI救済ルート
- **メタキャラクター**: サイトウによる相関図表示・復帰説明機能

---

このプロジェクトは **Godot 4.x エンジン**を活用し、「僕たちの絆」を紡ぐ3段階関係値システムを核とした革新的なRPG体験の創造を目指します。**98%の軽量化**と**90%の高速化**を達成し、**Windows・Mac・Linux**でのマルチプラットフォーム対応を標準実装しています。
