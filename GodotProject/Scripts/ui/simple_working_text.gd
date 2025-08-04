extends Control

# 最もシンプルなテキスト表示 - マークダウンシナリオ対応

# フォールバック用テストメッセージ
var fallback_messages = [
	"システム: 願い石と僕たちの絆 - デモンストレーション",
	"ソウマ: ……ここが噂の遺跡、か。",
	"ユズキ: うん。……緊張してる？",
	"ソウマ: 少しね。でも、君と一緒なら大丈夫だと思う。",
	"ユズキ: ありがとう。私も、ソウマと一緒だから安心してる。",
	"ソウマ: さあ、行こうか。遺跡の入り口が見えてきた。",
	"システム: この後、選択肢システムや関係値システムが表示されます。",
	"システム: テキストダイアログシステム - 動作確認完了"
]

# 実際に使用するメッセージ配列
var current_messages = []

var current_index = 0
var text_label: Label
var name_label: Label
var continue_indicator: Label
var background: ColorRect
var text_panel: Panel

func _ready():
	print("=== SimpleWorkingText: 開始 ===")
	
	# 背景を作成
	background = ColorRect.new()
	background.color = Color.DARK_BLUE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	print("SimpleWorkingText: 背景作成完了")
	
	# テキストパネルを作成（ダイアログボックス風）
	text_panel = Panel.new()
	text_panel.position = Vector2(50, 400)
	text_panel.size = Vector2(900, 180)
	add_child(text_panel)
	print("SimpleWorkingText: テキストパネル作成完了")
	
	# 話者名ラベルを作成
	name_label = Label.new()
	name_label.position = Vector2(20, 10)
	name_label.size = Vector2(200, 30)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.YELLOW)
	text_panel.add_child(name_label)
	print("SimpleWorkingText: 話者名ラベル作成完了")
	
	# テキストラベルを作成
	text_label = Label.new()
	text_label.position = Vector2(20, 45)
	text_label.size = Vector2(860, 100)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_panel.add_child(text_label)
	print("SimpleWorkingText: テキストラベル作成完了")
	
	# 進行インジケーターを作成
	continue_indicator = Label.new()
	continue_indicator.text = "▼"
	continue_indicator.position = Vector2(850, 150)
	continue_indicator.size = Vector2(30, 20)
	continue_indicator.add_theme_font_size_override("font_size", 20)
	continue_indicator.add_theme_color_override("font_color", Color.WHITE)
	continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_panel.add_child(continue_indicator)
	print("SimpleWorkingText: 進行インジケーター作成完了")
	
	# マークダウンシナリオを読み込み
	load_markdown_scenario()
	
	# 最初のメッセージを表示
	show_current_message()
	print("=== SimpleWorkingText: 初期化完了 ===")

func show_current_message():
	if current_index < current_messages.size():
		var message = current_messages[current_index]
		var parts = message.split(": ", false, 1)
		
		if parts.size() == 2:
			# 話者名がある場合
			name_label.text = parts[0]
			name_label.visible = true
			text_label.text = parts[1]
			print("SimpleWorkingText: メッセージ表示 [%d] %s: %s" % [current_index, parts[0], parts[1]])
		else:
			# 話者名がない場合
			name_label.visible = false
			text_label.text = message
			print("SimpleWorkingText: メッセージ表示 [%d]: %s" % [current_index, message])
	else:
		name_label.visible = false
		text_label.text = "テキストダイアログシステム動作確認完了\n\nESCキーでタイトルに戻る"
		continue_indicator.visible = false
		print("SimpleWorkingText: テスト完了")

func load_markdown_scenario():
	# scene01.mdからシナリオを読み込み# 
	print("SimpleWorkingText: マークダウンシナリオ読み込み開始")
	
	# まずフォールバックメッセージを設定（安全措置）
	current_messages = fallback_messages.duplicate()
	
	# ScenarioLoaderのインスタンス化を試行
	var scenario_loader = null
	var scenario_path = "res://Assets/scenarios/scene01.md"
	
	# ScenarioLoaderが利用可能かチェック
	if not ResourceLoader.exists("res://Scripts/systems/scenario_loader.gd"):
		print("SimpleWorkingText: ScenarioLoaderが見つかりません、フォールバックメッセージを使用")
		return
	
	try:
		scenario_loader = ScenarioLoader.new()
	except:
		print("SimpleWorkingText: ScenarioLoaderのインスタンス化に失敗、フォールバックメッセージを使用")
		return
	
	if scenario_loader == null:
		print("SimpleWorkingText: ScenarioLoaderがnull、フォールバックメッセージを使用")
		return
	
	# 強制再読み込みで最新のファイル内容を確実に読み込む
	var loaded_scenario_data = null
	try:
		loaded_scenario_data = scenario_loader.force_reload_scenario_file(scenario_path)
	except:
		print("SimpleWorkingText: マークダウン読み込み中にエラー、フォールバックメッセージを使用")
		return
	
	if loaded_scenario_data == null:
		print("SimpleWorkingText: マークダウン読み込み失敗、フォールバックメッセージを使用")
		return
	
	# ScenarioDataをメッセージ配列に変換
	var converted_scenes = null
	try:
		converted_scenes = scenario_loader.convert_to_text_scene_data(loaded_scenario_data)
	except:
		print("SimpleWorkingText: シーンデータ変換中にエラー、フォールバックメッセージを使用")
		return
	
	if converted_scenes == null or converted_scenes.is_empty():
		print("SimpleWorkingText: シーンデータ変換失敗、フォールバックメッセージを使用")
		return
	
	# シーンデータをシンプルなメッセージ形式に変換
	current_messages.clear()
	for scene_data in converted_scenes:
		var message = ""
		if scene_data.speaker_name.is_empty():
			message = scene_data.text
		else:
			message = "%s: %s" % [scene_data.speaker_name, scene_data.text]
		current_messages.append(message)
	
	print("SimpleWorkingText: マークダウンシナリオ読み込み成功: %d メッセージ" % current_messages.size())

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