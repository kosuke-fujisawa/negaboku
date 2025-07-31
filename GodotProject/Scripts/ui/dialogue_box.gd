class_name DialogueBox
extends Control

# ダイアログボックス
# Unity版のダイアログシステムをGodot UIで再実装

signal dialogue_finished
signal next_line_requested
signal dialogue_skipped

@export var text_speed: float = 0.05  # 文字表示速度（秒）
@export var auto_advance_delay: float = 2.0  # 自動進行の待機時間
@export var enable_auto_advance: bool = false

var background_panel: Panel
var name_label: Label
var content_label: RichTextLabel
var next_button: Button
var skip_button: Button

var current_dialogue: Array[String] = []
var current_line_index: int = 0
var is_typing: bool = false
var is_waiting_for_input: bool = false
var typing_tween: Tween

func _ready():
	setup_ui()
	visible = false

func setup_ui():
	# 背景パネル
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	background_panel.size.y = 200
	background_panel.position.y = -200
	add_child(background_panel)
	
	# キャラクター名ラベル
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = ""
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 16)
	background_panel.add_child(name_label)
	
	# メインテキスト
	content_label = RichTextLabel.new()
	content_label.name = "ContentLabel"
	content_label.position = Vector2(20, 45)
	content_label.size = Vector2(760, 100)
	content_label.fit_content = true
	content_label.bbcode_enabled = true
	background_panel.add_child(content_label)
	
	# 次へボタン
	next_button = Button.new()
	next_button.name = "NextButton"
	next_button.text = "▼"
	next_button.position = Vector2(750, 150)
	next_button.size = Vector2(30, 30)
	next_button.pressed.connect(_on_next_button_pressed)
	background_panel.add_child(next_button)
	
	# スキップボタン
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip"
	skip_button.position = Vector2(680, 150)
	skip_button.size = Vector2(60, 30)
	skip_button.pressed.connect(_on_skip_button_pressed)
	background_panel.add_child(skip_button)

func _input(event: InputEvent):
	if not visible or not is_waiting_for_input:
		return
	
	# マウスボタン入力の改善（左クリックのみ有効）
	var should_advance: bool = false
	
	if event.is_action_pressed("ui_accept"):
		should_advance = true
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			should_advance = true
	
	if should_advance:
		if is_typing:
			complete_current_line()
		else:
			show_next_line()

func show_dialogue(lines: Array[String], character_name: String = ""):
	if lines.is_empty():
		return
	
	current_dialogue = lines.duplicate()
	current_line_index = 0
	
	name_label.text = character_name
	
	visible = true
	show_next_line()

func show_next_line():
	if current_line_index >= current_dialogue.size():
		finish_dialogue()
		return
	
	var line = current_dialogue[current_line_index]
	current_line_index += 1
	
	is_waiting_for_input = false
	next_line_requested.emit()
	
	# タイピング効果で表示
	start_typing_effect(line)

func start_typing_effect(text: String):
	is_typing = true
	content_label.text = ""
	next_button.visible = false
	
	if typing_tween:
		typing_tween.kill()
	
	typing_tween = create_tween()
	
	var char_count = text.length()
	var duration = char_count * text_speed
	
	# 文字を一文字ずつ表示
	for i in range(char_count + 1):
		typing_tween.tween_callback(set_partial_text.bind(text, i))
		typing_tween.tween_delay(text_speed)
	
	# タイピング完了後の処理
	typing_tween.tween_callback(complete_current_line)

func set_partial_text(full_text: String, char_count: int):
	if char_count > full_text.length():
		char_count = full_text.length()
	content_label.text = full_text.substr(0, char_count)

func complete_current_line():
	if typing_tween:
		typing_tween.kill()
	
	is_typing = false
	content_label.text = current_dialogue[current_line_index - 1]
	next_button.visible = true
	is_waiting_for_input = true
	
	# 自動進行が有効な場合
	if enable_auto_advance:
		await get_tree().create_timer(auto_advance_delay).timeout
		if is_waiting_for_input:  # まだ待機中の場合のみ進行
			show_next_line()

func finish_dialogue():
	visible = false
	current_dialogue.clear()
	current_line_index = 0
	is_waiting_for_input = false
	is_typing = false
	dialogue_finished.emit()

func skip_dialogue():
	if current_dialogue.is_empty():
		return
	
	dialogue_skipped.emit()
	finish_dialogue()

func _on_next_button_pressed():
	if is_typing:
		complete_current_line()
	else:
		show_next_line()

func _on_skip_button_pressed():
	skip_dialogue()

# アニメーション効果
func show_with_animation():
	visible = true
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_with_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

# 設定の変更
func set_text_speed(speed: float):
	text_speed = speed

func set_auto_advance(enabled: bool):
	enable_auto_advance = enabled

func set_character_name(character_name: String):
	name_label.text = character_name