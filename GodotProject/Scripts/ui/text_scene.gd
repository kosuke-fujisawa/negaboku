class_name TextScene
extends Control

signal text_finished
signal choice_selected(choice_index: int)

# ノード参照
@onready var background: TextureRect = $BackgroundLayer/Background
@onready var character_left: TextureRect = $CharacterLayer/CharacterLeft
@onready var character_right: TextureRect = $CharacterLayer/CharacterRight
@onready var text_window: Control = $UILayer/TextWindow
@onready var name_label: Label = $UILayer/TextWindow/NameContainer/NameLabel
@onready var text_label: RichTextLabel = $UILayer/TextWindow/TextContainer/TextLabel
@onready var continue_indicator: Control = $UILayer/TextWindow/ContinueIndicator
@onready var log_button: Button = $UILayer/LogButton
@onready var log_panel: Control = $UILayer/LogPanel
@onready var log_text: RichTextLabel = $UILayer/LogPanel/LogContainer/LogText
@onready var log_close_button: Button = $UILayer/LogPanel/LogContainer/CloseButton

# テキスト表示関連
var current_text: String = ""
var current_character_index: int = 0
var text_speed: float = 0.05
var is_text_animating: bool = false
var text_tween: Tween

# テキストログ
var text_history: Array[Dictionary] = []
var max_log_entries: int = 100

# 立ち絵管理
var character_portraits: Dictionary = {}

# シーンマネージャー
var scene_manager: TextSceneManager

func _ready():
	_setup_ui()
	_connect_signals()
	_setup_initial_state()
	_initialize_scene_manager()

func _initialize_scene_manager():
	"""シーンマネージャーを初期化"""
	scene_manager = TextSceneManager.new()
	add_child(scene_manager)
	scene_manager.initialize_with_scene(self)

func _setup_ui():
	# テキストウィンドウの設定
	text_window.visible = true
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	
	# 継続インジケーターの設定
	continue_indicator.visible = false
	
	# ログパネルの設定
	log_panel.visible = false
	log_text.bbcode_enabled = true

func _connect_signals():
	# ログボタン
	log_button.pressed.connect(_on_log_button_pressed)
	log_close_button.pressed.connect(_on_log_close_button_pressed)
	
	# テキスト進行（クリック・キー入力）
	text_window.gui_input.connect(_on_text_window_input)

func _setup_initial_state():
	# 背景をクリア
	background.texture = null
	background.color = Color.BLACK
	
	# 立ち絵をクリア
	character_left.texture = null
	character_left.visible = false
	character_right.texture = null
	character_right.visible = false
	
	# テキストをクリア
	clear_text()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_advance_text()
	elif event.is_action_pressed("ui_cancel"):
		if log_panel.visible:
			_close_log()

func _on_text_window_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_text()

func _advance_text():
	if is_text_animating:
		# アニメーション中なら即座に完了
		_complete_text_animation()
	elif continue_indicator.visible:
		# テキスト表示完了後なら次へ
		text_finished.emit()

func set_background(texture_path: String):
	"""背景CGを設定"""
	if texture_path.is_empty():
		background.texture = null
		background.color = Color.BLACK
		return
	
	var texture = load(texture_path) as Texture2D
	if texture:
		background.texture = texture
		background.color = Color.WHITE
		print("背景を設定: %s" % texture_path)
	else:
		print("背景の読み込みに失敗: %s" % texture_path)

func set_character_portrait(position: String, texture_path: String):
	"""立ち絵を設定 (position: "left" or "right")"""
	var character_node: TextureRect
	
	match position.to_lower():
		"left":
			character_node = character_left
		"right":
			character_node = character_right
		_:
			print("不正な立ち絵位置: %s" % position)
			return
	
	if texture_path.is_empty():
		character_node.texture = null
		character_node.visible = false
		return
	
	var texture = load(texture_path) as Texture2D
	if texture:
		character_node.texture = texture
		character_node.visible = true
		print("立ち絵を設定 (%s): %s" % [position, texture_path])
	else:
		print("立ち絵の読み込みに失敗 (%s): %s" % [position, texture_path])

func show_text(speaker_name: String, text: String):
	"""テキストを表示"""
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
	current_character_index = 0
	is_text_animating = true
	continue_indicator.visible = false
	
	_start_text_animation()

func _start_text_animation():
	"""テキストのタイピングアニメーション開始"""
	text_label.text = ""
	
	if text_tween:
		text_tween.kill()
	
	text_tween = create_tween()
	text_tween.tween_method(_update_text_display, 0, current_text.length(), current_text.length() * text_speed)
	text_tween.tween_callback(_on_text_animation_complete)

func _update_text_display(char_count: int):
	"""テキスト表示の更新"""
	var displayed_text = current_text.substr(0, char_count)
	text_label.text = displayed_text

func _complete_text_animation():
	"""テキストアニメーションを即座に完了"""
	if text_tween:
		text_tween.kill()
	
	text_label.text = current_text
	_on_text_animation_complete()

func _on_text_animation_complete():
	"""テキストアニメーション完了"""
	is_text_animating = false
	continue_indicator.visible = true

func clear_text():
	"""テキスト表示をクリア"""
	name_label.text = ""
	name_label.visible = false
	text_label.text = ""
	continue_indicator.visible = false
	
	if text_tween:
		text_tween.kill()
	
	is_text_animating = false

func _add_to_log(speaker_name: String, text: String):
	"""テキストログに追加"""
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
	"""ログボタン押下"""
	_show_log()

func _show_log():
	"""ログパネルを表示"""
	_update_log_display()
	log_panel.visible = true

func _update_log_display():
	"""ログ表示を更新"""
	var log_content = ""
	
	for entry in text_history:
		if not entry.speaker.is_empty():
			log_content += "[color=yellow]%s[/color]\n" % entry.speaker
		log_content += "%s\n\n" % entry.text
	
	log_text.text = log_content

func _on_log_close_button_pressed():
	"""ログ閉じるボタン押下"""
	_close_log()

func _close_log():
	"""ログパネルを閉じる"""
	log_panel.visible = false

func get_log_history() -> Array[Dictionary]:
	"""ログ履歴を取得"""
	return text_history.duplicate()

func clear_log():
	"""ログをクリア"""
	text_history.clear()
	_update_log_display()