class_name RelationshipSystem
extends Node

# 関係値システム
# Unity版の関係値システムをGDScriptで再実装
# -25〜100の範囲を25刻みの5段階で管理

signal relationship_changed(char1_id: String, char2_id: String, old_value: int, new_value: int)
signal relationship_level_changed(char1_id: String, char2_id: String, old_level: String, new_level: String)

# 関係値レベルの定義
enum RelationshipLevel {
	HOSTILE = -1,    # 敵対（0〜-25）
	COLD = 0,        # 冷淡（1〜25）
	NORMAL = 1,      # 普通（26〜50）
	FRIENDLY = 2,    # 友好（51〜75）
	INTIMATE = 3     # 親密（76〜100）
}

# 関係値データ
var relationships: Dictionary = {}

# 関係値の境界値
const MIN_VALUE = -25
const MAX_VALUE = 100
const LEVEL_THRESHOLD = 25

func _ready():
	print("RelationshipSystem: 初期化完了")

# 関係値の設定
func set_relationship(char1_id: String, char2_id: String, value: int):
	var clamped_value = clamp(value, MIN_VALUE, MAX_VALUE)
	var key = get_relationship_key(char1_id, char2_id)
	var old_value = relationships.get(key, 50)  # デフォルトは普通レベル
	
	relationships[key] = clamped_value
	
	if old_value != clamped_value:
		relationship_changed.emit(char1_id, char2_id, old_value, clamped_value)
		
		var old_level = get_relationship_level(old_value)
		var new_level = get_relationship_level(clamped_value)
		if old_level != new_level:
			relationship_level_changed.emit(char1_id, char2_id, 
				level_to_string(old_level), level_to_string(new_level))

# 関係値の取得
func get_relationship(char1_id: String, char2_id: String) -> int:
	var key = get_relationship_key(char1_id, char2_id)
	return relationships.get(key, 50)  # デフォルトは普通レベル（50）

# 関係値の変更
func modify_relationship(char1_id: String, char2_id: String, delta: int, reason: String = ""):
	var current_value = get_relationship(char1_id, char2_id)
	var new_value = current_value + delta
	set_relationship(char1_id, char2_id, new_value)
	
	if reason != "":
		print("関係値変更: %s ↔ %s, %+d (%s)" % [char1_id, char2_id, delta, reason])

# 関係値レベルの取得
func get_relationship_level_enum(char1_id: String, char2_id: String) -> RelationshipLevel:
	var value = get_relationship(char1_id, char2_id)
	return get_relationship_level(value)

# 関係値レベル文字列の取得
func get_relationship_level_string(char1_id: String, char2_id: String) -> String:
	var level = get_relationship_level_enum(char1_id, char2_id)
	return level_to_string(level)

# 値から関係値レベルを判定
func get_relationship_level(value: int) -> RelationshipLevel:
	if value <= 0:
		return RelationshipLevel.HOSTILE
	elif value <= 25:
		return RelationshipLevel.COLD
	elif value <= 50:
		return RelationshipLevel.NORMAL
	elif value <= 75:
		return RelationshipLevel.FRIENDLY
	else:
		return RelationshipLevel.INTIMATE

# レベルを文字列に変換
func level_to_string(level: RelationshipLevel) -> String:
	match level:
		RelationshipLevel.HOSTILE:
			return "敵対"
		RelationshipLevel.COLD:
			return "冷淡"
		RelationshipLevel.NORMAL:
			return "普通"
		RelationshipLevel.FRIENDLY:
			return "友好"
		RelationshipLevel.INTIMATE:
			return "親密"
		_:
			return "不明"

# 共闘技が使用可能かチェック
func can_use_cooperation_skill(char1_id: String, char2_id: String) -> bool:
	var level = get_relationship_level_enum(char1_id, char2_id)
	return level == RelationshipLevel.INTIMATE  # 親密レベル（76以上）で使用可能

# 対立技が使用可能かチェック
func can_use_conflict_skill(char1_id: String, char2_id: String) -> bool:
	var level = get_relationship_level_enum(char1_id, char2_id)
	return level == RelationshipLevel.HOSTILE  # 敵対レベル（0以下）で使用可能

# バトルイベントによる関係値変化を処理
func process_battle_event(event_type: String, char1_id: String, char2_id: String):
	match event_type:
		"cooperation":
			modify_relationship(char1_id, char2_id, 12, "戦闘での協力")
		"great_cooperation":
			modify_relationship(char1_id, char2_id, 25, "見事な連携")
		"protection":
			modify_relationship(char1_id, char2_id, 13, "仲間を守った")
		"conflict":
			modify_relationship(char1_id, char2_id, -12, "戦闘での対立")
		"great_conflict":
			modify_relationship(char1_id, char2_id, -25, "深刻な対立")
		"abandonment":
			modify_relationship(char1_id, char2_id, -13, "仲間を見捨てた")

# 関係値のキーを生成（双方向対応）
func get_relationship_key(char1_id: String, char2_id: String) -> String:
	var ids = [char1_id, char2_id]
	ids.sort()
	return ids[0] + "_" + ids[1]

# 全ての関係値データを取得
func get_all_relationships() -> Dictionary:
	return relationships.duplicate()

# 関係値データの一括読み込み（セーブデータから復元）
func load_relationships(data: Dictionary):
	relationships = data.duplicate()
	print("RelationshipSystem: 関係値データ読み込み完了")

# デバッグ用：全関係値の表示
func debug_print_all_relationships():
	print("=== 関係値一覧 ===")
	for key in relationships.keys():
		var value = relationships[key]
		var level = get_relationship_level(value)
		print("%s: %d (%s)" % [key, value, level_to_string(level)])