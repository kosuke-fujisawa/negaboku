class_name MainTextScene
extends Control

# メインのテキストシーン - マークダウンシナリオ対応

# 定数定義
const SCENARIO_PATH = "res://Assets/scenarios/scene01.md"
const SCENARIO_LOADER_PATH = "res://Scripts/systems/scenario_loader.gd"
const SPEAKER_SEPARATOR = ": "
const CONTINUE_INDICATOR_TEXT = "▼"
const LOG_BUTTON_TEXT = "ログ"
const CLOSE_BUTTON_TEXT = "閉じる"
const SYSTEM_SPEAKER = "システム"

# UI色定数
const BACKGROUND_COLOR = Color.DARK_BLUE
const TEXT_PANEL_HEIGHT = 160
const TEXT_PANEL_OFFSET_Y = -180

# フォントサイズ定数
const NAME_FONT_SIZE = 18
const TEXT_FONT_SIZE = 16
const LOG_FONT_SIZE = 14
const BUTTON_FONT_SIZE = 16

# フォールバック用テキスト
var fallback_texts = [
	"システム: MainTextSceneが開始されました。",
	"システム: マークダウンシナリオの読み込みを試行します...",
	"ソウマ: ……ここが噂の遺跡、か。",
	"ユズキ: うん。……緊張してる？",
	"ソウマ: 少しね。でも、君と一緒なら大丈夫だと思う。",
	"ユズキ: ありがとう。私も、ソウマと一緒だから安心してる。",
	"システム: テスト完了です。"
]

# 状態変数
var current_texts = []
var current_index = 0
var use_markdown = true
var scenario_texts = []

# UI要素
var background_rect: ColorRect
var text_panel: Panel
var name_label: Label
var text_label: Label
var continue_indicator: Label
var log_button: Button
var log_panel: Panel
var log_text: Label
var log_close_button: Button

# ログ機能
var text_history: Array
var max_history_entries = 100

func _ready():
	print("=== MainTextScene: 開始 ===")
	
	_initialize_scene()
	_create_ui_elements()
	_setup_signals()
	_load_initial_content()
	
	print("=== MainTextScene: 初期化完了 ===")

func _initialize_scene():
	# フルスクリーンに設定
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_texts = fallback_texts.duplicate()

func _create_ui_elements():
	_create_background()
	_create_text_panel()
	_create_ui_controls()
	_create_log_system()

func _create_background():
	background_rect = ColorRect.new()
	background_rect.color = BACKGROUND_COLOR
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)
	print("MainTextScene: 背景作成完了")

func _create_text_panel():
	text_panel = Panel.new()
	text_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_panel.position.y = TEXT_PANEL_OFFSET_Y
	text_panel.size.y = TEXT_PANEL_HEIGHT
	add_child(text_panel)
	print("MainTextScene: テキストパネル作成完了")

func _create_ui_controls():
	_create_name_label()
	_create_text_label()
	_create_continue_indicator()
	_create_log_button()

func _create_name_label():
	name_label = Label.new()
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	name_label.visible = false
	text_panel.add_child(name_label)

func _create_text_label():
	text_label = Label.new()
	text_label.position = Vector2(20, 45)
	text_label.size = Vector2(760, 80)
	text_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_panel.add_child(text_label)

func _create_continue_indicator():
	continue_indicator = Label.new()
	continue_indicator.text = CONTINUE_INDICATOR_TEXT
	continue_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_indicator.position = Vector2(-50, -30)
	continue_indicator.size = Vector2(40, 25)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_indicator.visible = true
	text_panel.add_child(continue_indicator)

func _create_log_button():
	log_button = Button.new()
	log_button.text = LOG_BUTTON_TEXT
	log_button.position = Vector2(20, 20)
	log_button.size = Vector2(100, 50)
	log_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	add_child(log_button)

func _create_log_system():
	log_panel = Panel.new()
	log_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	log_panel.size = Vector2(600, 400)
	log_panel.visible = false
	add_child(log_panel)
	
	log_text = Label.new()
	log_text.position = Vector2(10, 40)
	log_text.size = Vector2(580, 320)
	log_text.add_theme_font_size_override("font_size", LOG_FONT_SIZE)
	log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	log_panel.add_child(log_text)
	
	log_close_button = Button.new()
	log_close_button.text = CLOSE_BUTTON_TEXT
	log_close_button.position = Vector2(520, 10)
	log_close_button.size = Vector2(70, 30)
	log_panel.add_child(log_close_button)

func _setup_signals():
	if log_button and not log_button.pressed.is_connected(_on_log_button_pressed):
		log_button.pressed.connect(_on_log_button_pressed)
	
	if log_close_button and not log_close_button.pressed.is_connected(_on_log_close_button_pressed):
		log_close_button.pressed.connect(_on_log_close_button_pressed)

func _load_initial_content():
	if use_markdown:
		_try_load_markdown()
	show_current_text()

func show_current_text():
	if current_index < current_texts.size():
		var text = current_texts[current_index]
		_display_text(text)
		print("MainTextScene: テキスト表示 [%d]: %s" % [current_index, text])
	else:
		_show_completion_message()

func _display_text(text: String):
	var parts = text.split(SPEAKER_SEPARATOR, false, 1)
	if parts.size() == 2:
		# スピーカー名がある場合
		name_label.text = parts[0]
		name_label.visible = true
		text_label.text = parts[1]
		_add_to_log(parts[0], parts[1])
	else:
		# スピーカー名がない場合
		name_label.visible = false
		text_label.text = text
		_add_to_log("", text)

func _show_completion_message():
	name_label.visible = false
	text_label.text = "テスト終了: タイトルに戻るにはESCキーを押してください"
	continue_indicator.visible = false

func _try_load_markdown():
	print("MainTextScene: マークダウン読み込み試行開始")
	
	var loader_script = _load_resource_safely(SCENARIO_LOADER_PATH)
	if not loader_script:
		print("MainTextScene: ScenarioLoaderスクリプトが見つかりません")
		return
	
	var scenario_loader = _instantiate_safely(loader_script)
	if not scenario_loader:
		print("MainTextScene: ScenarioLoaderの作成に失敗")
		return
	
	var scenario_data = scenario_loader.load_scenario_file(SCENARIO_PATH)
	if not scenario_data:
		print("MainTextScene: マークダウンファイルの読み込みに失敗")
		return
	
	var converted_scenes = scenario_loader.convert_to_text_scene_data(scenario_data)
	if not converted_scenes or converted_scenes.is_empty():
		print("MainTextScene: シーンデータの変換に失敗")
		return
	
	_process_converted_scenes(converted_scenes)

func _load_resource_safely(path: String):
	if not ResourceLoader.exists(path):
		print("MainTextScene: リソースファイルが存在しません: %s" % path)
		return null
	
	var resource = ResourceLoader.load(path)
	if not resource:
		print("MainTextScene: リソースの読み込みに失敗: %s" % path)
		return null
	
	return resource

func _instantiate_safely(script_resource):
	if not script_resource:
		return null
	
	# GDScriptリソースかチェック
	if not script_resource is GDScript:
		print("MainTextScene: 指定されたリソースはGDScriptではありません")
		return null
	
	var instance = script_resource.new()
	if not instance:
		print("MainTextScene: インスタンスの作成に失敗")
		return null
	
	return instance

func _process_converted_scenes(converted_scenes: Array):
	scenario_texts.clear()
	
	for scene_data in converted_scenes:
		if not scene_data:
			continue
		
		var display_text = ""
		if scene_data.has("speaker_name") and not scene_data.speaker_name.is_empty():
			display_text = "%s%s%s" % [scene_data.speaker_name, SPEAKER_SEPARATOR, scene_data.text]
		else:
			display_text = scene_data.text
		scenario_texts.append(display_text)
	
	if scenario_texts.size() > 0:
		use_markdown = true
		current_texts = scenario_texts.duplicate()
		print("MainTextScene: マークダウンテキストを使用します - %d 行" % scenario_texts.size())

func _add_to_log(speaker_name: String, text: String):
	var log_entry = ""
	if not speaker_name.is_empty():
		log_entry = "%s%s%s" % [speaker_name, SPEAKER_SEPARATOR, text]
	else:
		log_entry = text
	
	text_history.append(log_entry)
	
	# 履歴上限チェック
	if text_history.size() > max_history_entries:
		text_history = text_history.slice(text_history.size() - max_history_entries)
	
	_update_log_display()

func _update_log_display():
	if log_text:
		log_text.text = "\n".join(text_history)

func _on_log_button_pressed():
	if log_panel:
		log_panel.visible = not log_panel.visible
		print("MainTextScene: ログパネル切り替え - visible: %s" % log_panel.visible)

func _on_log_close_button_pressed():
	if log_panel:
		log_panel.visible = false
		print("MainTextScene: ログパネル閉じる")

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_advance_text()
	elif event.is_action_pressed("ui_cancel"):
		_return_to_title()

func _advance_text():
	if current_index < current_texts.size() - 1:
		current_index += 1
		show_current_text()
	else:
		print("MainTextScene: テキスト終了")

func _return_to_title():
	print("MainTextScene: タイトル画面に戻る")
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _exit_tree():
	# リソースクリーンアップ
	_cleanup_resources()

func _cleanup_resources():
	# 子ノードの適切な削除
	if background_rect and is_instance_valid(background_rect):
		background_rect.queue_free()
	
	if text_panel and is_instance_valid(text_panel):
		text_panel.queue_free()
	
	if log_panel and is_instance_valid(log_panel):
		log_panel.queue_free()
	
	# 配列のクリア
	text_history.clear()
	scenario_texts.clear()
	current_texts.clear()