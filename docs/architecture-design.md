# アーキテクチャ設計書

> **🔄 Godot移行完了**: Unity版のクリーンアーキテクチャをGodot 4.xのScene + Nodeシステムに適応し、より軽量で効率的な設計に進化しました。

## Godot実装での設計思想

### Godot適応アーキテクチャ
- **Scene + Node パターン**: Godot の標準設計に合わせた階層構造
- **Signal-driven**: イベント通信を Godot の Signal システムで実装
- **Resource システム**: データ駆動設計を Godot の Resource で実現
- **軽量性重視**: エンジンオーバーヘッドを最小化した効率的設計

### Unity移行による改善
- **98%軽量化**: プロジェクトサイズ 500MB → 10MB
- **90%高速化**: 起動時間 15-30 秒 → 1-3 秒
- **75%メモリ削減**: 使用量 200-400MB → 50-100MB
- **クロスプラットフォーム**: Windows・Mac・Linux 標準対応

## Godot実装構成

### システム層（`res/Scripts/systems/`）
- **責任**: ゲームロジック、関係値・バトル管理 ✅
- **Godot実装**: class_name + Signal 通信
- **実装済み**:
  - `relationship.gd`: 関係値システム（3 段階管理：対立/通常/親密）
  - `battle_system.gd`: ターン制バトル、AI 行動、スキル発動

### シーン管理層（`res/Scenes/`）
- **責任**: ゲーム進行制御、UI 統合 ✅
- **Godot実装**: Scene + Node 階層設計
- **実装済み**:
  - `Main.tscn`: 統合メインシーン、デバッグ機能
  - `Battle.tscn`: バトル専用シーン、UI 連携

### UI層（`res/Scripts/ui/`）
- **責任**: 表示制御、プレイヤー入力処理 ✅
- **Godot実装**: Control + Signal イベント
- **実装済み**:
  - `dialogue_box.gd`: タイピング効果付きダイアログ
  - `choice_panel.gd`: 条件判定付き選択肢システム
  - `effect_layer.gd`: パーティクル・フラッシュ・カメラ揺れ

### リソース管理層（`res/Scripts/`）
- **責任**: データ管理、永続化 ✅
- **Godot実装**: Resource + JSON セーブシステム
- **実装済み**:
  - `character.gd`: キャラクターリソース（extends Resource）
  - `game_manager.gd`: 全体統括、セーブ・ロード機能

## プラットフォーム抽象化

### 条件付きコンパイル
- `#if UNITY_STANDALONE_WIN` の適切な使用
- プラットフォーム固有処理の分離

### インターフェース設計
```csharp
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

### Godot設定統一
- **レンダリング**: Forward Plus（全プラットフォーム対応）
- **ビルドテンプレート**: 標準テンプレートで全 OS 対応
- **入力システム**: Godot 標準の Input（自動でデバイス対応）
- **リソース管理**: .tres/.res 形式（プラットフォーム非依存）

## 新系統詳細仕様

### プレゼントシステム詳細

#### プレゼント効果データ
```gdscript
# res/Scripts/systems/present_system.gd
class_name PresentSystem
extends Node

enum PresentReaction {
    FAVORITE = 10,  # 好物：相手の好みにピッタリ適合
    NORMAL = 5,     # 普通：無難なアイテム選択
    DISLIKE = -5    # 嫌い：致命傷にならない軽微なペナルティ
}

# キャラ別好みデータ（初回リアクションで情報開示）
var character_preferences = {
    "yuzuki": {"flowers": PresentReaction.FAVORITE, "books": PresentReaction.NORMAL, "weapons": PresentReaction.DISLIKE},
    "retsuji": {"weapons": PresentReaction.FAVORITE, "food": PresentReaction.NORMAL, "flowers": PresentReaction.DISLIKE}
}
```

### イベントシステム詳細

#### 汎用イベント管理
- **序盤～中盤**: 共通イベント多め、自然変動許容で程よい関係性変化
- **後半ルート確定**: 親密/通常/対立ルートが確定後に専用イベント発生
- **推奨ペア限定**: 専用エンディング CG は推奨ペアのみに提供

#### 超対立技発動条件
- **特定ペアのみ**: 恋愛的嫉妬が発生する特定組み合わせ
- **数値条件**: 関係値-100 達成が必須
- **リスク要素**: 高火力だが運用困難なハイリスクスキル

### ラスボス戦（AIリラ）詳細

#### 戦闘メカニクス
```gdscript
# res/Scripts/systems/lira_boss_system.gd
class_name LiraBossSystem
extends Node

# 基本スペック設定
var lira_stats = {
    "attack_type": "physical_main",  # 物理攻撃主体
    "target_type": "single_high",   # 単体高火力
    "physical_defense": "high",     # 高物理耐久
    "magic_weakness": true          # 魔法攻撃が有効
}

# フルパワーモード管理
var is_full_power_mode = false
var turn_limit = 10  # タイムリミット

func on_hp_half():
    is_full_power_mode = true
    apply_endurance_debuff()  # 耐久デバフ
    enable_high_power_attacks()  # 高威力攻撃解放
    start_turn_countdown()  # タイムリミット開始
```

#### 断片アイテムシステム
```gdscript
# 断片収集とデバフ効果
var fragment_count = 0
const REQUIRED_FRAGMENTS = 5

func check_fragments_before_battle() -> bool:
    fragment_count = inventory_system.count_lira_fragments()

    if fragment_count < REQUIRED_FRAGMENTS:
        show_forced_defeat_cutscene()  # 強制敗北演出
        return false  # 戦闘不可

    apply_fragment_debuffs()  # 断片数に応じたデバフ
    return true  # 戦闘開始可能

func apply_fragment_debuffs():
    var debuff_ratio = fragment_count * 0.15  # 断片、1個あたり15%デバフ
    lira_stats.defense_multiplier *= (1.0 - debuff_ratio)
    lira_stats.attack_multiplier *= (1.0 - debuff_ratio * 0.5)
```

#### 救済システム
- **戦闘前再編成**: ラスボス戦直前にペア再編成機会を提供
- **サイトウアドバイス**: 全滅時に戦略的アドバイスを提供
- **リトライシステム**: 死亡時の状態を保持して再挑戦可能
- **難易度バランス**: クリア可能性を保証しつつ挑戦的な難易度を維持
