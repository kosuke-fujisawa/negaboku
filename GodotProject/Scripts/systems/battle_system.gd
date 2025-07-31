class_name BattleSystem
extends Node

# バトルシステム
# Unity版のバトルシステムをGDScriptで再実装
# 関係値連動スキル、ターン制戦闘を管理

signal battle_started(enemies: Array)
signal battle_ended(result)
signal turn_started(character)
signal action_performed(actor, action, targets: Array)
signal skill_activated(actor, skill, targets: Array)

enum BattleState {
	IDLE,
	PREPARING,
	IN_PROGRESS,
	ENDING
}

enum ActionType {
	ATTACK,
	SKILL,
	ITEM,
	DEFEND
}

var current_state: BattleState = BattleState.IDLE
var party_members = []
var enemies = []
var current_turn_character
var turn_queue = []
var relationship_system

class BattleAction:
	var type: ActionType
	var skill_id: String = ""
	var item_id: String = ""
	var targets = []
	
	func _init(action_type: ActionType = ActionType.ATTACK):
		type = action_type

class BattleResult:
	var victory: bool = false
	var experience_gained: int = 0
	var items_obtained = []
	var relationship_changes: Dictionary = {}

func _ready():
	print("BattleSystem: 初期化完了")

func initialize(party: Array, rel_system) -> bool:
	if party == null or party.is_empty():
		push_error("BattleSystem: パーティが無効です")
		return false
	
	if rel_system == null:
		push_error("BattleSystem: RelationshipSystemがnullです")
		return false
	
	# パーティメンバーの妥当性チェック
	for member in party:
		if member == null:
			push_error("BattleSystem: パーティにnullのメンバーが含まれています")
			return false
	
	party_members = party.duplicate()
	relationship_system = rel_system
	print("BattleSystem: パーティとシステム設定完了")
	return true

func start_battle(enemy_list: Array) -> bool:
	if current_state != BattleState.IDLE:
		push_warning("BattleSystem: 既にバトル中です")
		return false
	
	if enemy_list == null or enemy_list.is_empty():
		push_error("BattleSystem: 敵リストが無効です")
		return false
	
	if party_members.is_empty():
		push_error("BattleSystem: パーティが設定されていません")
		return false
	
	# 敵の妥当性チェック
	for enemy in enemy_list:
		if enemy == null:
			push_error("BattleSystem: 敵リストにnullが含まれています")
			return false
	
	current_state = BattleState.PREPARING
	enemies = enemy_list.duplicate()
	
	print("BattleSystem: バトル開始 - 敵 %d体" % enemies.size())
	
	# ターン順序の決定
	if not setup_turn_queue():
		push_error("BattleSystem: ターン順序の設定に失敗しました")
		current_state = BattleState.IDLE
		return false
	
	current_state = BattleState.IN_PROGRESS
	battle_started.emit(enemies)
	
	# 最初のターンを開始
	start_next_turn()
	return true

func setup_turn_queue() -> bool:
	turn_queue.clear()
	
	if party_members.is_empty():
		push_error("BattleSystem: パーティメンバーが空です")
		return false
	
	if enemies.is_empty():
		push_error("BattleSystem: 敵が空です")
		return false
	
	# パーティメンバーと敵を速度順でソート
	var all_combatants = []
	
	# nullチェックしながら追加
	for member in party_members:
		if member == null:
			push_error("BattleSystem: パーティメンバーにnullが含まれています")
			return false
		all_combatants.append(member)
	
	for enemy in enemies:
		if enemy == null:
			push_error("BattleSystem: 敵にnullが含まれています")
			return false
		all_combatants.append(enemy)
	
	if all_combatants.is_empty():
		push_error("BattleSystem: 戦闘参加者がいません")
		return false
	
	# 速度でソート（降順）
	all_combatants.sort_custom(func(a, b): return a.speed > b.speed)
	turn_queue = all_combatants
	
	print("BattleSystem: ターン順序決定 - %d人" % turn_queue.size())
	return true

func start_next_turn():
	if current_state != BattleState.IN_PROGRESS:
		return
	
	# 戦闘終了条件をチェック
	if check_battle_end():
		end_battle()
		return
	
	# 次のキャラクターのターン
	if turn_queue.is_empty():
		if not setup_turn_queue():  # 全員のターンが終わったら再度セットアップ
			push_error("BattleSystem: ターン順序の再設定に失敗しました")
			end_battle()
			return
	
	if turn_queue.is_empty():
		push_error("BattleSystem: ターンキューが空です")
		end_battle()
		return
	
	current_turn_character = turn_queue.pop_front()
	
	if current_turn_character == null:
		push_error("BattleSystem: 現在のターンキャラクターがnullです")
		start_next_turn()
		return
	
	# 戦闘不能チェック
	if current_turn_character.current_hp <= 0:
		start_next_turn()
		return
	
	print("BattleSystem: %s のターン開始" % current_turn_character.name)
	turn_started.emit(current_turn_character)
	
	# AIか人間かで処理を分岐
	if current_turn_character in enemies:
		await process_ai_turn(current_turn_character)
	else:
		# プレイヤーの入力待ち（UIシステムから呼び出される）
		pass

func perform_action(actor, action):
	if current_state != BattleState.IN_PROGRESS or actor != current_turn_character:
		print("BattleSystem: 無効なアクション")
		return
	
	print("BattleSystem: %s がアクション実行" % actor.name)
	
	match action.type:
		ActionType.ATTACK:
			perform_attack(actor, action.targets)
		ActionType.SKILL:
			perform_skill(actor, action.skill_id, action.targets)
		ActionType.ITEM:
			use_item(actor, action.item_id, action.targets)
		ActionType.DEFEND:
			perform_defend(actor)
	
	action_performed.emit(actor, action, action.targets)
	
	# ターン終了
	await get_tree().create_timer(1.0).timeout  # 演出待機
	start_next_turn()

func perform_attack(actor, targets: Array) -> bool:
	if actor == null:
		push_error("BattleSystem: 攻撃者がnullです")
		return false
	
	if targets == null or targets.is_empty():
		push_error("BattleSystem: 攻撃対象が指定されていません")
		return false
	
	if targets.size() == 0:
		push_error("BattleSystem: 攻撃対象配列が空です")
		return false
	
	var target = targets[0]
	if target == null:
		push_error("BattleSystem: 攻撃対象がnullです")
		return false
	
	var damage = calculate_attack_damage(actor, target)
	
	target.current_hp -= damage
	target.current_hp = max(0, target.current_hp)
	
	print("BattleSystem: %s が %s に %d ダメージ" % [actor.name, target.name, damage])
	return true

func perform_skill(actor, skill_id: String, targets: Array):
	var skill = get_skill_data(skill_id)
	if not skill:
		print("BattleSystem: スキル %s が見つかりません" % skill_id)
		return
	
	# 関係値スキルの発動チェック
	if skill.requires_relationship:
		if not check_relationship_skill_condition(actor, skill):
			print("BattleSystem: 関係値条件を満たしていません")
			return
	
	# スキル効果の適用
	apply_skill_effects(actor, skill, targets)
	
	# 関係値変化の処理
	if skill.affects_relationship:
		process_skill_relationship_effects(actor, skill)
	
	skill_activated.emit(actor, skill, targets)

func check_relationship_skill_condition(actor, skill) -> bool:
	if not relationship_system:
		return false
	
	# パートナーを特定
	var partner = get_partner(actor)
	if not partner:
		return false
	
	match skill.relationship_type:
		"cooperation":
			return relationship_system.can_use_cooperation_skill(actor.character_id, partner.character_id)
		"conflict":
			return relationship_system.can_use_conflict_skill(actor.character_id, partner.character_id)
		_:
			return true

func get_partner(character):
	for member in party_members:
		if member != character:
			return member
	return null

func calculate_attack_damage(attacker, target) -> int:
	var base_damage = attacker.attack - target.defense
	base_damage = max(1, base_damage)  # 最低1ダメージ
	
	# 関係値による修正
	var partner = get_partner(attacker)
	if partner and relationship_system:
		var relationship_bonus = get_relationship_damage_bonus(attacker, partner)
		base_damage = int(base_damage * relationship_bonus)
	
	# ランダム要素
	var variance = randf() * 0.2 + 0.9  # 0.9〜1.1倍
	return int(base_damage * variance)

func get_relationship_damage_bonus(char1, char2) -> float:
	var level = relationship_system.get_relationship_level_enum(char1.character_id, char2.character_id)
	match level:
		3:  # INTIMATE
			return 1.2  # 親密：+20%
		2:  # FRIENDLY
			return 1.1  # 友好：+10%
		1:  # NORMAL
			return 1.0  # 普通：変化なし
		0:  # COLD
			return 0.9  # 冷淡：-10%
		-1: # HOSTILE
			return 0.8  # 敵対：-20%
		_:
			return 1.0

func process_ai_turn(ai_character):
	if ai_character == null:
		push_error("BattleSystem: AIキャラクターがnullです")
		start_next_turn()
		return
	
	print("BattleSystem: AI %s の行動決定中..." % ai_character.name)
	
	# 簡単なAI：体力が低い敵を優先攻撃
	if party_members.is_empty():
		push_error("BattleSystem: パーティメンバーが空です")
		start_next_turn()
		return
	
	var targets = party_members.filter(func(c): return c != null and c.current_hp > 0)
	if targets.is_empty():
		push_warning("BattleSystem: 攻撃可能な対象がいません")
		start_next_turn()
		return
	
	# nullチェック付きソート
	var valid_targets = []
	for target in targets:
		if target != null:
			valid_targets.append(target)
	
	if valid_targets.is_empty():
		push_error("BattleSystem: 有効な攻撃対象がいません")
		start_next_turn()
		return
	
	valid_targets.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	var selected_target = valid_targets[0]
	
	if selected_target == null:
		push_error("BattleSystem: 選択された攻撃対象がnullです")
		start_next_turn()
		return
	
	var action = BattleAction.new(ActionType.ATTACK)
	if action == null:
		push_error("BattleSystem: BattleActionの生成に失敗しました")
		start_next_turn()
		return
	
	action.targets = [selected_target]
	
	await get_tree().create_timer(1.5).timeout  # AI思考時間
	perform_action(ai_character, action)

func check_battle_end() -> bool:
	var alive_party = party_members.filter(func(c): return c.current_hp > 0)
	var alive_enemies = enemies.filter(func(c): return c.current_hp > 0)
	
	return alive_party.is_empty() or alive_enemies.is_empty()

func end_battle():
	current_state = BattleState.ENDING
	
	var alive_party = party_members.filter(func(c): return c.current_hp > 0)
	var victory = not alive_party.is_empty()
	
	var result = BattleResult.new()
	result.victory = victory
	
	if victory:
		result.experience_gained = calculate_experience()
		print("BattleSystem: 勝利！経験値 %d 獲得" % result.experience_gained)
	else:
		print("BattleSystem: 敗北...")
	
	current_state = BattleState.IDLE
	battle_ended.emit(result)

func calculate_experience() -> int:
	var total_exp = 0
	for enemy in enemies:
		total_exp += enemy.level * 10
	return total_exp

func get_skill_data(skill_id: String):
	# スキルの仮実装データ
	var skill_data = {}
	
	match skill_id:
		"cooperation_skill":
			skill_data = {
				"id": skill_id,
				"name": "共闘技",
				"requires_relationship": true,
				"affects_relationship": true,
				"relationship_type": "cooperation",
				"power": 150
			}
		"conflict_skill":
			skill_data = {
				"id": skill_id,
				"name": "対立技",
				"requires_relationship": true,
				"affects_relationship": true,
				"relationship_type": "conflict",
				"power": 120
			}
		_:
			skill_data = {
				"id": skill_id,
				"name": "基本スキル",
				"requires_relationship": false,
				"affects_relationship": false,
				"relationship_type": "",
				"power": 100
			}
	
	return skill_data

func apply_skill_effects(actor, skill, targets: Array):
	# スキル効果の適用（仮実装）
	for target in targets:
		var damage = skill.power
		target.current_hp -= damage
		target.current_hp = max(0, target.current_hp)
		print("BattleSystem: %s のスキル %s で %s に %d ダメージ" % [actor.name, skill.name, target.name, damage])

func process_skill_relationship_effects(actor, skill):
	var partner = get_partner(actor)
	if not partner or not relationship_system:
		return
	
	match skill.relationship_type:
		"cooperation":
			relationship_system.process_battle_event("cooperation", actor.character_id, partner.character_id)
		"conflict":
			relationship_system.process_battle_event("conflict", actor.character_id, partner.character_id)

func use_item(actor, item_id: String, targets: Array):
	print("BattleSystem: %s がアイテム %s を使用" % [actor.name, item_id])
	# TODO: アイテム効果の実装

func perform_defend(actor):
	print("BattleSystem: %s が防御" % actor.name)
	# 防御効果（次のダメージ半減など）