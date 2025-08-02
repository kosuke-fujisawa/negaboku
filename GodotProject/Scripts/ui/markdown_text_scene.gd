class_name MarkdownTextScene
extends Control

# マークダウンシーケンシャル実行対応のテキストシーン
# Phase 2: 順次実行によるbg・キャラクター表示制御

signal text_finished
signal choice_selected(choice_index: int)
signal sequence_completed

# UI要素
var background_rect: TextureRect
var character_left_rect: TextureRect
var character_right_rect: TextureRect
var text_panel: Panel
var name_label: Label
var text_label: RichTextLabel
var continue_indicator: Label
var debug_panel: Panel
var debug_label: RichTextLabel

# システム
var sequence_controller: MarkdownSequenceController
var asset_manager: AssetResourceManager

# 状態管理
var is_waiting_for_input: bool = false
var current_speaker: String = ""
var current_text: String = ""

# 設定
var show_debug_info: bool = true

func _ready():
	print("MarkdownTextScene: 初期化開始")
	
	# フルスクリーン設定
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# システム初期化
	_initialize_systems()
	
	# UI作成
	_create_ui()
	
	# シグナル接続
	_connect_signals()
	
	# テストシナリオ自動実行
	_start_test_scenario()
	
	print("MarkdownTextScene: 初期化完了")

func _initialize_systems():
	"""システムを初期化"""
	# AssetResourceManager初期化
	asset_manager = AssetResourceManager.get_instance()
	asset_manager.preload_common_assets()
	
	# MarkdownSequenceController初期化
	sequence_controller = MarkdownSequenceController.new()
	add_child(sequence_controller)
	sequence_controller.initialize(self)
	
	# 実行設定
	sequence_controller.set_text_advance_mode("manual")
	sequence_controller.set_auto_advance_delay(2.0)
	sequence_controller.set_command_execution_delay(0.5)

func _create_ui():
	"""UI要素を作成"""
	# 背景
	background_rect = TextureRect.new()
	background_rect.name = "Background"
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(background_rect)
	
	# キャラクター立ち絵（左）
	character_left_rect = TextureRect.new()
	character_left_rect.name = "CharacterLeft"
	character_left_rect.size = Vector2(512, 1024)
	character_left_rect.position = Vector2(100, 50)
	character_left_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	character_left_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	character_left_rect.visible = false
	add_child(character_left_rect)
	
	# キャラクター立ち絵（右）
	character_right_rect = TextureRect.new()
	character_right_rect.name = "CharacterRight"
	character_right_rect.size = Vector2(512, 1024)
	character_right_rect.position = Vector2(512, 50)
	character_right_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	character_right_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	character_right_rect.visible = false
	add_child(character_right_rect)
	
	# テキストパネル
	text_panel = Panel.new()
	text_panel.name = "TextPanel"
	text_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_panel.size.y = 200
	text_panel.position.y = -200
	add_child(text_panel)
	
	# 名前ラベル
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.visible = false
	text_panel.add_child(name_label)
	
	# テキストラベル
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.position = Vector2(20, 50)
	text_label.size = Vector2(760, 100)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_panel.add_child(text_label)
	
	# 継続インジケーター
	continue_indicator = Label.new()
	continue_indicator.name = "ContinueIndicator"
	continue_indicator.text = "▼ (Click to continue)"
	continue_indicator.position = Vector2(600, 160)
	continue_indicator.size = Vector2(180, 30)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_indicator.visible = false
	text_panel.add_child(continue_indicator)
	
	# デバッグパネル（オプション）
	if show_debug_info:
		_create_debug_panel()

func _create_debug_panel():
	"""デバッグパネルを作成"""
	debug_panel = Panel.new()
	debug_panel.name = "DebugPanel"
	debug_panel.position = Vector2(10, 10)
	debug_panel.size = Vector2(300, 150)
	debug_panel.z_index = 100
	add_child(debug_panel)
	
	debug_label = RichTextLabel.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(5, 5)
	debug_label.size = Vector2(290, 140)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.bbcode_enabled = true
	debug_label.fit_content = true
	debug_panel.add_child(debug_label)
	
	_update_debug_info()

func _connect_signals():
	"""シグナル接続"""
	# SequenceControllerのシグナル
	sequence_controller.sequence_completed.connect(_on_sequence_completed)
	sequence_controller.command_executed.connect(_on_command_executed)
	sequence_controller.text_displayed.connect(_on_text_displayed)
	
	# マウスクリックでテキスト進行
	text_panel.gui_input.connect(_on_text_panel_input)

func _input(event):
	"""入力処理"""
	if event.is_action_pressed("ui_accept") and is_waiting_for_input:
		_advance_text()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_text_panel_input(event):
	"""テキストパネルクリック処理"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_waiting_for_input:
			_advance_text()

func _advance_text():
	"""テキスト進行"""
	if is_waiting_for_input:
		is_waiting_for_input = false
		continue_indicator.visible = false
		text_finished.emit()
		print("MarkdownTextScene: テキスト進行")

# 背景・キャラクター設定メソッド（SceneCommandExecutorから呼ばれる）

func set_background(texture_path: String):
	"""背景設定（パス指定）"""
	print("MarkdownTextScene: 背景設定 - %s" % texture_path)
	if texture_path.is_empty():
		background_rect.texture = null
		return
	
	var texture = load(texture_path) as Texture2D
	if texture:
		background_rect.texture = texture
	else:
		print("警告: 背景テクスチャの読み込み失敗: %s" % texture_path)

func set_background_texture(texture: Texture2D):
	"""背景設定（テクスチャ直指定）"""
	background_rect.texture = texture
	print("MarkdownTextScene: 背景テクスチャ設定完了")

func set_character_portrait(position: String, texture_path: String):
	"""キャラクター立ち絵設定（パス指定）"""
	print("MarkdownTextScene: キャラクター設定 - %s: %s" % [position, texture_path])
	
	var character_rect = character_left_rect if position == "left" else character_right_rect
	
	if texture_path.is_empty():
		character_rect.texture = null
		character_rect.visible = false
		return
	
	var texture = load(texture_path) as Texture2D
	if texture:
		character_rect.texture = texture
		character_rect.visible = true
	else:
		print("警告: キャラクターテクスチャの読み込み失敗: %s" % texture_path)

func set_character_texture(position: String, texture: Texture2D):
	"""キャラクター立ち絵設定（テクスチャ直指定）"""
	var character_rect = character_left_rect if position == "left" else character_right_rect
	
	if texture:
		character_rect.texture = texture
		character_rect.visible = true
		print("MarkdownTextScene: キャラクターテクスチャ設定完了 - %s" % position)
	else:
		character_rect.texture = null
		character_rect.visible = false

func show_text(speaker_name: String, text: String):
	"""テキスト表示"""
	current_speaker = speaker_name
	current_text = text
	
	# スピーカー名設定
	if speaker_name.is_empty():
		name_label.text = ""
		name_label.visible = false
	else:
		name_label.text = speaker_name
		name_label.visible = true
	
	# テキスト設定
	text_label.text = text
	
	# 入力待機状態
	is_waiting_for_input = true
	continue_indicator.visible = true
	
	# デバッグ情報更新
	if show_debug_info:
		_update_debug_info()
	
	print("MarkdownTextScene: テキスト表示 - %s: %s" % [speaker_name, text])

# シグナルハンドラー

func _on_sequence_completed():
	"""シーケンス完了"""
	print("MarkdownTextScene: シーケンス完了")
	show_text("システム", "シナリオが完了しました。ESCキーでタイトルに戻ります。")
	sequence_completed.emit()

func _on_command_executed(command_name: String, parameters: Dictionary):
	"""コマンド実行完了"""
	print("MarkdownTextScene: コマンド実行 - %s %s" % [command_name, parameters])
	if show_debug_info:
		_update_debug_info()

func _on_text_displayed(speaker: String, text: String):
	"""テキスト表示完了"""
	print("MarkdownTextScene: テキスト表示通知 - %s: %s" % [speaker, text])

# デバッグ機能

func _update_debug_info():
	"""デバッグ情報更新"""
	if not debug_label:
		return
	
	var progress = sequence_controller.get_progress()
	var scene_state = sequence_controller.get_current_scene_state()
	var state = sequence_controller.get_current_state()
	
	var debug_text = """[b]Debug Info[/b]
State: %s
Progress: %d/%d (%.1f%%)
Background: %s
Left: %s
Right: %s
Waiting: %s""" % [
		sequence_controller._state_to_string(state),
		progress.current_index,
		progress.total_elements,
		progress.progress_percent,
		scene_state.background,
		scene_state.character_left,
		scene_state.character_right,
		is_waiting_for_input
	]
	
	debug_label.text = debug_text

# テスト機能

func _start_test_scenario():
	"""テストシナリオを開始"""
	print("MarkdownTextScene: Phase2テストシナリオ開始")
	# 少し遅らせて実行
	await get_tree().create_timer(1.0).timeout
	load_markdown_scenario("res://Assets/scenarios/phase2_test.md")

func load_markdown_scenario(file_path: String):
	"""マークダウンシナリオを読み込み・実行"""
	print("MarkdownTextScene: マークダウンシナリオ読み込み - %s" % file_path)
	sequence_controller.load_and_execute_markdown_file(file_path)

# デバッグ用ホットキー

func _unhandled_input(event):
	if event.is_action_pressed("ui_select"):  # Spaceキー
		if sequence_controller.get_current_state() == MarkdownSequenceController.State.PAUSED:
			sequence_controller.resume_sequence()
		elif sequence_controller.get_current_state() == MarkdownSequenceController.State.EXECUTING:
			sequence_controller.pause_sequence()
	elif event.is_action_pressed("ui_home"):  # Homeキー（デバッグ情報表示切り替え）
		if debug_panel:
			debug_panel.visible = not debug_panel.visible