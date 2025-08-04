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
	
	# 最もシンプルなテキスト表示シーンに遷移
	print("SimpleWorkingTextに遷移します...")
	var target_scene = "res://Scenes/SimpleWorkingText.tscn"
	
	if ResourceLoader.exists(target_scene):
		print("SimpleWorkingText.tscnが見つかりました")
		get_tree().change_scene_to_file(target_scene)
	else:
		print("エラー: SimpleWorkingText.tscnが見つかりません")
		# フォールバック: WorkingTextScene
		var fallback_scene = "res://Scenes/WorkingTextScene.tscn"
		if ResourceLoader.exists(fallback_scene):
			print("フォールバック: WorkingTextSceneに遷移")
			get_tree().change_scene_to_file(fallback_scene)
		else:
			print("エラー: フォールバックシーンも見つかりません")

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
				print("=== デバッグ: SimpleWorkingTextに直接遷移 ===")
				get_tree().change_scene_to_file("res://Scenes/SimpleWorkingText.tscn")
			KEY_3:
				print("=== デバッグ: WorkingTextSceneに直接遷移 ===")
				get_tree().change_scene_to_file("res://Scenes/WorkingTextScene.tscn")
			KEY_4:
				if GameManager and GameManager.has_method("print_system_diagnostics"):
					GameManager.print_system_diagnostics()
			KEY_ESCAPE:
				print("ESCキーでゲーム終了")
				get_tree().quit()