extends Control

# タイトル画面 - シンプルなボタン接続

# UI参照（手動取得に変更）
var new_game_button: Button
var load_game_button: Button
var settings_button: Button
var quit_button: Button


func _ready():
	print("=== タイトル画面初期化開始 ===")
	print("ノード名: %s" % name)

	# 手動でボタンを取得
	_get_button_references()

	# ボタンシグナル接続
	_connect_buttons()

	print("=== タイトル画面初期化完了 ===")


func _get_button_references():
	print("=== ボタン参照取得開始 ===")

	# 各ボタンを手動で取得
	print("新規ゲームボタンを検索中...")
	new_game_button = get_node_or_null("UILayer/MainContainer/MenuContainer/NewGameButton")
	if new_game_button:
		print("✅ 新規ゲームボタンが見つかりました")
	else:
		print("❌ 新規ゲームボタンが見つかりません")

	print("ロードゲームボタンを検索中...")
	load_game_button = get_node_or_null("UILayer/MainContainer/MenuContainer/LoadGameButton")
	if load_game_button:
		print("✅ ロードゲームボタンが見つかりました")
	else:
		print("❌ ロードゲームボタンが見つかりません")

	print("設定ボタンを検索中...")
	settings_button = get_node_or_null("UILayer/MainContainer/MenuContainer/SettingsButton")
	if settings_button:
		print("✅ 設定ボタンが見つかりました")
	else:
		print("❌ 設定ボタンが見つかりません")

	print("終了ボタンを検索中...")
	quit_button = get_node_or_null("UILayer/MainContainer/MenuContainer/QuitButton")
	if quit_button:
		print("✅ 終了ボタンが見つかりました")
	else:
		print("❌ 終了ボタンが見つかりません")

	# 見つからない場合はシーン構造を出力
	if not new_game_button or not load_game_button or not settings_button or not quit_button:
		print("一部のボタンが見つからないため、シーン構造を出力します...")
		_debug_scene_structure()

	print("=== ボタン参照取得完了 ===")

	# 自動テスト一時無効化
	# print("5秒後に自動で新規ゲームボタンを押します（デバッグ）")
	# await get_tree().create_timer(5.0).timeout
	# print("自動テスト: 新規ゲームボタンを押します")
	# _on_new_game_pressed()


func _connect_buttons():
	print("=== ボタン接続処理開始 ===")

	# ボタンが存在するかチェックして接続
	print("新規ゲームボタンのチェック中...")
	if new_game_button:
		print("✅ 新規ゲームボタンが見つかりました: %s" % new_game_button.name)
		print("ボタンのパス: %s" % new_game_button.get_path())
		print("ボタンのテキスト: %s" % new_game_button.text)
		new_game_button.pressed.connect(_on_new_game_pressed)
		print("新規ゲームボタン: シグナル接続完了")
	else:
		print("❌ エラー: 新規ゲームボタンが見つかりません")
		print("手動検索を試行...")
		var manual_button = get_node_or_null("UILayer/MainContainer/MenuContainer/NewGameButton")
		if manual_button:
			print("✅ 手動検索で新規ゲームボタンが見つかりました")
			new_game_button = manual_button
			new_game_button.pressed.connect(_on_new_game_pressed)
			print("手動検索で新規ゲームボタン: シグナル接続完了")
		else:
			print("❌ 手動検索でも新規ゲームボタンが見つかりません")
			_debug_scene_structure()

	# 他のボタンも同様にチェック
	print("ロードゲームボタンのチェック中...")
	if load_game_button:
		load_game_button.pressed.connect(_on_load_game_pressed)
		print("ロードゲームボタン: 接続完了")
	else:
		print("❌ エラー: ロードゲームボタンが見つかりません")

	print("設定ボタンのチェック中...")
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		print("設定ボタン: 接続完了")
	else:
		print("❌ エラー: 設定ボタンが見つかりません")

	print("終了ボタンのチェック中...")
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		print("終了ボタン: 接続完了")
	else:
		print("❌ エラー: 終了ボタンが見つかりません")

	print("=== ボタン接続処理完了 ===")


func _debug_scene_structure():
	print("=== シーン構造デバッグ ===")
	_print_children(self, 0)


func _print_children(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_children(child, depth + 1)


func _on_new_game_pressed():
	print("🎯 新規ゲームボタンがクリックされました！")
	print("現在時刻: %s" % Time.get_datetime_string_from_system())

	# 直接SimpleWorkingTextシーンに遷移
	var target_scene = "res://Scenes/SimpleWorkingText.tscn"

	print("シーン遷移開始: %s" % target_scene)
	if ResourceLoader.exists(target_scene):
		print("✅ ターゲットシーンが存在します")
		var result = get_tree().change_scene_to_file(target_scene)
		if result == OK:
			print("🎉 シーン遷移成功！")
		else:
			print("❌ シーン遷移失敗 - エラーコード: %d" % result)
	else:
		print("❌ ターゲットシーンが見つかりません: %s" % target_scene)


func _on_load_game_pressed():
	print("ゲームロード機能（未実装）")


func _on_settings_pressed():
	print("設定画面（未実装）")


func _on_quit_pressed():
	print("ゲーム終了")
	get_tree().quit()


# デバッグ用キーボード入力
func _input(event):
	if event is InputEventKey and event.pressed:
		print("キー入力検出: %s" % event.keycode)
		match event.keycode:
			KEY_1:
				print("=== デバッグ: 新規ゲーム強制実行 ===")
				_on_new_game_pressed()
			KEY_2:
				print("=== デバッグ: SimpleWorkingTextに直接遷移 ===")
				get_tree().change_scene_to_file("res://Scenes/SimpleWorkingText.tscn")
			KEY_3:
				print("=== デバッグ: WorkingTextSceneに直接遷移 ===")
				get_tree().change_scene_to_file("res://Scenes/WorkingTextScene.tscn")
			KEY_4:
				print("=== デバッグ: システム情報 ===")
				print("Godotバージョン: %s" % Engine.get_version_info())
				print("現在のシーン: %s" % get_tree().current_scene.name)
				print("フレーム数: %d" % Engine.get_process_frames())
			KEY_5:
				print("=== デバッグ: ボタン状態確認 ===")
				_debug_button_status()
			KEY_6:
				print("=== デバッグ: 新規ゲームボタンを手動クリック ===")
				if new_game_button:
					print("ボタンを手動でクリックします...")
					new_game_button.pressed.emit()
				else:
					print("新規ゲームボタンがnullです")
			KEY_SPACE:
				print("=== スペースキー: 新規ゲーム強制実行 ===")
				_on_new_game_pressed()
			KEY_ESCAPE:
				print("ESCキーでゲーム終了")
				get_tree().quit()


func _debug_button_status():
	print("=== ボタン状態デバッグ ===")
	if new_game_button:
		print("新規ゲームボタン:")
		print("  ノード名: %s" % new_game_button.name)
		print("  パス: %s" % new_game_button.get_path())
		print("  テキスト: %s" % new_game_button.text)
		print("  無効化: %s" % new_game_button.disabled)
		print("  可視: %s" % new_game_button.visible)
		print("  接続されたシグナル数: %s" % new_game_button.pressed.get_connections().size())
		for connection in new_game_button.pressed.get_connections():
			print(
				(
					"    -> %s.%s"
					% [connection.callable.get_object(), connection.callable.get_method()]
				)
			)
	else:
		print("新規ゲームボタン: null")
	print("========================")
