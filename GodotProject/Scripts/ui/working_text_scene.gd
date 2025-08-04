extends Control

# 動作確認済みのテキストシーン + マークダウン統合版

signal text_finished

var test_texts = [
	"ソウマ: ……ここが噂の遺跡、か。",
	"ユズキ: うん。……緊張してる？",
	"ソウマ: 少しね。でも、君と一緒なら大丈夫だと思う。",
	"ユズキ: ありがとう。私も、ソウマと一緒だから安心してる。",
	"ソウマ: さあ、行こうか。遺跡の入り口が見えてきた。"
]

var current_index = 0
var background_rect: ColorRect
var text_panel: Panel
var name_label: Label
var text_label: Label
var continue_indicator: Label
var log_button: Button

# ログ機能
var dialogue_log: Array
var log_overlay: Control
var log_panel: Panel
var log_scroll: ScrollContainer
var log_content: VBoxContainer
var is_log_visible: bool = false

# マークダウン関連
var scenario_loader: ScenarioLoader
var converted_scenes: Array = []
var scene_index = 0

func _ready():
	print("=== WorkingTextScene: 開始 ===")

	# フルスクリーンに設定
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# UI作成
	_create_ui()

	# マークダウンシナリオを読み込み
	_load_markdown_scenario()

	print("=== WorkingTextScene: 初期化完了 ===")

func _create_ui():
	# 背景作成
	background_rect = ColorRect.new()
	background_rect.color = Color.DARK_SLATE_GRAY
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)
	print("WorkingTextScene: 背景作成完了")

	# テキストパネル作成
	text_panel = Panel.new()
	text_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_panel.position.y = -180
	text_panel.size.y = 160
	add_child(text_panel)
	print("WorkingTextScene: パネル作成完了")

	# 名前ラベル作成
	name_label = Label.new()
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.visible = false
	text_panel.add_child(name_label)
	print("WorkingTextScene: 名前ラベル作成完了")

	# テキストラベル作成
	text_label = Label.new()
	text_label.position = Vector2(20, 45)
	text_label.size = Vector2(760, 80)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_panel.add_child(text_label)
	print("WorkingTextScene: テキストラベル作成完了")

	# 継続インジケーター作成
	continue_indicator = Label.new()
	continue_indicator.text = "▼"
	continue_indicator.position = Vector2(750, 130)
	continue_indicator.size = Vector2(30, 20)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_indicator.visible = true
	text_panel.add_child(continue_indicator)
	print("WorkingTextScene: 継続インジケーター作成完了")

	# ログボタン作成
	log_button = Button.new()
	log_button.text = "ログ"
	log_button.position = Vector2(650, 130)
	log_button.size = Vector2(80, 25)
	log_button.pressed.connect(_on_log_button_pressed)
	text_panel.add_child(log_button)
	print("WorkingTextScene: ログボタン作成完了")

	# ログオーバーレイ作成
	_create_log_overlay()
	print("WorkingTextScene: ログオーバーレイ作成完了")

func _load_markdown_scenario():
	print("WorkingTextScene: Phase2マークダウンシナリオ読み込み開始")

	scenario_loader = ScenarioLoader.new()
	var scenario_data = scenario_loader.load_scenario_file("res://Assets/scenarios/phase2_test.md")

	if scenario_data == null:
		print("WorkingTextScene: マークダウン読み込み失敗 - デフォルトテキストを使用")
		_show_current_scene()
		return

	# ScenarioDataをテキスト配列に変換
	converted_scenes = scenario_loader.convert_to_text_scene_data(scenario_data)

	if converted_scenes.is_empty():
		print("WorkingTextScene: シーンデータ変換失敗 - デフォルトテキストを使用")
		_show_current_scene()
		return

	print("WorkingTextScene: Phase2マークダウンシナリオ読み込み成功: %d シーン" % converted_scenes.size())
	scene_index = 0
	_show_markdown_scene_with_commands()

func _show_current_scene():
	# デフォルトテキストを表示
	if current_index < test_texts.size():
		var full_text = test_texts[current_index]
		var parts = full_text.split(": ", false, 1)

		if parts.size() == 2:
			name_label.text = parts[0]
			name_label.visible = true
			text_label.text = parts[1]
			# ログに追加
			_add_to_log(parts[0], parts[1])
		else:
			name_label.visible = false
			text_label.text = full_text
			# ログに追加
			_add_to_log("", full_text)

		print("WorkingTextScene: デフォルトテキスト表示 [%d]: %s" % [current_index, full_text])
	else:
		name_label.visible = false
		text_label.text = "テスト終了: ESCキーでタイトルに戻ります"
		continue_indicator.visible = false
		print("WorkingTextScene: デフォルトテスト終了")

func _show_markdown_scene():
	# マークダウンシーンを表示（従来版）
	if scene_index < converted_scenes.size():
		var scene_data = converted_scenes[scene_index]

		# スピーカー名設定
		if scene_data.speaker_name.is_empty():
			name_label.visible = false
		else:
			name_label.text = scene_data.speaker_name
			name_label.visible = true

		# テキスト設定
		text_label.text = scene_data.text

		# ログに追加
		_add_to_log(scene_data.speaker_name, scene_data.text)

		print("WorkingTextScene: マークダウンシーン表示 [%d]: %s「%s」" % [scene_index, scene_data.speaker_name, scene_data.text])
	else:
		name_label.visible = false
		text_label.text = "シナリオ終了: ESCキーでタイトルに戻ります"
		continue_indicator.visible = false
		print("WorkingTextScene: マークダウンシナリオ終了")

func _show_markdown_scene_with_commands():
	# マークダウンシーンをコマンド実行付きで表示（Phase2版）
	if scene_index < converted_scenes.size():
		var scene_data = converted_scenes[scene_index]

		# 背景コマンド処理
		if not scene_data.background_path.is_empty():
			_execute_background_command(scene_data.background_path)

		# キャラクター表示コマンド処理
		_execute_character_commands(scene_data)

		# スピーカー名設定
		if scene_data.speaker_name.is_empty():
			name_label.visible = false
		else:
			name_label.text = scene_data.speaker_name
			name_label.visible = true

		# テキスト設定
		text_label.text = scene_data.text

		# ログに追加
		_add_to_log(scene_data.speaker_name, scene_data.text)

		print("WorkingTextScene: Phase2シーン表示 [%d]: %s「%s」" % [scene_index, scene_data.speaker_name, scene_data.text])
		print("  背景: %s, 左: %s, 右: %s" % [scene_data.background_path, scene_data.character_left_path, scene_data.character_right_path])
	else:
		name_label.visible = false
		text_label.text = "Phase2テスト終了: ESCキーでタイトルに戻ります"
		continue_indicator.visible = false
		print("WorkingTextScene: Phase2マークダウンシナリオ終了")

func _execute_background_command(background_path: String):
	# 背景コマンドを実行
	if background_path.is_empty():
		return

	print("WorkingTextScene: 背景変更コマンド実行 - %s" % background_path)

	# 背景画像のファイル名から色を決定（プレースホルダー実装）
	var bg_color = Color.DARK_SLATE_GRAY
	if "forest" in background_path:
		bg_color = Color.DARK_GREEN
	elif "ruins" in background_path:
		bg_color = Color.DARK_GRAY
	elif "interior" in background_path:
		bg_color = Color.DIM_GRAY

	background_rect.color = bg_color
	print("WorkingTextScene: 背景色変更完了 - %s" % bg_color)

func _execute_character_commands(scene_data):
	# キャラクター表示コマンドを実行
	# 左キャラクター
	if not scene_data.character_left_path.is_empty():
		var char_name = _extract_character_name(scene_data.character_left_path)
		print("WorkingTextScene: 左キャラクター表示 - %s" % char_name)
		name_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)

	# 右キャラクター
	if not scene_data.character_right_path.is_empty():
		var char_name = _extract_character_name(scene_data.character_right_path)
		print("WorkingTextScene: 右キャラクター表示 - %s" % char_name)
		name_label.add_theme_color_override("font_color", Color.LIGHT_PINK)

func _extract_character_name(path: String) -> String:
	# パスからキャラクター名を抽出
	if path.is_empty():
		return ""

	var file_name = path.get_file().get_basename()
	var parts = file_name.split("_")
	return parts[0] if parts.size() > 0 else "unknown"

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		print("WorkingTextScene: ui_accept入力検出")
		_advance_text()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		print("WorkingTextScene: ui_cancel入力検出 - タイトルに戻る")
		GameManager.return_to_title()
		get_viewport().set_input_as_handled()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("WorkingTextScene: マウスクリック検出")
		_advance_text()
		get_viewport().set_input_as_handled()

func _advance_text():
	if converted_scenes.size() > 0:
		# マークダウンシナリオを使用（Phase2版）
		scene_index += 1
		_show_markdown_scene_with_commands()
	else:
		# デフォルトテキストを使用
		current_index += 1
		_show_current_scene()

# TextSceneManagerとの互換性のため
func show_text(speaker_name: String, text: String):
	# 外部からのテキスト表示要求
	print("WorkingTextScene: 外部テキスト表示要求 - %s: %s" % [speaker_name, text])

	if speaker_name.is_empty():
		name_label.visible = false
	else:
		name_label.text = speaker_name
		name_label.visible = true

	text_label.text = text

	# ログに追加
	_add_to_log(speaker_name, text)

func set_background(texture_path: String):
	# 背景設定（互換性のため）
	print("WorkingTextScene: 背景設定要求 - %s" % texture_path)
	if texture_path.is_empty():
		background_rect.color = Color.DARK_SLATE_GRAY
	else:
		background_rect.color = Color.DARK_BLUE

func set_character_portrait(position: String, texture_path: String):
	# 立ち絵設定（互換性のため）
	print("WorkingTextScene: 立ち絵設定要求 - %s: %s" % [position, texture_path])

func get_log_history() -> Array:
	# ログ履歴取得（互換性のため）
	return dialogue_log

# ログ機能実装

func _create_log_overlay():
	# ログオーバーレイの作成
	log_overlay = Control.new()
	log_overlay.name = "LogOverlay"
	log_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	log_overlay.visible = false
	log_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	log_overlay.z_index = 100

	# 半透明背景
	var overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_bg.color = Color(0, 0, 0, 0.7)
	log_overlay.add_child(overlay_bg)

	# ログパネル
	log_panel = Panel.new()
	log_panel.name = "LogPanel"
	log_panel.size = Vector2(600, 400)
	log_panel.position = Vector2(200, 100)
	log_overlay.add_child(log_panel)

	# タイトルラベル
	var title_label = Label.new()
	title_label.text = "会話ログ"
	title_label.position = Vector2(20, 10)
	title_label.size = Vector2(200, 30)
	title_label.add_theme_font_size_override("font_size", 18)
	log_panel.add_child(title_label)

	# スクロールコンテナ
	log_scroll = ScrollContainer.new()
	log_scroll.position = Vector2(20, 50)
	log_scroll.size = Vector2(560, 320)
	log_panel.add_child(log_scroll)

	# ログ内容コンテナ
	log_content = VBoxContainer.new()
	log_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.add_child(log_content)

	# 閉じるボタン
	var close_button = Button.new()
	close_button.text = "閉じる"
	close_button.position = Vector2(520, 10)
	close_button.size = Vector2(70, 30)
	close_button.pressed.connect(_on_log_close_button_pressed)
	log_panel.add_child(close_button)

	add_child(log_overlay)

func _on_log_button_pressed():
	# ログボタンが押された時の処理
	print("WorkingTextScene: ログボタンが押されました")
	print("WorkingTextScene: ログエントリ数: %d" % dialogue_log.size())
	_toggle_log_window()

func _toggle_log_window():
	# ログウィンドウの表示切り替え
	if is_log_visible:
		_hide_log_window()
	else:
		_show_log_window()

func _show_log_window():
	# ログウィンドウを表示
	if not log_overlay:
		print("WorkingTextScene: エラー - log_overlayが存在しません")
		return

	print("WorkingTextScene: ログウィンドウを表示します")
	is_log_visible = true
	_refresh_log_display()
	log_overlay.visible = true

func _hide_log_window():
	# ログウィンドウを非表示
	if not log_overlay:
		print("WorkingTextScene: エラー - log_overlayが存在しません")
		return

	print("WorkingTextScene: ログウィンドウを非表示にします")
	is_log_visible = false
	log_overlay.visible = false

func _on_log_close_button_pressed():
	# ログ閉じるボタンが押された時の処理
	_hide_log_window()

func _add_to_log(speaker_name: String, text: String):
	# ログに追加
	var log_entry = {
		"speaker": speaker_name,
		"text": text
	}
	dialogue_log.append(log_entry)
	print("WorkingTextScene: ログに追加 - %s: %s" % [speaker_name, text])

func _refresh_log_display():
	# ログ表示の更新
	if not log_content:
		return

	# 既存の子要素をクリア
	for child in log_content.get_children():
		child.queue_free()

	# ログエントリを表示
	for entry in dialogue_log:
		var log_label = RichTextLabel.new()
		log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		log_label.fit_content = true
		log_label.bbcode_enabled = true

		var display_text = ""
		if entry.speaker != "":
			display_text = "[b]%s[/b]: %s" % [entry.speaker, entry.text]
		else:
			display_text = entry.text

		log_label.text = display_text
		log_label.custom_minimum_size.y = 40
		log_content.add_child(log_label)