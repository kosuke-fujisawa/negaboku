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
@onready var close_button: Button = $SettingsDialog/VBoxContainer/ButtonContainer/CloseButton

# 設定データ
var settings_manager: SettingsManager
var tween: Tween

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
	settings_manager = SettingsManager.new()
	_setup_resolution_options()
	_connect_signals()
	_load_settings()
	_play_show_animation()

func _validate_ui_references() -> bool:
	return master_volume_slider != null and bgm_volume_slider != null and \
		   sfx_volume_slider != null and fullscreen_check != null and \
		   resolution_option != null

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
	close_button.pressed.connect(_on_close_pressed)

func _load_settings():
	if settings_manager == null:
		return
	
	# 音量設定の読み込み
	master_volume_slider.value = settings_manager.get_setting("master_volume", 100)
	bgm_volume_slider.value = settings_manager.get_setting("bgm_volume", 100)
	sfx_volume_slider.value = settings_manager.get_setting("sfx_volume", 100)
	
	# ディスプレイ設定の読み込み
	fullscreen_check.button_pressed = settings_manager.get_setting("fullscreen", false)
	
	var current_size = DisplayServer.window_get_size()
	_select_resolution_by_size(current_size)
	
	# 値ラベルを更新
	_update_volume_labels()

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
	settings_manager.set_setting("master_volume", value)
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0))
	else:
		push_warning("SettingsPanel: Masterバスが見つかりません")

func _on_bgm_volume_changed(value: float):
	bgm_volume_value.text = "%d%%" % int(value)
	settings_manager.set_setting("bgm_volume", value)
	# BGMバス音量調整（バス名は将来的に設定される）
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if bgm_bus >= 0:
		AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(value / 100.0))
	else:
		push_warning("SettingsPanel: BGMバスが見つかりません")

func _on_sfx_volume_changed(value: float):
	sfx_volume_value.text = "%d%%" % int(value)
	settings_manager.set_setting("sfx_volume", value)
	# SFXバス音量調整（バス名は将来的に設定される）
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value / 100.0))
	else:
		push_warning("SettingsPanel: SFXバスが見つかりません")

func _on_fullscreen_toggled(pressed: bool):
	settings_manager.set_setting("fullscreen", pressed)
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_selected(index: int):
	if index < 0 or index >= resolution_options.size():
		return
	
	var selected_resolution = resolution_options[index]
	settings_manager.set_setting("resolution", selected_resolution.name)
	
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_size(selected_resolution.size)

func _on_defaults_pressed():
	_reset_to_defaults()
	settings_manager.save_settings()

func _on_close_pressed():
	_play_hide_animation()

func _reset_to_defaults():
	master_volume_slider.value = 100
	bgm_volume_slider.value = 100
	sfx_volume_slider.value = 100
	fullscreen_check.button_pressed = false
	resolution_option.selected = 0
	
	# 設定を適用
	_on_master_volume_changed(100)
	_on_bgm_volume_changed(100)
	_on_sfx_volume_changed(100)
	_on_fullscreen_toggled(false)
	_on_resolution_selected(0)

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
	settings_closed.emit()
	queue_free()

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