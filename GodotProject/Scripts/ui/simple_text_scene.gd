class_name SimpleTextScene
extends Control

signal text_finished
signal choice_selected(choice_index: int)

# 動的に作成されるノード
var background: ColorRect
var character_left: TextureRect
var character_right: TextureRect
var text_window: Panel
var name_label: Label
var text_label: RichTextLabel
var continue_indicator: Label
var log_button: Button
var log_panel: Panel
var log_text: RichTextLabel
var log_close_button: Button

# テキスト表示関連
var current_text: String = ""
var text_speed: float = 0.05
var is_text_animating: bool = false
var text_tween: Tween
var _is_processing_advance: bool = false

# テキストログ
var text_history: Array
var max_log_entries: int = 100

# シーンマネージャー
var scene_manager: TextSceneManager

func _ready():
	print("=== SimpleTextScene: 初期化開始 ===")
	print("SimpleTextScene: ウィンドウサイズ: %s" % get_viewport().get_visible_rect().size)
	
	_create_ui_nodes()
	print("SimpleTextScene: UIノード作成完了")
	
	_setup_ui()
	print("SimpleTextScene: UI設定完了")
	
	_connect_signals()
	print("SimpleTextScene: シグナル接続完了")
	
	_setup_initial_state()
	print("SimpleTextScene: 初期状態設定完了")
	
	_initialize_scene_manager()
	print("SimpleTextScene: シーンマネージャー初期化完了")
	
	# テスト用に簡単なテキストを表示
	await get_tree().process_frame
	_test_display()
	
	print("=== SimpleTextScene: 初期化完了 ===")

func _create_ui_nodes():
	# UIノードを動的に作成# 
	print("SimpleTextScene: UIノード作成開始")
	
	# ルートコントロールのサイズ設定
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("SimpleTextScene: ルートサイズ設定完了: %s" % size)
	
	# 背景レイヤー
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	print("SimpleTextScene: 背景作成完了: %s" % background.size)
	
	# キャラクターレイヤー
	var character_layer = Control.new()
	character_layer.name = "CharacterLayer"
	character_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(character_layer)
	
	# 左側キャラクター
	character_left = TextureRect.new()
	character_left.name = "CharacterLeft"
	character_left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	character_left.size = Vector2(400, 600)
	character_left.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	character_left.visible = false
	character_layer.add_child(character_left)
	
	# 右側キャラクター
	character_right = TextureRect.new()
	character_right.name = "CharacterRight"
	character_right.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	character_right.size = Vector2(400, 600)
	character_right.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	character_right.visible = false
	character_layer.add_child(character_right)
	
	# UIレイヤー
	var ui_layer = Control.new()
	ui_layer.name = "UILayer"
	ui_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui_layer)
	
	# テキストウィンドウ
	text_window = Panel.new()
	text_window.name = "TextWindow"
	text_window.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_window.position.y = -200
	text_window.size.y = 180
	text_window.custom_minimum_size = Vector2(800, 180)
	ui_layer.add_child(text_window)
	print("SimpleTextScene: テキストウィンドウ作成完了: pos=%s, size=%s" % [text_window.position, text_window.size])
	
	# 名前ラベル
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = "キャラクター名"
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.visible = false
	text_window.add_child(name_label)
	
	# テキストラベル
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.position = Vector2(20, 45)
	text_label.size = Vector2(760, 100)
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.add_theme_font_size_override("normal_font_size", 16)
	text_window.add_child(text_label)
	print("SimpleTextScene: テキストラベル作成完了: pos=%s, size=%s" % [text_label.position, text_label.size])
	
	# 継続インジケーター
	continue_indicator = Label.new()
	continue_indicator.name = "ContinueIndicator"
	continue_indicator.text = "▼"
	continue_indicator.position = Vector2(750, 150)
	continue_indicator.size = Vector2(30, 20)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_indicator.visible = false
	text_window.add_child(continue_indicator)
	
	# ログボタン
	log_button = Button.new()
	log_button.name = "LogButton"
	log_button.text = "ログ"
	log_button.position = Vector2(50, 50)
	log_button.size = Vector2(80, 40)
	ui_layer.add_child(log_button)
	
	# ログパネル
	log_panel = Panel.new()
	log_panel.name = "LogPanel"
	log_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	log_panel.size = Vector2(600, 400)
	log_panel.visible = false
	ui_layer.add_child(log_panel)
	
	# ログテキスト
	log_text = RichTextLabel.new()
	log_text.name = "LogText"
	log_text.position = Vector2(10, 40)
	log_text.size = Vector2(580, 320)
	log_text.bbcode_enabled = true
	log_panel.add_child(log_text)
	
	# ログ閉じるボタン
	log_close_button = Button.new()
	log_close_button.name = "LogCloseButton"
	log_close_button.text = "閉じる"
	log_close_button.position = Vector2(520, 10)
	log_close_button.size = Vector2(70, 30)
	log_panel.add_child(log_close_button)
	
	print("SimpleTextScene: UIノード作成完了")

func _setup_ui():
	# UI設定# 
	print("SimpleTextScene: UI設定開始")
	
	# テキストウィンドウの設定
	text_window.visible = true
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	
	# 継続インジケーターの設定
	continue_indicator.visible = false
	
	# ログパネルの設定
	log_panel.visible = false
	log_text.bbcode_enabled = true
	
	print("SimpleTextScene: UI設定完了")

func _connect_signals():
	# シグナル接続# 
	print("SimpleTextScene: シグナル接続開始")
	
	# ログボタン
	log_button.pressed.connect(_on_log_button_pressed)
	log_close_button.pressed.connect(_on_log_close_button_pressed)
	
	# テキスト進行（クリック・キー入力）
	text_window.gui_input.connect(_on_text_window_input)
	
	print("SimpleTextScene: シグナル接続完了")

func _setup_initial_state():
	# 初期状態設定# 
	print("SimpleTextScene: 初期状態設定開始")
	
	# 背景をクリア
	background.color = Color.BLACK
	
	# 立ち絵をクリア
	character_left.texture = null
	character_left.visible = false
	character_right.texture = null
	character_right.visible = false
	
	# テキストをクリア
	clear_text()
	
	print("SimpleTextScene: 初期状態設定完了")

func _initialize_scene_manager():
	# シーンマネージャーを初期化# 
	print("SimpleTextScene: シーンマネージャー初期化開始")
	
	# 一時的にシーンマネージャーなしでテスト
	print("SimpleTextScene: シーンマネージャー初期化をスキップ（テスト中）")
	
	# scene_manager = TextSceneManager.new()
	# add_child(scene_manager)
	# scene_manager.initialize_with_scene(self)
	
	# 新規ゲーム開始時はマークダウンサンプルシナリオを読み込み
	# print("SimpleTextScene: マークダウンシナリオを読み込み")
	# scene_manager.load_sample_markdown_scenario()
	
	print("SimpleTextScene: シーンマネージャー初期化完了")

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		_advance_text()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if log_panel.visible:
			_close_log()
			get_viewport().set_input_as_handled()

func _on_text_window_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_text()
		get_viewport().set_input_as_handled()

func _advance_text():
	print("SimpleTextScene: _advance_text()呼び出し")
	
	# 連続実行防止
	if _is_processing_advance:
		print("SimpleTextScene: 既に処理中のためスキップ")
		return
	
	_is_processing_advance = true
	
	if is_text_animating:
		# アニメーション中なら即座に完了
		print("SimpleTextScene: テキストアニメーション完了")
		_complete_text_animation()
	elif continue_indicator.visible:
		# テキスト表示完了後なら次へ
		print("SimpleTextScene: text_finishedシグナル発信")
		text_finished.emit()
	else:
		print("SimpleTextScene: テキスト進行条件が満たされていません (is_animating=%s, continue_visible=%s)" % [is_text_animating, continue_indicator.visible])
	
	# 次フレームで実行可能にする
	await get_tree().process_frame
	_is_processing_advance = false

func set_background(texture_path: String):
	# 背景CGを設定# 
	print("SimpleTextScene: 背景設定 - %s" % texture_path)
	
	if texture_path.is_empty():
		background.color = Color.BLACK
		return
	
	# 背景色をダークグレーに設定（画像がない場合）
	background.color = Color(0.2, 0.2, 0.2, 1.0)

func set_character_portrait(position: String, texture_path: String):
	# 立ち絵を設定 (position: "left" or "right")# 
	print("SimpleTextScene: 立ち絵設定 - %s: %s" % [position, texture_path])
	
	var character_node: TextureRect = null
	match position.to_lower():
		"left":
			character_node = character_left
		"right":
			character_node = character_right
		_:
			print("エラー: 不正な立ち絵位置: %s" % position)
			return
	
	if texture_path.is_empty():
		character_node.texture = null
		character_node.visible = false
	else:
		# 立ち絵を表示状態にする（画像がない場合でも）
		character_node.visible = true

func show_text(speaker_name: String, text: String):
	# テキストを表示# 
	print("SimpleTextScene: show_text()呼び出し - スピーカー: %s, テキスト: %s" % [speaker_name, text])
	
	# 名前ラベルの設定
	if speaker_name.is_empty():
		name_label.text = ""
		name_label.visible = false
	else:
		name_label.text = speaker_name
		name_label.visible = true
	
	# テキストログに追加
	_add_to_log(speaker_name, text)
	
	# テキストアニメーション開始
	current_text = text
	is_text_animating = true
	continue_indicator.visible = false
	
	_start_text_animation()

func _start_text_animation():
	# テキストのタイピングアニメーション開始# 
	print("SimpleTextScene: テキストアニメーション開始")
	text_label.text = ""
	
	if text_tween:
		text_tween.kill()
	
	text_tween = create_tween()
	text_tween.tween_method(_update_text_display, 0, current_text.length(), current_text.length() * text_speed)
	text_tween.tween_callback(_on_text_animation_complete)

func _update_text_display(char_count: int):
	# テキスト表示の更新# 
	if current_text.is_empty():
		text_label.text = ""
		return
	
	var safe_char_count = max(0, min(char_count, current_text.length()))
	var displayed_text = current_text.substr(0, safe_char_count)
	text_label.text = displayed_text

func _complete_text_animation():
	# テキストアニメーションを即座に完了# 
	if text_tween:
		text_tween.kill()
	
	text_label.text = current_text
	_on_text_animation_complete()

func _on_text_animation_complete():
	# テキストアニメーション完了# 
	print("SimpleTextScene: テキストアニメーション完了")
	is_text_animating = false
	continue_indicator.visible = true
	print("SimpleTextScene: 継続インジケーター表示")

func clear_text():
	# テキスト表示をクリア# 
	name_label.text = ""
	name_label.visible = false
	text_label.text = ""
	continue_indicator.visible = false
	
	if text_tween:
		text_tween.kill()
	
	is_text_animating = false

func _add_to_log(speaker_name: String, text: String):
	# テキストログに追加# 
	var log_entry = {
		"speaker": speaker_name,
		"text": text,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	text_history.append(log_entry)
	
	# ログサイズ制限
	if text_history.size() > max_log_entries:
		text_history.pop_front()

func _on_log_button_pressed():
	# ログボタン押下# 
	print("SimpleTextScene: ログボタン押下")
	_show_log()

func _show_log():
	# ログパネルを表示# 
	print("SimpleTextScene: ログパネル表示")
	_update_log_display()
	log_panel.visible = true

func _update_log_display():
	# ログ表示を更新# 
	var log_content = ""
	
	for entry in text_history:
		if not entry.speaker.is_empty():
			log_content += "[color=yellow]%s[/color]\n" % entry.speaker
		log_content += "%s\n\n" % entry.text
	
	log_text.text = log_content

func _on_log_close_button_pressed():
	# ログ閉じるボタン押下# 
	print("SimpleTextScene: ログ閉じるボタン押下")
	_close_log()

func _close_log():
	# ログパネルを閉じる# 
	print("SimpleTextScene: ログパネルを閉じる")
	log_panel.visible = false

func get_log_history() -> Array:
	# ログ履歴を取得# 
	return text_history.duplicate()

func clear_log():
	# ログをクリア# 
	text_history.clear()
	_update_log_display()

func _test_display():
	# テスト用の表示# 
	print("SimpleTextScene: テスト表示開始")
	
	# UIノードが正しく作成されているか確認
	print("SimpleTextScene: background存在: %s" % (background != null))
	print("SimpleTextScene: text_window存在: %s" % (text_window != null))
	print("SimpleTextScene: text_label存在: %s" % (text_label != null))
	print("SimpleTextScene: name_label存在: %s" % (name_label != null))
	
	if text_window and text_label and name_label:
		print("SimpleTextScene: テストテキスト表示")
		show_text("システム", "SimpleTextSceneが正常に初期化されました。クリックして進んでください。")
	else:
		print("SimpleTextScene: エラー - UIノードが正しく作成されていません")