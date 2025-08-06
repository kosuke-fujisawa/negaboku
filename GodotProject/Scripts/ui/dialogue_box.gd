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
var log_button: Button

var current_dialogue: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var is_waiting_for_input: bool = false
var typing_tween: Tween

# テキストログ機能
var dialogue_log: Array = []  # {"character": String, "text": String}
var log_overlay: Control
var log_panel: Panel
var log_scroll: ScrollContainer
var log_content: VBoxContainer
var is_log_visible: bool = false


func _ready():
	print("DialogueBox: _ready開始")
	setup_ui()
	visible = false
	print("DialogueBox: _ready完了 - ログボタン存在: %s" % str(log_button != null))
	if log_button:
		print(
			(
				"DialogueBox: ログボタンの詳細 - 可視: %s, 有効: %s, 親: %s"
				% [
					str(log_button.visible),
					str(not log_button.disabled),
					str(log_button.get_parent().name if log_button.get_parent() else "なし")
				]
			)
		)


func setup_ui() -> void:
	# 背景パネル
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	background_panel.size.y = 200
	background_panel.position.y = -200
	# パネルの幅を画面幅に合わせる
	background_panel.size.x = 1024  # 画面幅を想定
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
	next_button.position = Vector2(860, 150)
	next_button.size = Vector2(30, 30)
	next_button.pressed.connect(_on_next_button_pressed)
	background_panel.add_child(next_button)

	# ログボタン
	log_button = Button.new()
	log_button.name = "LogButton"
	log_button.text = "Log"
	log_button.position = Vector2(720, 150)
	log_button.size = Vector2(60, 30)
	log_button.visible = true  # 明示的に可視化
	log_button.disabled = false  # 明示的に有効化
	log_button.pressed.connect(_on_log_button_pressed)
	background_panel.add_child(log_button)

	# スキップボタン
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip"
	skip_button.position = Vector2(790, 150)
	skip_button.size = Vector2(60, 30)
	skip_button.pressed.connect(_on_skip_button_pressed)
	background_panel.add_child(skip_button)
	print(
		(
			"DialogueBox: ログボタンを作成しました - 位置: %s, サイズ: %s"
			% [str(log_button.position), str(log_button.size)]
		)
	)

	# ログウィンドウの初期化
	print("DialogueBox: ログウィンドウをセットアップします")
	setup_log_window()
	print("DialogueBox: ログウィンドウのセットアップ完了")


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


func show_dialogue(lines: Array, character_name: String = "") -> void:
	if lines.is_empty():
		return

	current_dialogue = lines.duplicate()
	current_line_index = 0

	name_label.text = character_name

	visible = true
	show_next_line()


func show_next_line() -> void:
	if current_line_index >= current_dialogue.size():
		finish_dialogue()
		return

	var line = current_dialogue[current_line_index]
	current_line_index += 1

	# ログに追加
	add_to_log(name_label.text, line)

	is_waiting_for_input = false
	next_line_requested.emit()

	# タイピング効果で表示
	start_typing_effect(line)


func start_typing_effect(text: String) -> void:
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


func set_partial_text(full_text: String, char_count: int) -> void:
	# 安全な境界チェック
	if full_text.is_empty():
		content_label.text = ""
		return

	var safe_char_count = max(0, min(char_count, full_text.length()))
	content_label.text = _safe_substr(full_text, 0, safe_char_count)


func _safe_substr(source: String, start: int, length: int) -> String:
	# 安全なsubstr実装#
	if source.is_empty():
		return ""

	if start < 0:
		start = 0

	if start >= source.length():
		return ""

	if length < 0:
		return ""

	var end_pos = start + length
	if end_pos > source.length():
		end_pos = source.length()

	return source.substr(start, end_pos - start)


func complete_current_line() -> void:
	if typing_tween and typing_tween.is_valid():
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


func finish_dialogue() -> void:
	visible = false
	current_dialogue.clear()
	current_line_index = 0
	is_waiting_for_input = false
	is_typing = false
	dialogue_finished.emit()


func skip_dialogue() -> void:
	if current_dialogue.is_empty():
		return

	dialogue_skipped.emit()
	finish_dialogue()


func _on_next_button_pressed() -> void:
	if is_typing:
		complete_current_line()
	else:
		show_next_line()


func _on_skip_button_pressed() -> void:
	skip_dialogue()


# アニメーション効果
func show_with_animation() -> void:
	visible = true
	modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_with_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)


# 設定の変更
func set_text_speed(speed: float) -> void:
	text_speed = speed


func set_auto_advance(enabled: bool) -> void:
	enable_auto_advance = enabled


func set_character_name(character_name: String) -> void:
	name_label.text = character_name


# ログウィンドウのセットアップ
func setup_log_window() -> void:
	# オーバーレイ（全画面を覆う透明な背景）
	log_overlay = Control.new()
	log_overlay.name = "LogOverlay"
	log_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	log_overlay.visible = false
	log_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # クリックを止める
	log_overlay.z_index = 100  # 最前面に表示

	# 半透明背景
	var overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_bg.color = Color(0, 0, 0, 0.7)  # 半透明黒
	log_overlay.add_child(overlay_bg)

	# ログパネル（中央に配置）
	log_panel = Panel.new()
	log_panel.name = "LogPanel"
	log_panel.size = Vector2(600, 400)
	log_panel.position = Vector2(200, 100)  # 画面中央付近
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

	# ログ内容のコンテナ
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

	# オーバーレイをメインUIに追加
	add_child(log_overlay)


# ログに追加
func add_to_log(character_name: String, text: String) -> void:
	var log_entry = {"character": character_name, "text": text}
	dialogue_log.append(log_entry)
	print("DialogueBox: ログに追加 - %s: %s" % [character_name, text])

	# ログウィンドウが表示されている場合は更新
	if is_log_visible:
		refresh_log_display()


# ログ表示の更新
func refresh_log_display() -> void:
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
		if entry.character != "":
			display_text = "[b]%s[/b]: %s" % [entry.character, entry.text]
		else:
			display_text = entry.text

		log_label.text = display_text
		log_label.custom_minimum_size.y = 40
		log_content.add_child(log_label)


# ログボタンが押された時の処理
func _on_log_button_pressed() -> void:
	print("DialogueBox: ログボタンが押されました")
	print("DialogueBox: ログエントリ数: %d" % dialogue_log.size())
	print("DialogueBox: ログオーバーレイ存在: %s" % str(log_overlay != null))
	toggle_log_window()


# ログウィンドウの表示切り替え
func toggle_log_window() -> void:
	if is_log_visible:
		hide_log_window()
	else:
		show_log_window()


# ログウィンドウを表示
func show_log_window() -> void:
	if not log_overlay:
		print("DialogueBox: エラー - log_overlayが存在しません")
		return

	print("DialogueBox: ログウィンドウを表示します")
	is_log_visible = true
	refresh_log_display()
	log_overlay.visible = true


# ログウィンドウを非表示
func hide_log_window() -> void:
	if not log_overlay:
		print("DialogueBox: エラー - log_overlayが存在しません")
		return

	print("DialogueBox: ログウィンドウを非表示にします")
	is_log_visible = false
	log_overlay.visible = false


# ログウィンドウの閉じるボタンが押された時の処理
func _on_log_close_button_pressed() -> void:
	hide_log_window()


# ログをクリア
func clear_log() -> void:
	dialogue_log.clear()
	if is_log_visible:
		refresh_log_display()
