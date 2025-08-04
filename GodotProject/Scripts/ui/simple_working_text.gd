extends Control

# 最もシンプルなテキスト表示テスト

var test_messages = [
	"テスト開始: シンプルテキスト表示",
	"ソウマ: ここが遺跡の入り口だ...",
	"ユズキ: 少し怖いけど、一緒なら大丈夫",
	"ソウマ: ああ、君と一緒なら何も怖くない",
	"システム: テキスト表示テスト完了"
]

var current_index = 0
var text_label: Label
var background: ColorRect

func _ready():
	print("=== SimpleWorkingText: 開始 ===")
	
	# 背景を作成
	background = ColorRect.new()
	background.color = Color.DARK_BLUE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	print("SimpleWorkingText: 背景作成完了")
	
	# テキストラベルを作成
	text_label = Label.new()
	text_label.position = Vector2(50, 300)
	text_label.size = Vector2(900, 200)
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(text_label)
	print("SimpleWorkingText: テキストラベル作成完了")
	
	# 最初のメッセージを表示
	show_current_message()
	print("=== SimpleWorkingText: 初期化完了 ===")

func show_current_message():
	if current_index < test_messages.size():
		var message = test_messages[current_index]
		text_label.text = message
		print("SimpleWorkingText: メッセージ表示 [%d]: %s" % [current_index, message])
	else:
		text_label.text = "テスト完了 - ESCキーでタイトルに戻る"
		print("SimpleWorkingText: テスト完了")

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		advance_message()
	elif event.is_action_pressed("ui_cancel"):
		return_to_title()

func advance_message():
	current_index += 1
	show_current_message()

func return_to_title():
	print("SimpleWorkingText: タイトルに戻る")
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")