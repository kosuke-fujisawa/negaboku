extends Control

# MainMenu用の直接デバッグスクリプト


func _init():
	print("★★★ MainMenuDebug: _init()が呼び出されました ★★★")


func _enter_tree():
	print("★★★ MainMenuDebug: _enter_tree()が呼び出されました ★★★")


func _ready():
	print("★★★ MainMenuDebug: _ready()が呼び出されました ★★★")
	print("MainMenuDebug: シーン名 = %s" % name)
	print("MainMenuDebug: ノードパス = %s" % get_path())

	# シーンツリーを出力
	print("MainMenuDebug: シーン構造:")
	_print_children(self, 0)

	# ボタンを検索して直接接続
	_find_and_connect_buttons()


func _print_children(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_children(child, depth + 1)


func _find_and_connect_buttons():
	print("MainMenuDebug: ボタンを検索中...")

	# 再帰的にすべてのボタンを検索
	var buttons = _find_all_buttons(self)
	print("MainMenuDebug: 見つかったボタン数: %d" % buttons.size())

	for button in buttons:
		print("MainMenuDebug: ボタン発見 - %s (%s)" % [button.text, button.get_path()])

		# 新規ゲームボタンを探す
		if button.text == "新規ゲーム":
			print("MainMenuDebug: 新規ゲームボタンにシグナル接続")
			button.pressed.connect(_on_new_game_pressed)
		elif button.text == "ゲームロード":
			print("MainMenuDebug: ロードボタンにシグナル接続")
			button.pressed.connect(_on_load_pressed)
		elif button.text == "設定":
			print("MainMenuDebug: 設定ボタンにシグナル接続")
			button.pressed.connect(_on_settings_pressed)
		elif button.text == "ゲーム終了":
			print("MainMenuDebug: 終了ボタンにシグナル接続")
			button.pressed.connect(_on_quit_pressed)


func _find_all_buttons(node: Node) -> Array:
	var buttons = []

	if node is Button:
		buttons.append(node)

	for child in node.get_children():
		buttons.append_array(_find_all_buttons(child))

	return buttons


func _on_new_game_pressed():
	print("★★★ MainMenuDebug: 新規ゲームボタンが押されました！ ★★★")

	# 直接SimpleWorkingTextシーンに遷移
	print("MainMenuDebug: 直接SimpleWorkingText.tscnに遷移")
	get_tree().change_scene_to_file("res://Scenes/SimpleWorkingText.tscn")


func _on_load_pressed():
	print("★★★ MainMenuDebug: ロードボタンが押されました ★★★")


func _on_settings_pressed():
	print("★★★ MainMenuDebug: 設定ボタンが押されました ★★★")


func _on_quit_pressed():
	print("★★★ MainMenuDebug: 終了ボタンが押されました ★★★")
	get_tree().quit()


func _input(event):
	if event is InputEventKey and event.pressed:
		print("MainMenuDebug: キー押下 - %s" % event.keycode)
		if event.keycode == KEY_SPACE:
			print("MainMenuDebug: Spaceキーで新規ゲーム強制実行")
			_on_new_game_pressed()
