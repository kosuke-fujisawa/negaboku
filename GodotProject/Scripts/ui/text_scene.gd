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
var _is_processing_advance: bool = false

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
	# 連続実行防止
	if _is_processing_advance:
		return
	
	_is_processing_advance = true
	
	if is_text_animating:
		# アニメーション中なら即座に完了
		_complete_text_animation()
	elif continue_indicator.visible:
		# テキスト表示完了後なら次へ
		text_finished.emit()
	
	# 次フレームで実行可能にする
	await get_tree().process_frame
	_is_processing_advance = false

func set_background(texture_path: String):
	"""背景CGを設定"""
	if texture_path.is_empty():
		background.texture = null
		background.color = Color.BLACK
		print("背景をクリア")
		return
	
	# パスの妥当性チェック
	if not texture_path.begins_with("res://") and not texture_path.begins_with("user://"):
		print("エラー: 不正な背景パス形式: %s" % texture_path)
		_set_background_fallback()
		return
	
	# ファイル存在チェック
	if not ResourceLoader.exists(texture_path):
		print("エラー: 背景ファイルが存在しません: %s" % texture_path)
		_set_background_fallback()
		return
	
	# リソース読み込み
	var texture: Texture2D = null
	var error = _safe_load_texture(texture_path)
	if error.has("texture"):
		texture = error.texture
	else:
		print("エラー: 背景の読み込みに失敗: %s - %s" % [texture_path, error.get("message", "不明なエラー")])
		_set_background_fallback()
		return
	
	# 背景設定
	background.texture = texture
	background.color = Color.WHITE
	print("背景を設定: %s" % texture_path)

func _safe_load_texture(path: String) -> Dictionary:
	"""安全なテクスチャ読み込み"""
	var result = {}
	
	# ResourceLoaderを使用した安全な読み込み
	if ResourceLoader.exists(path, "Texture2D"):
		var resource = ResourceLoader.load(path, "Texture2D")
		if resource and resource is Texture2D:
			result["texture"] = resource
		else:
			result["message"] = "テクスチャ形式が不正です"
	else:
		result["message"] = "リソースが見つかりません"
	
	return result

func _set_background_fallback():
	"""背景設定のフォールバック処理"""
	background.texture = null
	background.color = Color.BLACK
	print("フォールバック: 背景を黒色に設定")

func set_character_portrait(position: String, texture_path: String):
	"""立ち絵を設定 (position: "left" or "right")"""
	# 入力パラメータ検証
	if position.is_empty():
		print("エラー: 立ち絵位置が指定されていません")
		return
	
	var character_node: TextureRect = null
	var normalized_position = position.to_lower().strip_edges()
	
	match normalized_position:
		"left":
			character_node = character_left
		"right":
			character_node = character_right
		_:
			print("エラー: 不正な立ち絵位置: '%s' (有効値: 'left', 'right')" % position)
			return
	
	# ノードの存在確認
	if not character_node:
		print("エラー: 立ち絵ノードが見つかりません (%s)" % position)
		return
	
	# 空のパスの場合は立ち絵をクリア
	if texture_path.is_empty():
		character_node.texture = null
		character_node.visible = false
		print("立ち絵をクリア (%s)" % position)
		return
	
	# パスの妥当性チェック
	if not texture_path.begins_with("res://") and not texture_path.begins_with("user://"):
		print("エラー: 不正な立ち絵パス形式 (%s): %s" % [position, texture_path])
		_set_character_fallback(character_node, position)
		return
	
	# ファイル存在チェック
	if not ResourceLoader.exists(texture_path):
		print("エラー: 立ち絵ファイルが存在しません (%s): %s" % [position, texture_path])
		_set_character_fallback(character_node, position)
		return
	
	# リソース読み込み
	var texture: Texture2D = null
	var error = _safe_load_texture(texture_path)
	if error.has("texture"):
		texture = error.texture
	else:
		print("エラー: 立ち絵の読み込みに失敗 (%s): %s - %s" % [position, texture_path, error.get("message", "不明なエラー")])
		_set_character_fallback(character_node, position)
		return
	
	# テクスチャサイズ検証（異常に大きなテクスチャを防ぐ）
	if texture.get_width() > 2048 or texture.get_height() > 2048:
		print("警告: 立ち絵サイズが大きすぎます (%s): %dx%d" % [position, texture.get_width(), texture.get_height()])
	
	# 立ち絵設定
	character_node.texture = texture
	character_node.visible = true
	print("立ち絵を設定 (%s): %s" % [position, texture_path])

func _set_character_fallback(character_node: TextureRect, position: String):
	"""立ち絵設定のフォールバック処理"""
	if character_node:
		character_node.texture = null
		character_node.visible = false
		print("フォールバック: 立ち絵を非表示に設定 (%s)" % position)

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
	# 境界チェック
	if current_text.is_empty():
		text_label.text = ""
		return
	
	# char_countの範囲チェック
	var safe_char_count = max(0, min(char_count, current_text.length()))
	
	# substrの安全な使用
	var displayed_text = _safe_substr(current_text, 0, safe_char_count)
	text_label.text = displayed_text

func _safe_substr(source: String, start: int, length: int) -> String:
	"""安全なsubstr実装"""
	# 入力検証
	if source.is_empty():
		return ""
	
	if start < 0:
		start = 0
	
	if start >= source.length():
		return ""
	
	if length < 0:
		return ""
	
	# 境界を超えないように調整
	var end_pos = start + length
	if end_pos > source.length():
		end_pos = source.length()
	
	# 安全なsubstr呼び出し
	return source.substr(start, end_pos - start)

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