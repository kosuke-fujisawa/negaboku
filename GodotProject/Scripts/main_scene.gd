extends Node2D

# メインシーン
# 全システムを統合し、動作確認可能な最小サイクルを実装

var game_manager: Node
var dialogue_box: Control
var choice_panel: Control
var effect_layer: Control

# デバッグUI要素
var relationship_label: Label
var test_dialogue_button: Button
var test_choices_button: Button
var test_battle_button: Button
var test_effects_button: Button
var increase_button: Button
var decrease_button: Button
var save_button: Button
var load_button: Button
var return_to_title_button: Button

# テスト用データ
var test_dialogue_lines: Array[String] = [
	"こんにちは、テストダイアログです。",
	"これは関係値重視型RPGのプロトタイプです。",
	"選択肢によって関係値が変化し、スキル発動条件が変わります。",
	"Godot 4.xで実装されています。"
]

var test_choices: Array[String] = [
	"協力的な選択肢（関係値+25）",
	"普通の選択肢（変化なし）",
	"対立的な選択肢（関係値-25）",
	"条件が必要な選択肢（親密レベル必要）"
]

func _ready():
	print("MainScene: 初期化開始")
	setup_references()
	setup_signals()
	setup_game_manager()
	print("MainScene: 初期化完了")

func setup_references():
	# UI要素の参照を取得
	dialogue_box = $UI/GameInterface/DialogueBox
	choice_panel = $UI/GameInterface/ChoicePanel
	effect_layer = $UI/GameInterface/EffectLayer
	
	# デバッグUI要素の参照（デバッグビルドのみ）
	if OS.is_debug_build():
		relationship_label = $UI/DebugInterface/DebugPanel/VBoxContainer/RelationshipLabel
		test_dialogue_button = $UI/DebugInterface/DebugPanel/VBoxContainer/TestDialogueButton
		test_choices_button = $UI/DebugInterface/DebugPanel/VBoxContainer/TestChoicesButton
		test_battle_button = $UI/DebugInterface/DebugPanel/VBoxContainer/TestBattleButton
		test_effects_button = $UI/DebugInterface/DebugPanel/VBoxContainer/TestEffectsButton
		increase_button = $UI/DebugInterface/DebugPanel/VBoxContainer/ModifyRelationshipContainer/IncreaseButton
		decrease_button = $UI/DebugInterface/DebugPanel/VBoxContainer/ModifyRelationshipContainer/DecreaseButton
		save_button = $UI/DebugInterface/DebugPanel/VBoxContainer/SaveButton
		load_button = $UI/DebugInterface/DebugPanel/VBoxContainer/LoadButton
		return_to_title_button = $UI/DebugInterface/DebugPanel/VBoxContainer/ReturnToTitleButton
	else:
		# 本番ビルドではデバッグUIを無効化
		var debug_interface = $UI/DebugInterface
		if debug_interface:
			debug_interface.visible = false

func setup_signals():
	# ダイアログシステムのシグナル接続
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	
	# 選択肢システムのシグナル接続
	choice_panel.choice_selected.connect(_on_choice_selected)
	
	# エフェクトシステムのシグナル接続
	effect_layer.effect_completed.connect(_on_effect_completed)
	
	# デバッグボタンのシグナル接続（デバッグビルドのみ）
	if OS.is_debug_build():
		test_dialogue_button.pressed.connect(_on_test_dialogue_pressed)
		test_choices_button.pressed.connect(_on_test_choices_pressed)
		test_battle_button.pressed.connect(_on_test_battle_pressed)
		test_effects_button.pressed.connect(_on_test_effects_pressed)
		increase_button.pressed.connect(_on_increase_relationship_pressed)
		decrease_button.pressed.connect(_on_decrease_relationship_pressed)
		save_button.pressed.connect(_on_save_pressed)
		load_button.pressed.connect(_on_load_pressed)
		return_to_title_button.pressed.connect(_on_return_to_title_pressed)

func setup_game_manager():
	# GameManagerは既にAutoLoadとして利用可能
	if GameManager == null:
		push_error("MainScene: GameManagerのAutoLoadが見つかりません")
		return
	
	game_manager = GameManager
	
	# GameManagerの初期化完了を待つ
	if not game_manager.is_initialized:
		await game_manager.game_initialized
	
	# 関係値システムの存在確認
	if game_manager.relationship_system == null:
		push_error("MainScene: RelationshipSystemが初期化されていません")
		return
	
	# 関係値システムのシグナル接続
	game_manager.relationship_system.relationship_changed.connect(_on_relationship_changed)
	game_manager.relationship_system.relationship_level_changed.connect(_on_relationship_level_changed)
	
	# 初期関係値表示更新
	update_relationship_display()

func update_relationship_display():
	if not game_manager or not game_manager.relationship_system:
		return
	
	# デバッグビルドでのみ表示更新
	if OS.is_debug_build() and relationship_label:
		var rel_value = game_manager.relationship_system.get_relationship("player", "partner")
		var rel_level = game_manager.relationship_system.get_relationship_level_string("player", "partner")
		relationship_label.text = "関係値: %d (%s)" % [rel_value, rel_level]

# ダイアログシステムのテスト
func _on_test_dialogue_pressed():
	print("MainScene: ダイアログテスト開始")
	dialogue_box.show_dialogue(test_dialogue_lines, "テストキャラクター")

func _on_dialogue_finished():
	print("MainScene: ダイアログテスト完了")

# 選択肢システムのテスト
func _on_test_choices_pressed():
	print("MainScene: 選択肢テスト開始")
	
	# 選択肢の有効状態を関係値に基づいて決定
	var enabled_states = [true, true, true, false]
	
	# 親密レベルの場合は4番目の選択肢を有効化
	var rel_level_str = game_manager.relationship_system.get_relationship_level_string("player", "partner")
	if rel_level_str == "親密":
		enabled_states[3] = true
	
	choice_panel.show_choices(test_choices, enabled_states)

func _on_choice_selected(choice_index: int, choice_text: String):
	print("MainScene: 選択肢 %d を選択: %s" % [choice_index, choice_text])
	
	# 選択肢に応じて関係値を変更
	match choice_index:
		0:  # 協力的な選択肢
			game_manager.relationship_system.modify_relationship("player", "partner", 25, "協力的な行動")
			effect_layer.play_effect("heal", get_viewport_rect().size / 2)
		1:  # 普通の選択肢
			print("関係値に変化なし")
		2:  # 対立的な選択肢
			game_manager.relationship_system.modify_relationship("player", "partner", -25, "対立的な行動")
			effect_layer.play_effect("explosion", get_viewport_rect().size / 2)
		3:  # 条件が必要な選択肢
			game_manager.relationship_system.modify_relationship("player", "partner", 12, "特別な行動")
			effect_layer.play_effect("light")

# バトルシステムのテスト
func _on_test_battle_pressed():
	print("MainScene: バトルシステムテスト開始")
	
	# テスト用の敵を作成（class_nameを使用し、直接インスタンス化）
	var enemy = Character.new()
	
	enemy.character_id = "test_enemy"
	enemy.name = "テスト敵"
	enemy.max_hp = 50
	enemy.current_hp = 50
	enemy.attack = 8
	enemy.defense = 5
	enemy.speed = 7
	enemy.is_party_member = false
	
	# バトル開始
	game_manager.battle_system.initialize(game_manager.party_members, game_manager.relationship_system)
	game_manager.battle_system.start_battle([enemy])

# エフェクトシステムのテスト
func _on_test_effects_pressed():
	print("MainScene: エフェクトテスト開始")
	
	# 各種エフェクトを順次再生
	var center = get_viewport_rect().size / 2
	
	effect_layer.play_effect("explosion", center + Vector2(-100, 0))
	await get_tree().create_timer(1.0).timeout
	
	effect_layer.play_effect("slash", center)
	await get_tree().create_timer(1.0).timeout
	
	effect_layer.play_effect("light")
	await get_tree().create_timer(1.0).timeout
	
	effect_layer.play_effect("heal", center + Vector2(100, 0))

# 関係値変更
func _on_increase_relationship_pressed():
	game_manager.relationship_system.modify_relationship("player", "partner", 25, "デバッグボタン")

func _on_decrease_relationship_pressed():
	game_manager.relationship_system.modify_relationship("player", "partner", -25, "デバッグボタン")

# セーブ・ロード
func _on_save_pressed():
	game_manager.save_game()
	print("MainScene: セーブ完了")

func _on_load_pressed():
	var success = game_manager.load_game()
	if success:
		update_relationship_display()
		print("MainScene: ロード完了")
	else:
		print("MainScene: ロード失敗")

func _on_return_to_title_pressed():
	print("MainScene: タイトル画面に戻ります")
	GameManager.return_to_title()

# 関係値変更の通知
func _on_relationship_changed(char1_id: String, char2_id: String, old_value: int, new_value: int):
	print("MainScene: 関係値変更 %s↔%s: %d → %d" % [char1_id, char2_id, old_value, new_value])
	update_relationship_display()

func _on_relationship_level_changed(char1_id: String, char2_id: String, old_level: String, new_level: String):
	print("MainScene: 関係レベル変更 %s↔%s: %s → %s" % [char1_id, char2_id, old_level, new_level])
	
	# レベル変更時のエフェクト
	if old_level == "普通" and new_level == "友好":
		effect_layer.play_effect("heal", get_viewport_rect().size / 2)
	elif old_level == "友好" and new_level == "親密":
		effect_layer.play_effect("light")
	elif old_level == "普通" and new_level == "冷淡":
		effect_layer.play_effect("explosion", get_viewport_rect().size / 2)

func _on_effect_completed(effect_name: String):
	print("MainScene: エフェクト '%s' 完了" % effect_name)

# ゲームサイクルのデモンストレーション
func start_demo_cycle():
	print("MainScene: デモサイクル開始")
	
	# 1. ダイアログ表示
	dialogue_box.show_dialogue([
		"デモンストレーションを開始します。",
		"これから選択肢が表示されます。"
	], "システム")
	
	await dialogue_box.dialogue_finished
	
	# 2. 選択肢表示
	choice_panel.show_choices([
		"友好的に接する",
		"普通に接する",
		"冷たく接する"
	])
	
	await choice_panel.choice_selected
	
	# 3. 結果ダイアログ
	dialogue_box.show_dialogue([
		"選択の結果が関係値に反映されました。",
		"デモンストレーション完了です。"
	], "システム")

# キーボードショートカット
func _input(event: InputEvent):
	if event.is_action_pressed("ui_select"):  # スペースキー
		if not dialogue_box.visible and not choice_panel.visible:
			start_demo_cycle()
	elif event.is_action_pressed("ui_cancel"):  # ESCキー
		# タイトル画面に戻る
		GameManager.return_to_title()