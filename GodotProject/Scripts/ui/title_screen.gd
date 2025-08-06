class_name TitleScreen
extends Control

signal new_game_requested
signal load_game_requested
signal settings_requested
signal quit_requested

# 動的にノードを取得する方式に変更（@onreadyの問題を回避）
var new_game_button: Button
var load_game_button: Button
var settings_button: Button
var quit_button: Button
var title_logo: Label
var animation_player: AnimationPlayer

var tween: Tween


func _ready():
	print("TitleScreen: 初期化開始")

	# デバッグビルドでのみ詳細ログ
	if OS.is_debug_build():
		print("TitleScreen: デバッグモード - 詳細ログ有効")
		print("TitleScreen: スクリプトパス = %s" % get_script().resource_path)
		print("TitleScreen: ノード名 = %s" % name)

	_setup_node_references()
	_connect_signals()
	_setup_initial_state()
	_play_intro_animation()

	print("TitleScreen: 初期化完了")


func _setup_node_references():
	# ノード参照の設定#
	# 動的にノードを取得（@onreadyの代替）
	new_game_button = get_node_or_null("UILayer/MainContainer/MenuContainer/NewGameButton")
	load_game_button = get_node_or_null("UILayer/MainContainer/MenuContainer/LoadGameButton")
	settings_button = get_node_or_null("UILayer/MainContainer/MenuContainer/SettingsButton")
	quit_button = get_node_or_null("UILayer/MainContainer/MenuContainer/QuitButton")
	title_logo = get_node_or_null("UILayer/MainContainer/TitleLogo")
	animation_player = get_node_or_null("AnimationPlayer")

	# デバッグビルドでノード確認
	if OS.is_debug_build():
		var nodes = [
			["new_game_button", new_game_button],
			["load_game_button", load_game_button],
			["settings_button", settings_button],
			["quit_button", quit_button],
			["title_logo", title_logo],
			["animation_player", animation_player]
		]

		for node_info in nodes:
			var node_name = node_info[0]
			var node_ref = node_info[1]
			if node_ref == null:
				print("警告: %s が見つかりません" % node_name)


func _connect_signals():
	# ボタンシグナルの接続#
	var button_connections = [
		[new_game_button, _on_new_game_pressed],
		[load_game_button, _on_load_game_pressed],
		[settings_button, _on_settings_pressed],
		[quit_button, _on_quit_pressed]
	]

	var connected_count = 0
	for connection in button_connections:
		var button = connection[0]
		var callback = connection[1]

		if button != null:
			button.pressed.connect(callback)
			# ホバーエフェクト
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))
			connected_count += 1
		elif OS.is_debug_build():
			print("警告: ボタンがnullのため接続をスキップ")

	if OS.is_debug_build():
		print("TitleScreen: %d個のボタンシグナルを接続" % connected_count)


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
	print("TitleScreen: 新規ゲーム開始")

	_play_button_press_effect(new_game_button)
	new_game_requested.emit()

	# ボタンを一時的に無効化して重複クリックを防止
	if new_game_button:
		new_game_button.disabled = true

	# GameManagerの存在確認
	if GameManager == null:
		print("エラー: GameManagerが見つかりません")
		if new_game_button:
			new_game_button.disabled = false
		return

	# GameManagerを通して新規ゲーム開始
	await GameManager.start_new_game()

	# 失敗した場合のみボタンを再有効化
	if get_tree().current_scene == self and new_game_button:  # まだタイトル画面にいる場合
		new_game_button.disabled = false
		print("TitleScreen: 新規ゲーム開始が失敗しました")


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
	# より安全なシーン遷移
	var target_scene = "res://Scenes/Main.tscn"
	if ResourceLoader.exists(target_scene):
		print("TitleScreen: %s に遷移します" % target_scene)
		get_tree().change_scene_to_file(target_scene)
	else:
		print("エラー: ターゲットシーンが見つかりません: %s" % target_scene)
		# フォールバック先を試行
		target_scene = "res://Scenes/WorkingTextScene.tscn"
		if ResourceLoader.exists(target_scene):
			print("TitleScreen: フォールバック先に遷移: %s" % target_scene)
			get_tree().change_scene_to_file(target_scene)
		else:
			print("エラー: フォールバック先も見つかりません")


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
		if new_game_button and new_game_button.has_focus():
			_on_new_game_pressed()
			get_viewport().set_input_as_handled()
		elif load_game_button and load_game_button.has_focus() and not load_game_button.disabled:
			_on_load_game_pressed()
			get_viewport().set_input_as_handled()
		elif settings_button and settings_button.has_focus():
			_on_settings_pressed()
			get_viewport().set_input_as_handled()
		elif quit_button and quit_button.has_focus():
			_on_quit_pressed()
			get_viewport().set_input_as_handled()
	# デバッグビルドでのみSpaceキーショートカット
	elif (
		OS.is_debug_build()
		and event is InputEventKey
		and event.pressed
		and event.keycode == KEY_SPACE
	):
		_on_new_game_pressed()
