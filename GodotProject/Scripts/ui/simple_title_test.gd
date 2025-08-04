extends Control

# 最もシンプルなタイトル画面テスト

func _init():
	print("★★★ SimpleTitleTest: _init() ★★★")

func _ready():
	print("★★★ SimpleTitleTest: _ready() ★★★")
	
	# 背景を作成
	var background = ColorRect.new()
	background.color = Color.BLUE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# ボタンを作成
	var button = Button.new()
	button.text = "テストボタン"
	button.position = Vector2(400, 300)
	button.size = Vector2(200, 50)
	button.pressed.connect(_on_test_button_pressed)
	add_child(button)
	
	print("SimpleTitleTest: セットアップ完了")

func _on_test_button_pressed():
	print("★★★ SimpleTitleTest: ボタンが押されました！ ★★★")
	
	# GameManagerテスト
	if GameManager:
		print("SimpleTitleTest: GameManagerが見つかりました")
		GameManager.print_system_diagnostics()
	else:
		print("SimpleTitleTest: GameManagerが見つかりません")
	
	# シーン遷移テスト
	print("SimpleTitleTest: Main.tscnに遷移します")
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		print("SimpleTitleTest: キー押下 - %s" % event.keycode)
		if event.keycode == KEY_SPACE:
			_on_test_button_pressed()