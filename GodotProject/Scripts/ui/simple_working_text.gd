extends Control

# 最もシンプルなテキスト表示テスト

var test_messages = [
	"システム: 願い石と僕たちの絆 - デモンストレーション",
	"ソウマ: ……ここが噂の遺跡、か。",
	"ユズキ: うん。……緊張してる？",
	"ソウマ: 少しね。でも、君と一緒なら大丈夫だと思う。",
	"ユズキ: ありがとう。私も、ソウマと一緒だから安心してる。",
	"ソウマ: さあ、行こうか。遺跡の入り口が見えてきた。",
	"システム: この後、選択肢システムや関係値システムが表示されます。",
	"システム: テキストダイアログシステム - 動作確認完了"
]

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
	
	# マークダウンシナリオの読み込みを試行（失敗時はtest_messagesをそのまま使用）
	_try_load_markdown_scenario()
	
	# 最初のメッセージを表示
	show_current_message()
	print("=== SimpleWorkingText: 初期化完了 ===")

func show_current_message():
	if current_index < test_messages.size():
		var message = test_messages[current_index]
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

func _try_load_markdown_scenario():
	# scene01.mdからシナリオを読み込み、成功時のみtest_messagesを置き換える
	print("★★★ SimpleWorkingText: マークダウンシナリオ読み込み試行開始 ★★★")
	
	# ScenarioLoaderクラスが利用可能かチェック
	print("SimpleWorkingText: ScenarioLoaderスクリプトを読み込み中...")
	var scenario_loader_script = load("res://Scripts/systems/scenario_loader.gd")
	if scenario_loader_script == null:
		print("❌ SimpleWorkingText: ScenarioLoaderが見つかりません。デフォルトメッセージを使用します。")
		return
	print("✅ SimpleWorkingText: ScenarioLoaderスクリプト読み込み成功")
	
	print("SimpleWorkingText: ScenarioLoaderインスタンス化中...")
	var scenario_loader = scenario_loader_script.new()
	if scenario_loader == null:
		print("❌ SimpleWorkingText: ScenarioLoaderのインスタンス化に失敗。デフォルトメッセージを使用します。")
		return
	print("✅ SimpleWorkingText: ScenarioLoaderインスタンス化成功")
	
	# force_reload_scenario_file が利用可能かチェック
	print("SimpleWorkingText: force_reload_scenario_fileメソッドの存在確認中...")
	if not scenario_loader.has_method("force_reload_scenario_file"):
		print("❌ SimpleWorkingText: force_reload_scenario_fileメソッドが見つかりません。デフォルトメッセージを使用します。")
		return
	print("✅ SimpleWorkingText: force_reload_scenario_fileメソッド存在確認")
	
	# シナリオファイルを読み込み
	var scenario_path = "res://Assets/scenarios/scene01.md"
	print("SimpleWorkingText: シナリオファイル読み込み中: %s" % scenario_path)
	var loaded_scenario_data = scenario_loader.force_reload_scenario_file(scenario_path)
	
	if loaded_scenario_data == null:
		print("❌ SimpleWorkingText: マークダウン読み込み失敗。デフォルトメッセージを使用します。")
		return
	print("✅ SimpleWorkingText: シナリオデータ読み込み成功")
	
	# シーンデータに変換
	print("SimpleWorkingText: シーンデータ変換中...")
	var converted_scenes = scenario_loader.convert_to_text_scene_data(loaded_scenario_data)
	if converted_scenes == null or converted_scenes.is_empty():
		print("❌ SimpleWorkingText: シーンデータ変換失敗。デフォルトメッセージを使用します。")
		return
	print("✅ SimpleWorkingText: シーンデータ変換成功: %d シーン" % converted_scenes.size())
	
	# 成功時のみtest_messagesを置き換え
	print("SimpleWorkingText: メッセージ配列変換中...")
	var new_messages = []
	for i in range(converted_scenes.size()):
		var scene_data = converted_scenes[i]
		var message = ""
		if scene_data.speaker_name.is_empty():
			message = scene_data.text
		else:
			message = "%s: %s" % [scene_data.speaker_name, scene_data.text]
		new_messages.append(message)
		print("  [%d] %s" % [i, message])
	
	# test_messagesを置き換え
	print("SimpleWorkingText: test_messages置き換え実行...")
	var old_count = test_messages.size()
	test_messages = new_messages
	print("✅ SimpleWorkingText: マークダウンシナリオ読み込み成功完了!")
	print("  置き換え前: %d メッセージ → 置き換え後: %d メッセージ" % [old_count, test_messages.size()])

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