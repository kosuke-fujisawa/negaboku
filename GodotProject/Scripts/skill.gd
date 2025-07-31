class_name Skill
extends Resource

# スキルクラス
# バトルシステムで使用されるスキルを定義

@export var skill_id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var mp_cost: int = 0
@export var power: int = 50
@export var accuracy: float = 1.0
@export var critical_rate: float = 0.1

# 関係値スキルの設定
@export var requires_relationship: bool = false
@export var affects_relationship: bool = false
@export var relationship_type: String = ""  # "cooperation" or "conflict"

# スキルの対象設定
@export var target_type: String = "enemy"  # "enemy", "ally", "self", "all"
@export var target_count: int = 1

# エフェクト設定
@export var effect_name: String = ""
@export var status_effects = []

func _init():
	resource_name = "Skill"

# スキルの効果を適用
func apply_effect(caster, targets: Array) -> Dictionary:
	var result = {
		"success": false,
		"damage_dealt": 0,
		"healing_done": 0,
		"status_applied": []
	}
	
	if targets.is_empty():
		return result
	
	for target in targets:
		if target == null:
			continue
			
		var damage = calculate_damage(caster, target)
		target.take_damage(damage)
		result.damage_dealt += damage
		
		# ステータス効果の適用
		for status in status_effects:
			target.add_status_effect(status)
			result.status_applied.append(status)
	
	result.success = true
	return result

# ダメージ計算
func calculate_damage(caster, target) -> int:
	if caster == null or target == null:
		return 0
	
	var base_damage = power + caster.attack - target.defense
	base_damage = max(1, base_damage)  # 最低1ダメージ
	
	# クリティカル判定
	if randf() < critical_rate:
		base_damage = int(base_damage * 1.5)
		print("クリティカルヒット！")
	
	return base_damage

# スキルが使用可能かチェック
func can_use(caster) -> bool:
	if caster == null:
		return false
	
	# MP消費チェック
	if caster.current_mp < mp_cost:
		return false
	
	return true

# Dictionary形式でデータを出力
func to_dict() -> Dictionary:
	return {
		"skill_id": skill_id,
		"name": name,
		"description": description,
		"mp_cost": mp_cost,
		"power": power,
		"accuracy": accuracy,
		"critical_rate": critical_rate,
		"requires_relationship": requires_relationship,
		"affects_relationship": affects_relationship,
		"relationship_type": relationship_type,
		"target_type": target_type,
		"target_count": target_count,
		"effect_name": effect_name,
		"status_effects": status_effects
	}

# Dictionary形式からデータを読み込み
func from_dict(data: Dictionary):
	skill_id = data.get("skill_id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	mp_cost = data.get("mp_cost", 0)
	power = data.get("power", 50)
	accuracy = data.get("accuracy", 1.0)
	critical_rate = data.get("critical_rate", 0.1)
	requires_relationship = data.get("requires_relationship", false)
	affects_relationship = data.get("affects_relationship", false)
	relationship_type = data.get("relationship_type", "")
	target_type = data.get("target_type", "enemy")
	target_count = data.get("target_count", 1)
	effect_name = data.get("effect_name", "")
	status_effects = data.get("status_effects", [])