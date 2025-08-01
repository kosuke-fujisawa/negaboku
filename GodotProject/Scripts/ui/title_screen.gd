class_name TitleScreen
extends Control

signal new_game_requested
signal load_game_requested
signal settings_requested
signal quit_requested

@onready var new_game_button: Button = $UILayer/MainContainer/MenuContainer/NewGameButton
@onready var load_game_button: Button = $UILayer/MainContainer/MenuContainer/LoadGameButton
@onready var settings_button: Button = $UILayer/MainContainer/MenuContainer/SettingsButton
@onready var quit_button: Button = $UILayer/MainContainer/MenuContainer/QuitButton
@onready var title_logo: Label = $UILayer/MainContainer/TitleLogo
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var tween: Tween

func _ready():
	_connect_signals()
	_setup_initial_state()
	_play_intro_animation()

func _connect_signals():
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# ボタンホバーエフェクト
	for button in [new_game_button, load_game_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _setup_initial_state():
	# 初期状態でUI要素を非表示にする
	title_logo.modulate.a = 0.0
	for button in [new_game_button, load_game_button, settings_button, quit_button]:
		button.modulate.a = 0.0
		button.position.x += 50  # 右にオフセット
	
	# ロードボタンの有効性チェック
	_update_load_button_availability()

func _update_load_button_availability():
	var save_exists = FileAccess.file_exists("user://savegame.save")
	load_game_button.disabled = not save_exists
	if not save_exists:
		load_game_button.modulate = Color(1, 1, 1, 0.5)

func _play_intro_animation():
	_cleanup_tween()
	tween = create_tween()
	tween.set_parallel(true)
	
	# タイトルロゴのフェードイン
	tween.tween_property(title_logo, "modulate:a", 1.0, 0.8)
	tween.tween_property(title_logo, "scale", Vector2(1.1, 1.1), 0.8)
	tween.tween_property(title_logo, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.8)
	
	# メニューボタンのスライドイン + フェードイン
	var delay = 1.0
	for button in [new_game_button, load_game_button, settings_button, quit_button]:
		tween.tween_property(button, "modulate:a", 1.0, 0.5).set_delay(delay)
		tween.tween_property(button, "position:x", button.position.x - 50, 0.5).set_delay(delay)
		delay += 0.1

func _on_button_hover(button: Button):
	_cleanup_tween()
	tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unhover(button: Button):
	_cleanup_tween()
	tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _cleanup_tween():
	if tween and tween.is_valid():
		tween.kill()
	tween = null

func _on_new_game_pressed():
	_play_button_press_effect(new_game_button)
	new_game_requested.emit()
	# GameManagerを通して新規ゲーム開始
	GameManager.start_new_game()

func _on_load_game_pressed():
	if load_game_button.disabled:
		return
	_play_button_press_effect(load_game_button)
	load_game_requested.emit()
	# GameManagerを通してゲームをロードしてメインシーンに遷移
	if GameManager.load_game():
		_transition_to_game()
	else:
		_show_load_error_message()

func _show_load_error_message():
	# TODO: モーダルダイアログまたはトーストメッセージでユーザーに通知
	print("TitleScreen: ゲームロードに失敗しました")
	# 暫定的にボタンを一時的に赤くしてユーザーにフィードバック
	_cleanup_tween()
	tween = create_tween()
	tween.tween_property(load_game_button, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.2)
	tween.tween_property(load_game_button, "modulate", Color(1.0, 1.0, 1.0, 0.5), 0.5)

func _on_settings_pressed():
	_play_button_press_effect(settings_button)
	settings_requested.emit()
	_show_settings_panel()

func _show_settings_panel():
	var settings_scene = preload("res://Scenes/UI/SettingsPanel.tscn")
	var settings_instance = settings_scene.instantiate()
	add_child(settings_instance)
	settings_instance.settings_closed.connect(_on_settings_closed)

func _on_settings_closed():
	print("TitleScreen: 設定画面が閉じられました")

func _on_quit_pressed():
	_play_button_press_effect(quit_button)
	quit_requested.emit()
	_quit_game()

func _play_button_press_effect(button: Button):
	_cleanup_tween()
	tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _transition_to_game():
	# ゲーム画面への遷移アニメーション
	_cleanup_tween()
	tween = create_tween()
	tween.set_parallel(true)
	
	# フェードアウト
	for node in [title_logo, new_game_button, load_game_button, settings_button, quit_button]:
		tween.tween_property(node, "modulate:a", 0.0, 0.5)
	
	# シーン遷移
	tween.tween_callback(_change_to_game_scene).set_delay(0.5)

func _change_to_game_scene():
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _quit_game():
	# 終了アニメーション
	_cleanup_tween()
	tween = create_tween()
	tween.set_parallel(true)
	
	for node in [title_logo, new_game_button, load_game_button, settings_button, quit_button]:
		tween.tween_property(node, "modulate:a", 0.0, 0.3)
		tween.tween_property(node, "scale", Vector2(0.8, 0.8), 0.3)
	
	tween.tween_callback(get_tree().quit).set_delay(0.3)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if new_game_button.has_focus():
			_on_new_game_pressed()
			get_viewport().set_input_as_handled()
		elif load_game_button.has_focus() and not load_game_button.disabled:
			_on_load_game_pressed()
			get_viewport().set_input_as_handled()
		elif settings_button.has_focus():
			_on_settings_pressed()
			get_viewport().set_input_as_handled()
		elif quit_button.has_focus():
			_on_quit_pressed()
			get_viewport().set_input_as_handled()