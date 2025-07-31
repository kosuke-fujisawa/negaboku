extends Node2D

# バトルシーン
# Unity版のバトルUIをGodotで再実装

var battle_system
var relationship_system

# UI要素の参照
var player1_status: Label
var player2_status: Label
var relationship_status: Label
var enemy1_status: Label
var action_label: Label
var attack_button: Button
var skill_button: Button
var defend_button: Button

var current_turn_character
var enemies
var party_members

func _ready():
	setup_references()
	setup_signals()

func setup_references():
	# ステータス表示要素
	player1_status = $UI/BattleInterface/PartyStatusPanel/VBoxContainer/Player1Status
	player2_status = $UI/BattleInterface/PartyStatusPanel/VBoxContainer/Player2Status
	relationship_status = $UI/BattleInterface/PartyStatusPanel/VBoxContainer/RelationshipStatus
	enemy1_status = $UI/BattleInterface/EnemyStatusPanel/VBoxContainer/Enemy1Status
	
	# アクション選択要素
	action_label = $UI/BattleInterface/ActionPanel/VBoxContainer/ActionLabel
	attack_button = $UI/BattleInterface/ActionPanel/VBoxContainer/AttackButton
	skill_button = $UI/BattleInterface/ActionPanel/VBoxContainer/SkillButton
	defend_button = $UI/BattleInterface/ActionPanel/VBoxContainer/DefendButton
	
	# 初期状態ではアクションパネルを非表示
	$UI/BattleInterface/ActionPanel.visible = false

func setup_signals():
	attack_button.pressed.connect(_on_attack_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	defend_button.pressed.connect(_on_defend_pressed)

func initialize_battle(battle_sys, rel_sys, party: Array, enemy_list: Array):
	battle_system = battle_sys
	relationship_system = rel_sys
	party_members = party.duplicate()
	enemies = enemy_list.duplicate()
	
	# バトルシステムのシグナル接続
	battle_system.battle_started.connect(_on_battle_started)
	battle_system.battle_ended.connect(_on_battle_ended)
	battle_system.turn_started.connect(_on_turn_started)
	battle_system.action_performed.connect(_on_action_performed)
	
	# 初期UI更新
	update_status_display()

func _on_battle_started(enemy_list: Array):
	print("BattleScene: バトル開始")
	update_status_display()

func _on_battle_ended(result):
	print("BattleScene: バトル終了 - 勝利: ", result.victory)
	
	$UI/BattleInterface/ActionPanel.visible = false
	
	if result.victory:
		action_label.text = "勝利！経験値 %d を獲得" % result.experience_gained
	else:
		action_label.text = "敗北..."
	
	# 3秒後にメインシーンに戻る
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_turn_started(character: Character):
	current_turn_character = character
	print("BattleScene: %s のターン" % character.name)
	
	if character in party_members:
		# プレイヤーのターン：アクション選択UI表示
		show_action_panel(character)
	else:
		# 敵のターン：アクションパネル非表示
		$UI/BattleInterface/ActionPanel.visible = false
		action_label.text = "%s の行動中..." % character.name

func show_action_panel(character: Character):
	$UI/BattleInterface/ActionPanel.visible = true
	action_label.text = "%s の行動を選択" % character.name
	
	# スキルボタンの有効/無効を関係値に基づいて設定
	update_skill_button_state(character)

func update_skill_button_state(character: Character):
	if not relationship_system:
		skill_button.disabled = true
		return
	
	var partner = get_partner(character)
	if not partner:
		skill_button.disabled = true
		return
	
	# 共闘技または対立技が使用可能かチェック
	var can_coop = relationship_system.can_use_cooperation_skill(character.character_id, partner.character_id)
	var can_conflict = relationship_system.can_use_conflict_skill(character.character_id, partner.character_id)
	
	skill_button.disabled = not (can_coop or can_conflict)
	
	if can_coop:
		skill_button.text = "共闘技"
	elif can_conflict:
		skill_button.text = "対立技"
	else:
		skill_button.text = "スキル (使用不可)"

func get_partner(character):
	for member in party_members:
		if member != character:
			return member
	return null

func _on_attack_pressed():
	if not current_turn_character:
		return
	
	# 最初の生きている敵を攻撃対象にする
	var target = get_first_alive_enemy()
	if not target:
		return
	
	var battle_script = load("res://Scripts/systems/battle_system.gd")
	if battle_script == null:
		push_error("BattleScene: BattleSystemスクリプトの読み込みに失敗しました")
		return
	
	var action = battle_script.BattleAction.new(battle_script.ActionType.ATTACK)
	action.targets = [target]
	
	battle_system.perform_action(current_turn_character, action)
	$UI/BattleInterface/ActionPanel.visible = false

func _on_skill_pressed():
	if not current_turn_character:
		return
	
	var partner = get_partner(current_turn_character)
	if not partner:
		return
	
	var target = get_first_alive_enemy()
	if not target:
		return
	
	# 関係値に基づいてスキルタイプを決定
	var skill_id = ""
	if relationship_system.can_use_cooperation_skill(current_turn_character.character_id, partner.character_id):
		skill_id = "cooperation_skill"
	elif relationship_system.can_use_conflict_skill(current_turn_character.character_id, partner.character_id):
		skill_id = "conflict_skill"
	else:
		print("BattleScene: スキル使用条件を満たしていません")
		return
	
	var battle_script = load("res://Scripts/systems/battle_system.gd")
	if battle_script == null:
		push_error("BattleScene: BattleSystemスクリプトの読み込みに失敗しました")
		return
	
	var action = battle_script.BattleAction.new(battle_script.ActionType.SKILL)
	action.skill_id = skill_id
	action.targets = [target]
	
	battle_system.perform_action(current_turn_character, action)
	$UI/BattleInterface/ActionPanel.visible = false

func _on_defend_pressed():
	if not current_turn_character:
		return
	
	var battle_script = load("res://Scripts/systems/battle_system.gd")
	if battle_script == null:
		push_error("BattleScene: BattleSystemスクリプトの読み込みに失敗しました")
		return
	
	var action = battle_script.BattleAction.new(battle_script.ActionType.DEFEND)
	battle_system.perform_action(current_turn_character, action)
	$UI/BattleInterface/ActionPanel.visible = false

func get_first_alive_enemy():
	for enemy in enemies:
		if enemy.current_hp > 0:
			return enemy
	return null

func _on_action_performed(actor: Character, action, targets: Array):
	print("BattleScene: %s がアクション実行" % actor.name)
	update_status_display()

func update_status_display():
	# パーティステータス更新
	if party_members.size() >= 1:
		var char1 = party_members[0]
		player1_status.text = "%s: HP %d/%d" % [char1.name, char1.current_hp, char1.max_hp]
	
	if party_members.size() >= 2:
		var char2 = party_members[1]
		player2_status.text = "%s: HP %d/%d" % [char2.name, char2.current_hp, char2.max_hp]
	
	# 関係値表示更新
	if relationship_system and party_members.size() >= 2:
		var rel_value = relationship_system.get_relationship(party_members[0].character_id, party_members[1].character_id)
		var rel_level = relationship_system.get_relationship_level_string(party_members[0].character_id, party_members[1].character_id)
		relationship_status.text = "関係値: %d (%s)" % [rel_value, rel_level]
	
	# 敵ステータス更新
	if enemies.size() >= 1:
		var enemy = enemies[0]
		enemy1_status.text = "%s: HP %d/%d" % [enemy.name, enemy.current_hp, enemy.max_hp]

# デバッグ用：強制勝利
func _input(event):
	if event.is_action_pressed("ui_select") and Input.is_action_pressed("ui_up"):
		# Shift+Space で強制勝利
		for enemy in enemies:
			enemy.current_hp = 0
		update_status_display()
		print("BattleScene: デバッグ - 強制勝利")
	elif event.is_action_pressed("ui_cancel"):
		# ESCでメインシーンに戻る
		get_tree().change_scene_to_file("res://Scenes/Main.tscn")