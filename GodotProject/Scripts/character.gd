class_name Character
extends Resource

# キャラクタークラス
# Unity版のCharacterDataをGodotのResourceとして再実装

@export var character_id: String = ""
@export var name: String = ""
@export var level: int = 1
@export var experience: int = 0

# ステータス
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_mp: int = 50
@export var current_mp: int = 50
@export var attack: int = 10
@export var defense: int = 10
@export var speed: int = 10
@export var luck: int = 10

# 状態
@export var status_effects: Array = []
@export var is_party_member: bool = true

# 成長率
@export var hp_growth: float = 1.2
@export var mp_growth: float = 1.1
@export var attack_growth: float = 1.15
@export var defense_growth: float = 1.1
@export var speed_growth: float = 1.05

func _init():
	resource_name = "Character"

# レベルアップ処理
func level_up() -> void:
	level += 1
	
	var old_max_hp = max_hp
	var old_max_mp = max_mp
	
	# ステータス成長
	max_hp = int(max_hp * hp_growth)
	max_mp = int(max_mp * mp_growth)
	attack = int(attack * attack_growth)
	defense = int(defense * defense_growth)
	speed = int(speed * speed_growth)
	
	# HPとMPを回復
	current_hp += (max_hp - old_max_hp)
	current_mp += (max_mp - old_max_mp)
	
	print("%s がレベルアップ！Lv.%d" % [name, level])

# 経験値獲得
func gain_experience(exp: int) -> void:
	experience += exp
	
	# レベルアップ判定
	var required_exp = get_required_experience()
	while experience >= required_exp:
		experience -= required_exp
		level_up()
		required_exp = get_required_experience()

# 次のレベルまでの必要経験値
func get_required_experience() -> int:
	return level * 100

# ダメージ処理
func take_damage(damage: int) -> void:
	current_hp -= damage
	current_hp = max(0, current_hp)
	
	if current_hp == 0:
		print("%s は戦闘不能になった" % name)

# 回復処理
func heal(amount: int) -> void:
	current_hp += amount
	current_hp = min(current_hp, max_hp)

# MP消費
func consume_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		return true
	return false

# ステータス効果の追加
func add_status_effect(effect: String) -> void:
	if effect not in status_effects:
		status_effects.append(effect)
		print("%s に %s の効果" % [name, effect])

# ステータス効果の除去
func remove_status_effect(effect: String) -> void:
	if effect in status_effects:
		status_effects.erase(effect)
		print("%s の %s が解除された" % [name, effect])

# 戦闘不能かチェック
func is_defeated() -> bool:
	return current_hp <= 0

# 完全回復
func full_heal() -> void:
	current_hp = max_hp
	current_mp = max_mp
	status_effects.clear()
	print("%s が完全回復した" % name)

# Dictionary形式でデータを出力（セーブ用）
func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"name": name,
		"level": level,
		"experience": experience,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"max_mp": max_mp,
		"current_mp": current_mp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"luck": luck,
		"status_effects": status_effects,
		"is_party_member": is_party_member,
		"hp_growth": hp_growth,
		"mp_growth": mp_growth,
		"attack_growth": attack_growth,
		"defense_growth": defense_growth,
		"speed_growth": speed_growth
	}

# Dictionary形式からデータを読み込み（ロード用）
func from_dict(data: Dictionary) -> void:
	character_id = data.get("character_id", "")
	name = data.get("name", "")
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	max_hp = data.get("max_hp", 100)
	current_hp = data.get("current_hp", 100)
	max_mp = data.get("max_mp", 50)
	current_mp = data.get("current_mp", 50)
	attack = data.get("attack", 10)
	defense = data.get("defense", 10)
	speed = data.get("speed", 10)
	luck = data.get("luck", 10)
	status_effects = data.get("status_effects", [])
	is_party_member = data.get("is_party_member", true)
	hp_growth = data.get("hp_growth", 1.2)
	mp_growth = data.get("mp_growth", 1.1)
	attack_growth = data.get("attack_growth", 1.15)
	defense_growth = data.get("defense_growth", 1.1)
	speed_growth = data.get("speed_growth", 1.05)

# デバッグ用：ステータス表示
func debug_print_status() -> void:
	print("=== %s (Lv.%d) ===" % [name, level])
	print("HP: %d/%d" % [current_hp, max_hp])
	print("MP: %d/%d" % [current_mp, max_mp])
	print("ATK: %d, DEF: %d, SPD: %d, LUK: %d" % [attack, defense, speed, luck])
	print("EXP: %d/%d" % [experience, get_required_experience()])
	if not status_effects.is_empty():
		print("状態: %s" % ", ".join(status_effects))