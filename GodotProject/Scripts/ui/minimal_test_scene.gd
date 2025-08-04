extends Control

# 超シンプルなテスト用スクリプト

var test_texts = [
	"システム: MinimalTestSceneが開始されました。",
	"システム: マークダウンシナリオの読み込みを試行します...",
	"ソウマ: ……ここが噂の遺跡、か。",
	"ユズキ: うん。……緊張してる？",
	"ソウマ: 少しね。でも、君と一緒なら大丈夫だと思う。",
	"ユズキ: ありがとう。私も、ソウマと一緒だから安心してる。",
	"システム: テスト完了です。"
]

var use_markdown = true
var scenario_texts = []

var current_index = 0
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

func _ready():
	print("=== MinimalTestScene: 開始 ===")
	
	# フルスクリーンに設定
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 背景作成
	background_rect = ColorRect.new()
	background_rect.color = Color.DARK_BLUE
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)
	print("MinimalTestScene: 背景作成完了")
	
	# テキストパネル作成
	text_panel = Panel.new()
	text_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_panel.position.y = -180
	text_panel.size.y = 160
	add_child(text_panel)
	print("MinimalTestScene: パネル作成完了")
	
	# 名前ラベル作成
	name_label = Label.new()
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.visible = false
	text_panel.add_child(name_label)
	print("MinimalTestScene: 名前ラベル作成完了")
	
	# テキストラベル作成
	text_label = Label.new()
	text_label.position = Vector2(20, 45)
	text_label.size = Vector2(760, 80)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_panel.add_child(text_label)
	print("MinimalTestScene: テキストラベル作成完了")
	
	# 継続インジケーター作成
	continue_indicator = Label.new()
	continue_indicator.text = "▼"
	continue_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_indicator.position = Vector2(-50, -30)  # 右下から50px左、30px上
	continue_indicator.size = Vector2(40, 25)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_indicator.visible = true
	text_panel.add_child(continue_indicator)
	print("MinimalTestScene: 継続インジケーター作成完了")
	
	# ログボタン作成
	log_button = Button.new()
	log_button.text = "ログ"
	log_button.position = Vector2(20, 20)
	log_button.size = Vector2(100, 50)
	log_button.add_theme_font_size_override("font_size", 16)
	# シグナル接続をより明示的に
	if not log_button.pressed.is_connected(_on_log_button_pressed):
		log_button.pressed.connect(_on_log_button_pressed)
	add_child(log_button)
	print("MinimalTestScene: ログボタン作成完了 - 位置: %s, サイズ: %s" % [log_button.position, log_button.size])
	
	# ログパネル作成
	log_panel = Panel.new()
	log_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	log_panel.size = Vector2(600, 400)
	log_panel.visible = false
	add_child(log_panel)
	
	# ログテキスト作成
	log_text = Label.new()
	log_text.position = Vector2(10, 40)
	log_text.size = Vector2(580, 320)
	log_text.add_theme_font_size_override("font_size", 14)
	log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	log_panel.add_child(log_text)
	
	# ログ閉じるボタン作成
	log_close_button = Button.new()
	log_close_button.text = "閉じる"
	log_close_button.position = Vector2(520, 10)
	log_close_button.size = Vector2(70, 30)
	log_close_button.pressed.connect(_on_log_close_button_pressed)
	log_panel.add_child(log_close_button)
	print("MinimalTestScene: ログパネル作成完了")
	
	# マークダウンシナリオの読み込みを試行
	_try_load_markdown()
	
	# 最初のテキストを表示
	show_current_text()
	
	print("=== MinimalTestScene: 初期化完了 ===")

func show_current_text():
	if current_index < test_texts.size():
		var text = test_texts[current_index]
		
		# スピーカー名とテキストを分離
		var parts = text.split(": ", false, 1)
		if parts.size() == 2:
			# スピーカー名がある場合
			name_label.text = parts[0]
			name_label.visible = true
			text_label.text = parts[1]
		else:
			# スピーカー名がない場合
			name_label.visible = false
			text_label.text = text
		
		# ログに追加
		_add_to_log(parts[0] if parts.size() == 2 else "", parts[1] if parts.size() == 2 else text)
		
		print("MinimalTestScene: テキスト表示 [%d]: %s" % [current_index, text])
	else:
		name_label.visible = false
		text_label.text = "テスト終了: タイトルに戻るにはESCキーを押してください"
		continue_indicator.visible = false
		print("MinimalTestScene: テスト終了")

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		if log_panel.visible:
			_close_log()
		else:
			print("MinimalTestScene: ui_accept入力検出")
			current_index += 1
			show_current_text()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if log_panel.visible:
			_close_log()
		else:
			print("MinimalTestScene: ui_cancel入力検出 - タイトルに戻る")
			GameManager.return_to_title()
		get_viewport().set_input_as_handled()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if log_panel.visible:
			_close_log()
		else:
			print("MinimalTestScene: マウスクリック検出")
			current_index += 1
			show_current_text()
		get_viewport().set_input_as_handled()

func _try_load_markdown():
	# 安全にマークダウンシナリオを読み込み# 
	print("MinimalTestScene: マークダウン読み込み試行開始")
	
	# try-catch的なエラーハンドリング
	var scenario_loader = null
	var scenario_data = null
	var converted_scenes = null
	
	# ScenarioLoaderの作成を試行
	var loader_script = load("res://Scripts/systems/scenario_loader.gd")
	if loader_script == null:
		print("MinimalTestScene: ScenarioLoaderスクリプトが見つかりません")
		return
	
	scenario_loader = loader_script.new()
	if scenario_loader == null:
		print("MinimalTestScene: ScenarioLoaderの作成に失敗")
		return
	
	# シナリオファイルの読み込みを試行
	scenario_data = scenario_loader.load_scenario_file("res://Assets/scenarios/scene01.md")
	if scenario_data == null:
		print("MinimalTestScene: マークダウンファイルの読み込みに失敗")
		return
	
	# シーンデータの変換を試行
	converted_scenes = scenario_loader.convert_to_text_scene_data(scenario_data)
	if converted_scenes == null or converted_scenes.is_empty():
		print("MinimalTestScene: シーンデータの変換に失敗")
		return
	
	# 成功した場合、マークダウンテキストを使用
	print("MinimalTestScene: マークダウン読み込み成功: %d シーン" % converted_scenes.size())
	
	scenario_texts.clear()
	for scene_data in converted_scenes:
		var display_text = ""
		if not scene_data.speaker_name.is_empty():
			display_text = scene_data.speaker_name + ": " + scene_data.text
		else:
			display_text = scene_data.text
		scenario_texts.append(display_text)
	
	# マークダウンテキストで既存のテキストを置き換え
	if scenario_texts.size() > 0:
		use_markdown = true
		test_texts = scenario_texts.duplicate()
		print("MinimalTestScene: マークダウンテキストを使用します")

func _add_to_log(speaker_name: String, text: String):
	# テキストログに追加# 
	var log_entry = {
		"speaker": speaker_name,
		"text": text,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	text_history.append(log_entry)
	
	# ログサイズ制限
	if text_history.size() > 50:
		text_history.pop_front()

func _on_log_button_pressed():
	# ログボタン押下# 
	print("MinimalTestScene: ログボタン押下")
	_show_log()

func _show_log():
	# ログパネルを表示# 
	_update_log_display()
	log_panel.visible = true

func _update_log_display():
	# ログ表示を更新# 
	var log_content = ""
	
	for entry in text_history:
		if not entry.speaker.is_empty():
			log_content += "[" + entry.speaker + "]\n"
		log_content += entry.text + "\n\n"
	
	log_text.text = log_content

func _on_log_close_button_pressed():
	# ログ閉じるボタン押下# 
	print("MinimalTestScene: ログ閉じるボタン押下")
	_close_log()

func _close_log():
	# ログパネルを閉じる# 
	log_panel.visible = false