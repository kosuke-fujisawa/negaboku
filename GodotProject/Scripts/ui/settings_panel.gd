class_name SettingsPanel
extends Control

signal settings_closed

# UI要素への参照
@onready var master_volume_slider: HSlider = $SettingsDialog/VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $SettingsDialog/VBoxContainer/MasterVolumeContainer/MasterVolumeValue
@onready var bgm_volume_slider: HSlider = $SettingsDialog/VBoxContainer/BGMVolumeContainer/BGMVolumeSlider
@onready var bgm_volume_value: Label = $SettingsDialog/VBoxContainer/BGMVolumeContainer/BGMVolumeValue
@onready var sfx_volume_slider: HSlider = $SettingsDialog/VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_value: Label = $SettingsDialog/VBoxContainer/SFXVolumeContainer/SFXVolumeValue
@onready var fullscreen_check: CheckBox = $SettingsDialog/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var resolution_option: OptionButton = $SettingsDialog/VBoxContainer/ResolutionContainer/ResolutionOption
@onready var defaults_button: Button = $SettingsDialog/VBoxContainer/ButtonContainer/DefaultsButton
@onready var apply_button: Button = $SettingsDialog/VBoxContainer/ButtonContainer/ApplyButton
@onready var close_button: Button = $SettingsDialog/VBoxContainer/ButtonContainer/CloseButton

# 設定データ
var settings_manager: SettingsManager
var tween: Tween

# 一時保存用の設定値
var temp_settings: Dictionary = {}
var original_settings: Dictionary = {}

# 背景UI管理
var hidden_ui_nodes: Array[Node] = []

# 解像度オプション
var resolution_options = [
	{"name": "1280x720", "size": Vector2i(1280, 720)},
	{"name": "1600x900", "size": Vector2i(1600, 900)},
	{"name": "1920x1080", "size": Vector2i(1920, 1080)},
	{"name": "2560x1440", "size": Vector2i(2560, 1440)}
]

func _ready():
	if not _validate_ui_references():
		push_error("SettingsPanel: 必要なUI要素が見つかりません")
		return
	
	# 背景UIを非表示にしてモーダル表示
	_hide_background_ui()
	
	settings_manager = SettingsManager.new()
	_setup_resolution_options()
	_connect_signals()
	_load_settings()
	_play_show_animation()

func _validate_ui_references() -> bool:
	return master_volume_slider != null and bgm_volume_slider != null and \
		   sfx_volume_slider != null and fullscreen_check != null and \
		   resolution_option != null and apply_button != null

func _setup_resolution_options():
	resolution_option.clear()
	for option in resolution_options:
		resolution_option.add_item(option.name)

func _connect_signals():
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	bgm_volume_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	defaults_button.pressed.connect(_on_defaults_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _load_settings():
	if settings_manager == null:
		return
	
	# 設定値を読み込み、元の値と一時保存値を初期化
	original_settings["master_volume"] = settings_manager.get_setting("master_volume", 100)
	original_settings["bgm_volume"] = settings_manager.get_setting("bgm_volume", 100)
	original_settings["sfx_volume"] = settings_manager.get_setting("sfx_volume", 100)
	original_settings["fullscreen"] = settings_manager.get_setting("fullscreen", false)
	original_settings["resolution"] = settings_manager.get_setting("resolution", "1280x720")
	
	# 一時保存値を元の値で初期化
	temp_settings = original_settings.duplicate()
	
	# UIに設定値を反映
	master_volume_slider.value = temp_settings["master_volume"]
	bgm_volume_slider.value = temp_settings["bgm_volume"]
	sfx_volume_slider.value = temp_settings["sfx_volume"]
	fullscreen_check.button_pressed = temp_settings["fullscreen"]
	
	var current_size = DisplayServer.window_get_size()
	_select_resolution_by_size(current_size)
	
	# 値ラベルを更新
	_update_volume_labels()
	
	# 適用ボタンを無効化（初期状態では変更なし）
	apply_button.disabled = true

func _select_resolution_by_size(size: Vector2i):
	for i in range(resolution_options.size()):
		if resolution_options[i].size == size:
			resolution_option.selected = i
			return
	resolution_option.selected = 0  # デフォルト

func _update_volume_labels():
	master_volume_value.text = "%d%%" % int(master_volume_slider.value)
	bgm_volume_value.text = "%d%%" % int(bgm_volume_slider.value)
	sfx_volume_value.text = "%d%%" % int(sfx_volume_slider.value)

func _on_master_volume_changed(value: float):
	master_volume_value.text = "%d%%" % int(value)
	temp_settings["master_volume"] = value
	_check_changes()
	
	# プレビューのために音量を一時的に適用
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0))
	else:
		push_warning("SettingsPanel: Masterバスが見つかりません")

func _on_bgm_volume_changed(value: float):
	bgm_volume_value.text = "%d%%" % int(value)
	temp_settings["bgm_volume"] = value
	_check_changes()
	
	# プレビューのためにBGM音量を一時的に適用
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if bgm_bus >= 0:
		AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(value / 100.0))
	else:
		push_warning("SettingsPanel: BGMバスが見つかりません")

func _on_sfx_volume_changed(value: float):
	sfx_volume_value.text = "%d%%" % int(value)
	temp_settings["sfx_volume"] = value
	_check_changes()
	
	# プレビューのためにSFX音量を一時的に適用
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value / 100.0))
	else:
		push_warning("SettingsPanel: SFXバスが見つかりません")

func _on_fullscreen_toggled(pressed: bool):
	temp_settings["fullscreen"] = pressed
	_check_changes()
	
	# プレビューのためにフルスクリーン設定を一時的に適用
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_selected(index: int):
	if index < 0 or index >= resolution_options.size():
		return
	
	var selected_resolution = resolution_options[index]
	temp_settings["resolution"] = selected_resolution.name
	_check_changes()
	
	# プレビューのために解像度を一時的に適用
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_size(selected_resolution.size)

func _on_defaults_pressed():
	_reset_to_defaults()

func _on_close_pressed():
	# 未保存の変更がある場合は元の設定に戻す
	if _has_unsaved_changes():
		_revert_to_original()
	_play_hide_animation()

func _reset_to_defaults():
	# デフォルト値を一時保存に設定
	temp_settings["master_volume"] = 100
	temp_settings["bgm_volume"] = 100
	temp_settings["sfx_volume"] = 100
	temp_settings["fullscreen"] = false
	temp_settings["resolution"] = "1280x720"
	
	# UIを更新（Signalを発生させずに直接更新）
	master_volume_slider.set_value_no_signal(100)
	bgm_volume_slider.set_value_no_signal(100)
	sfx_volume_slider.set_value_no_signal(100)
	fullscreen_check.set_pressed_no_signal(false)
	resolution_option.selected = 0
	
	# 設定をプレビュー適用
	_apply_preview_settings()
	
	# ラベル更新と変更チェック
	_update_volume_labels()
	_check_changes()

func _play_show_animation():
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	_cleanup_tween()
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)

func _play_hide_animation():
	_cleanup_tween()
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.3)
	tween.tween_callback(_close_settings).set_delay(0.3)

func _cleanup_tween():
	if tween and tween.is_valid():
		tween.kill()
	tween = null

func _close_settings():
	# 背景UIを復元
	_restore_background_ui()
	
	settings_closed.emit()
	queue_free()

func _on_apply_pressed():
	_apply_settings()

func _apply_settings():
	# 一時保存された設定を正式に保存
	for key in temp_settings:
		settings_manager.set_setting(key, temp_settings[key])
	
	# 元の設定を現在の設定で更新
	original_settings = temp_settings.duplicate()
	
	# 適用ボタンを無効化
	apply_button.disabled = true
	
	print("SettingsPanel: 設定が正常に適用されました")

func _check_changes():
	# 設定に変更があるかチェックして適用ボタンの状態を更新
	var has_changes = false
	for key in temp_settings:
		if temp_settings[key] != original_settings[key]:
			has_changes = true
			break
	
	apply_button.disabled = not has_changes

func _has_unsaved_changes() -> bool:
	for key in temp_settings:
		if temp_settings[key] != original_settings[key]:
			return true
	return false

func _revert_to_original():
	# 設定を元の値に戻す
	_apply_settings_to_system(original_settings)
	temp_settings = original_settings.duplicate()

func _apply_preview_settings():
	# プレビュー用の設定適用（システムには適用するが保存はしない）
	_apply_settings_to_system(temp_settings)

func _apply_settings_to_system(settings: Dictionary):
	# システムに設定を適用（音量、フルスクリーン、解像度）
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(settings["master_volume"] / 100.0))
	
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if bgm_bus >= 0:
		AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(settings["bgm_volume"] / 100.0))
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(settings["sfx_volume"] / 100.0))
	
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		# 解像度適用
		for option in resolution_options:
			if option.name == settings["resolution"]:
				DisplayServer.window_set_size(option.size)
				break

func _hide_background_ui():
	# 親のCanvasLayerから他のUI要素を取得
	var parent_canvas_layer = get_parent()
	if not parent_canvas_layer:
		return
	
	# 設定画面以外の子ノードを非表示にして記録
	for child in parent_canvas_layer.get_children():
		if child != self and child.visible:
			hidden_ui_nodes.append(child)
			child.visible = false

func _restore_background_ui():
	# 非表示にしたUI要素を復元
	for ui_node in hidden_ui_nodes:
		if is_instance_valid(ui_node):
			ui_node.visible = true
	hidden_ui_nodes.clear()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

# 設定管理クラス
class SettingsManager:
	var config: ConfigFile
	var settings_path: String = "user://settings.cfg"
	
	func _init():
		config = ConfigFile.new()
		load_settings()
	
	func load_settings():
		var error = config.load(settings_path)
		if error != OK and error != ERR_FILE_NOT_FOUND:
			push_error("SettingsManager: 設定ファイルの読み込みに失敗しました - エラー: %d" % error)
	
	func save_settings():
		var error = config.save(settings_path)
		if error != OK:
			push_error("SettingsManager: 設定ファイルの保存に失敗しました - エラー: %d" % error)
		else:
			print("SettingsManager: 設定保存完了")
	
	func get_setting(key: String, default_value):
		return config.get_value("settings", key, default_value)
	
	func set_setting(key: String, value):
		config.set_value("settings", key, value)
		save_settings()