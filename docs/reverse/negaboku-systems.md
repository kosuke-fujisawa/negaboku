# Negaboku システム仕様書（逆生成）

## 分析日時
2025-01-05 01:00:00

## システム概要

### コアシステム一覧
1. **関係値システム** - 5段階関係値管理とスキル連動
2. **バトルシステム** - ターン制戦闘と関係値連動スキル
3. **シナリオシステム** - マークダウン駆動テキスト表示
4. **UI管理システム** - Signal駆動UI制御
5. **セーブ・ロードシステム** - JSON形式データ永続化

## 関係値システム詳細仕様

### クラス定義
```gdscript
class_name RelationshipSystem
extends Node

# 5段階関係値レベル
enum RelationshipLevel {
    HOSTILE = -1,    # 敵対（0〜-25）
    COLD = 0,        # 冷淡（1〜25）
    NORMAL = 1,      # 普通（26〜50）
    FRIENDLY = 2,    # 友好（51〜75）
    INTIMATE = 3     # 親密（76〜100）
}
```

### 関係値管理仕様

#### 数値範囲と境界値
| レベル | 数値範囲 | 境界値定数 | 説明 |
|--------|----------|------------|------|
| HOSTILE | -25〜0 | HOSTILE_MAX = 0 | 敵対関係、対立技解放 |
| COLD | 1〜25 | COLD_MAX = 25 | 冷淡、基本スキルのみ |  
| NORMAL | 26〜50 | NORMAL_MAX = 50 | 普通、デフォルト状態 |
| FRIENDLY | 51〜75 | FRIENDLY_MAX = 75 | 友好、協力スキル一部解放 |
| INTIMATE | 76〜100 | INTIMATE_MIN = 76 | 親密、共闘技フル解放 |

#### 関係値変更量定数
```gdscript
const SMALL_COOPERATION = 12     # 小さな協力行動
const LARGE_COOPERATION = 25     # 大きな協力行動
const PROTECTION_BONUS = 13      # 保護行動ボーナス
const SMALL_CONFLICT = -12       # 小さな対立行動
const LARGE_CONFLICT = -25       # 大きな対立行動
const ABANDONMENT_PENALTY = -13  # 見捨て行動ペナルティ
```

#### 主要メソッド
```gdscript
# 関係値設定（基本機能）
func set_relationship(char1_id: String, char2_id: String, value: int) -> bool

# 関係値変更（イベント駆動）
func modify_relationship(char1_id: String, char2_id: String, delta: int, reason: String = "") -> bool

# 関係値取得
func get_relationship(char1_id: String, char2_id: String) -> int

# 関係レベル判定
func get_relationship_level(char1_id: String, char2_id: String) -> RelationshipLevel
func get_relationship_level_string(char1_id: String, char2_id: String) -> String

# バルク操作
func get_all_relationships() -> Dictionary
func set_multiple_relationships(relationship_data: Dictionary) -> bool
```

#### Signal仕様
```gdscript
# 関係値数値変更通知
signal relationship_changed(char1_id: String, char2_id: String, old_value: int, new_value: int)

# 関係レベル変更通知（レベル境界を超えた場合のみ）
signal relationship_level_changed(char1_id: String, char2_id: String, old_level: String, new_level: String)
```

## バトルシステム詳細仕様

### クラス定義
```gdscript
class_name BattleSystem
extends Node

# 戦闘状態管理
enum BattleState {
    IDLE,          # 待機中
    PREPARING,     # 戦闘準備中
    IN_PROGRESS,   # 戦闘進行中
    ENDING         # 戦闘終了処理中
}

# アクションタイプ
enum ActionType {
    ATTACK,   # 通常攻撃
    SKILL,    # スキル使用
    ITEM,     # アイテム使用
    DEFEND    # 防御
}
```

### スキルシステム仕様

#### スキル分類
```gdscript
enum SkillType {
    NORMAL,      # 白：常時使用可能
    MAGIC,       # 青：MP消費、常時使用可能
    COOPERATION, # 緑：関係値+50以上で解放（共闘技）
    CONFLICT     # 赤：関係値-50以下、特定ペアのみ（対立技）
}
```

#### 関係値連動スキル発動条件
| スキルタイプ | 発動条件 | 効果 |
|-------------|----------|------|
| NORMAL | なし | 標準ダメージ |
| MAGIC | MP消費 | 属性ダメージ、特殊効果 |
| COOPERATION | 関係値 >= 50 | 高威力+追加効果、イージー寄り |
| CONFLICT | 関係値 <= -50 & 特定ペア | ハイリスクハイリターン |

#### 特定対立ペア定義
```gdscript
var special_conflict_pairs = [
    "souma_kai",      # ソウマ × カイ（価値観不一致）
    "yuzuki_serene",  # ユズキ × セリーヌ（三角関係）
    "retsuji_kengo"   # レツジ × ケンゴ（過去の事件）
]
```

### バトルフロー仕様

#### ターン管理
```gdscript
# ターン順序決定（敏捷性ベース）
func calculate_turn_order(all_characters: Array) -> Array

# ターン実行
func execute_turn(character: Character) -> void

# 行動選択
func select_action(character: Character) -> BattleAction

# スキル発動可否判定
func can_use_skill(character1_id: String, character2_id: String, skill_type: SkillType) -> bool
```

#### Signal仕様
```gdscript
signal battle_started(enemies: Array)
signal battle_ended(result: BattleResult)
signal turn_started(character: Character)
signal action_performed(actor: Character, action: BattleAction, targets: Array)
signal skill_activated(actor: Character, skill: Skill, targets: Array)
```

## シナリオシステム詳細仕様

### マークダウンパーサー仕様

#### サポートする構文
```markdown
# タイトル（スキップ）
[bg storage=forest_day.jpg time=500]          # 背景変更コマンド
[chara_show name=souma face=normal pos=left]  # キャラクター表示
[wait time=1000]                              # 待機コマンド
**ソウマ**「セリフ内容」                      # スピーカー付きテキスト
通常のテキスト                                # 地の文
---                                           # シーン区切り
```

#### ParsedElement構造
```gdscript
class ParsedElement:
    enum Type {
        COMMAND,     # [bg storage=xxx] 等のコマンド
        TEXT,        # テキスト内容
        SPEAKER,     # **スピーカー名**「セリフ」
        SEPARATOR    # --- セパレーター
    }
    
    var type: Type
    var content: String = ""
    var speaker: String = ""
    var parameters: Dictionary = {}
```

#### 正規表現パターン
```gdscript
# コマンドパターン: [bg storage=forest.jpg time=500]
command_regex = r'\[([a-zA-Z_]+)([^\]]*)\]'

# スピーカーテキストパターン: **ソウマ**「こんにちは」
speaker_text_regex = r'\*\*([^*]+)\*\*[「『]([^」』]+)[」』]'

# セパレーターパターン: ---
separator_regex = r'^---+\s*$'
```

### シナリオローダー仕様

#### ScenarioData構造
```gdscript
class ScenarioData:
    var file_path: String = ""
    var title: String = ""
    var scenes: Array[SceneBlock] = []
    var metadata: Dictionary = {}

class SceneBlock:
    var block_id: String = ""
    var commands: Array[MarkdownParser.ParsedElement] = []
    var text_elements: Array[MarkdownParser.ParsedElement] = []
    var metadata: Dictionary = {}
```

#### キャッシュ管理
```gdscript
# キャッシュ機能付き読み込み
func load_scenario_file(file_path: String) -> ScenarioData

# 強制再読み込み（開発時用）
func force_reload_scenario_file(file_path: String) -> ScenarioData

# キャッシュクリア
func clear_cache() -> void
```

## UI管理システム詳細仕様

### UIコンポーネント一覧

#### DialogueBox（ダイアログボックス）
```gdscript
class_name DialogueBox extends Control

# 機能
- タイピング効果付きテキスト表示
- スピーカー名表示機能
- 継続インジケーター表示

# Signal
signal dialogue_finished    # ダイアログ表示完了
signal next_line_requested  # 次の行要求
signal dialogue_skipped     # ダイアログスキップ
```

#### ChoicePanel（選択肢パネル）
```gdscript
class_name ChoicePanel extends Control

# 機能
- 動的選択肢生成
- 条件付き選択肢表示
- ホバー効果

# Signal
signal choice_selected(choice_index: int, choice_text: String)
signal choice_hovered(choice_index: int)
```

#### EffectLayer（エフェクト管理）
```gdscript
class_name EffectLayer extends Control

# サポートエフェクト
- explosion: 爆発エフェクト
- slash: 斬撃エフェクト
- light: 光エフェクト
- camera_shake: カメラ振動

# Signal
signal effect_completed(effect_name: String)
```

### シーン遷移管理

#### SceneTransitionManager
```gdscript
class_name SceneTransitionManager extends Node

# 機能
- シーン間遷移制御
- フェード効果
- ロード画面管理

# シーン定義
var available_scenes = [
    {"id": "scene01", "path": "res://Assets/scenarios/scene01.md"},
    {"id": "scene02", "path": "res://Assets/scenarios/scene02.md"}
]

# Signal
signal scene_loaded(scene_id: String)
signal transition_started(from_scene: String, to_scene: String)
signal transition_completed(scene_id: String)
```

## セーブ・ロードシステム詳細仕様

### データ構造
```gdscript
# セーブデータ形式（JSON）
var save_data = {
    "version": "1.0",
    "timestamp": Time.get_unix_time_from_system(),
    "party_members": [],
    "relationships": relationship_system.get_all_relationships(),
    "game_progress": {
        "current_scene": "scene01",
        "scene_index": 0,
        "flags": {}
    },
    "settings": {
        "master_volume": 100,
        "bgm_volume": 100,
        "sfx_volume": 100,
        "fullscreen": false
    }
}
```

### ファイル管理
```gdscript
# セーブファイルパス
const SAVE_FILE_PATH = "user://savegame.save"
const SETTINGS_FILE_PATH = "user://settings.cfg"
const AUTO_SAVE_PATH = "user://autosave.save"

# 主要メソッド
func save_game() -> bool
func load_game() -> bool
func has_save_data() -> bool
func delete_save_data() -> bool
```

## デバッグシステム詳細仕様

### 統合デバッグパネル機能
```gdscript
# デバッグビルド限定機能
if OS.is_debug_build():
    # 関係値操作ボタン
    increase_button: +25ボタン
    decrease_button: -25ボタン
    
    # システムテストボタン
    test_dialogue_button: ダイアログテスト
    test_choices_button: 選択肢テスト
    test_battle_button: バトルテスト
    test_effects_button: エフェクトテスト
    test_markdown_button: マークダウン解析テスト
```

### デバッグログ仕様
```gdscript
# 関係値システムログ
"RelationshipSystem: 関係値変更 - %s ↔ %s: %d → %d (%s)"

# マークダウンパーサーログ
"MarkdownParser: ファイル読み込み成功 - %d文字"
"マークダウン解析完了: %d要素を解析"

# シナリオローダーログ
"★★★ ScenarioLoader: 強制再読み込み開始: %s"
"✅ ScenarioLoader: キャッシュから削除完了: %s"
```

## パフォーマンス仕様

### 軽量化実績
- **ファイルサイズ**: Unity 500MB → Godot 10MB（98%削減）
- **起動時間**: 15-30秒 → 1-3秒（90%高速化）
- **メモリ使用量**: 200-400MB → 50-100MB（75%削減）

### 最適化手法
```gdscript
# Object Pool実装
var effect_object_pool: Array = []

# Signal接続の適切な管理
func _exit_tree():
    # Signal切断処理
    
# キャッシュシステム
var loaded_scenarios: Dictionary = {}
```

## エラー処理・フォールバック仕様

### エラー分類
1. **ファイル読み込みエラー**: デフォルトデータで継続
2. **パースエラー**: 構文検証後、警告表示で継続
3. **システムエラー**: push_error()でログ出力、安全な状態に復帰

### フォールバック動作
```gdscript
# シナリオ読み込み失敗時
if loaded_scenario_data == null:
    print("マークダウン読み込み失敗、デフォルトテキストを使用")
    converted_scenes.clear()
    # デフォルトテストテキストで継続

# 関係値システムエラー時
if char1_id.is_empty() or char2_id.is_empty():
    push_error("キャラクターIDが空です")
    return false  # 安全な失敗
```

---

この仕様書は実装済みのGodotプロジェクトから逆生成されており、Scene + Node + Signal駆動による関係値重視型RPGシステムの完全な実装仕様を記録している。統合デバッグ機能により高速プロトタイピングを実現し、エラー処理・フォールバック機能で安定性を確保している。