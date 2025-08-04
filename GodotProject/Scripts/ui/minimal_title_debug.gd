extends Control

# タイトル画面 - シンプルなボタン接続

# UI参照
@onready var new_game_button: Button = $UILayer/MainContainer/MenuContainer/NewGameButton
@onready var load_game_button: Button = $UILayer/MainContainer/MenuContainer/LoadGameButton
@onready var settings_button: Button = $UILayer/MainContainer/MenuContainer/SettingsButton
@onready var quit_button: Button = $UILayer/MainContainer/MenuContainer/QuitButton

func _ready():
	print("=== タイトル画面初期化開始 ===")
	print("ノード名: %s" % name)
	
	# ボタンシグナル接続
	_connect_buttons()
	
	print("=== タイトル画面初期化完了 ===")

func _connect_buttons():
	# ボタンが存在するかチェックして接続
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
		print("新規ゲームボタン: 接続完了")
	else:
		print("エラー: 新規ゲームボタンが見つかりません")
	
	if load_game_button:
		load_game_button.pressed.connect(_on_load_game_pressed)
		print("ロードゲームボタン: 接続完了")
	else:
		print("エラー: ロードゲームボタンが見つかりません")
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		print("設定ボタン: 接続完了")
	else:
		print("エラー: 設定ボタンが見つかりません")
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		print("終了ボタン: 接続完了")
	else:
		print("エラー: 終了ボタンが見つかりません")

func _on_new_game_pressed():
	print("★★★ 新規ゲーム開始！ ★★★")
	
	# GameManagerの確認
	if not GameManager:
		print("エラー: GameManagerが見つかりません")
		return
	
	print("GameManager見つかりました")
	
	# GameManagerで新規ゲーム開始
	if GameManager.has_method("start_new_game"):
		print("GameManager.start_new_game()を呼び出します...")
		await GameManager.start_new_game()
		print("新規ゲーム開始処理完了")
	else:
		print("エラー: start_new_game()メソッドが見つかりません")
		# フォールバック: 直接メインシーンに遷移
		print("フォールバック: Main.tscnに直接遷移")
		get_tree().change_scene_to_file("res://Scenes/Main.tscn")

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
		match event.keycode:
			KEY_1:
				print("=== デバッグ: 新規ゲーム強制実行 ===")
				_on_new_game_pressed()
			KEY_2:
				print("=== デバッグ: Main.tscnに直接遷移 ===")
				get_tree().change_scene_to_file("res://Scenes/Main.tscn")
			KEY_3:
				if GameManager and GameManager.has_method("print_system_diagnostics"):
					GameManager.print_system_diagnostics()
			KEY_ESCAPE:
				print("ESCキーでゲーム終了")
				get_tree().quit()