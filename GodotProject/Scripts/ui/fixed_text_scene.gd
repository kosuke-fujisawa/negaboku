class_name FixedTextScene
extends Control

signal text_finished
signal choice_selected(choice_index: int)

# 最小限のノード参照（確実に存在するもののみ）
var background: Control
var text_window: Control
var name_label: Label
var text_label: Label
var continue_indicator: Control

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
	print("=== FixedTextScene: 初期化開始 ===")
	
	# 最小限のUI作成
	_create_minimal_ui()
	print("FixedTextScene: 最小限UI作成完了")
	
	# テスト表示
	_test_basic_display()
	print("FixedTextScene: テスト表示完了")
	
	# シーンマネージャー初期化
	_initialize_scene_manager()
	print("FixedTextScene: シーンマネージャー初期化完了")
	
	print("=== FixedTextScene: 初期化完了 ===")

func _create_minimal_ui():
	# 最小限のUIを作成# 
	print("FixedTextScene: 最小限UI作成開始")
	
	# フルスクリーンに設定
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 背景
	background = ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	print("FixedTextScene: 背景作成")
	
	# テキストウィンドウ
	text_window = Panel.new()
	text_window.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	text_window.position.y = -200
	text_window.size.y = 180
	add_child(text_window)
	print("FixedTextScene: テキストウィンドウ作成")
	
	# 名前ラベル
	name_label = Label.new()
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.visible = false
	text_window.add_child(name_label)
	print("FixedTextScene: 名前ラベル作成")
	
	# テキストラベル（RichTextLabelではなくLabelを使用）
	text_label = Label.new()
	text_label.position = Vector2(20, 45)
	text_label.size = Vector2(760, 100)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_window.add_child(text_label)
	print("FixedTextScene: テキストラベル作成")
	
	# 継続インジケーター
	continue_indicator = Label.new()
	continue_indicator.text = "▼"
	continue_indicator.position = Vector2(750, 150)
	continue_indicator.size = Vector2(30, 20)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_indicator.visible = false
	text_window.add_child(continue_indicator)
	print("FixedTextScene: 継続インジケーター作成")

func _test_basic_display():
	# 基本的な表示テスト# 
	print("FixedTextScene: 基本表示テスト開始")
	
	# 背景色を確認可能な色に設定
	background.color = Color.DARK_SLATE_GRAY
	print("FixedTextScene: 背景色設定")
	
	# テストテキストを表示
	show_text("システム", "FixedTextSceneが初期化されました。\nクリックまたはスペースキーで進んでください。")
	print("FixedTextScene: テストテキスト表示")

func _initialize_scene_manager():
	# シーンマネージャーを初期化# 
	print("FixedTextScene: シーンマネージャー初期化開始")
	
	scene_manager = TextSceneManager.new()
	add_child(scene_manager)
	scene_manager.initialize_with_scene(self)
	
	# マークダウンシナリオを読み込み
	print("FixedTextScene: マークダウンシナリオ読み込み開始")
	scene_manager.load_sample_markdown_scenario()
	print("FixedTextScene: マークダウンシナリオ読み込み完了")

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		print("FixedTextScene: ui_accept入力検出")
		_advance_text()
		get_viewport().set_input_as_handled()

func _advance_text():
	print("FixedTextScene: _advance_text()呼び出し")
	
	# 連続実行防止
	if _is_processing_advance:
		print("FixedTextScene: 既に処理中のためスキップ")
		return
	
	_is_processing_advance = true
	
	if is_text_animating:
		# アニメーション中なら即座に完了
		print("FixedTextScene: テキストアニメーション完了")
		_complete_text_animation()
	elif continue_indicator and continue_indicator.visible:
		# テキスト表示完了後なら次へ
		print("FixedTextScene: text_finishedシグナル発信")
		text_finished.emit()
	else:
		print("FixedTextScene: テキスト進行条件が満たされていません (is_animating=%s, continue_visible=%s)" % [is_text_animating, continue_indicator and continue_indicator.visible])
	
	# 次フレームで実行可能にする
	await get_tree().process_frame
	_is_processing_advance = false

func show_text(speaker_name: String, text: String):
	# テキストを表示# 
	print("FixedTextScene: show_text()呼び出し - スピーカー: %s, テキスト: %s" % [speaker_name, text])
	
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
	print("FixedTextScene: テキストアニメーション開始")
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
	print("FixedTextScene: テキストアニメーション完了")
	is_text_animating = false
	continue_indicator.visible = true
	print("FixedTextScene: 継続インジケーター表示")

func set_background(texture_path: String):
	# 背景CGを設定# 
	print("FixedTextScene: 背景設定 - %s" % texture_path)
	
	if texture_path.is_empty():
		background.color = Color.BLACK
	else:
		# 背景色をダークブルーに設定（画像がない場合）
		background.color = Color.DARK_BLUE

func set_character_portrait(position: String, texture_path: String):
	# 立ち絵を設定 (position: "left" or "right")# 
	print("FixedTextScene: 立ち絵設定 - %s: %s" % [position, texture_path])
	# 立ち絵は一旦無視（テキスト表示に集中）

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

func get_log_history() -> Array:
	# ログ履歴を取得# 
	return text_history.duplicate()

func clear_log():
	# ログをクリア# 
	text_history.clear()