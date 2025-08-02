class_name TextSceneManager
extends Node

signal scene_finished
signal choice_made(choice_index: int)

# シーンデータ構造
class SceneData:
	var background_path: String = ""
	var character_left_path: String = ""
	var character_right_path: String = ""
	var speaker_name: String = ""
	var text: String = ""
	var choices: Array[String] = []
	var scene_id: String = ""
	
	func _init(p_scene_id: String = "", p_background: String = "", p_left: String = "", p_right: String = "", p_speaker: String = "", p_text: String = "", p_choices: Array[String] = []):
		scene_id = p_scene_id
		background_path = p_background
		character_left_path = p_left
		character_right_path = p_right
		speaker_name = p_speaker
		text = p_text
		choices = p_choices.duplicate()

# 現在の状態
var current_scene_data: SceneData
var text_scene: TextScene
var is_waiting_for_input: bool = false

# シナリオデータ（サンプル）
var scenario_data: Array[SceneData] = []
var current_scene_index: int = 0

func _ready():
	_load_sample_scenario()

func _load_sample_scenario():
	"""サンプルシナリオデータを読み込み"""
	scenario_data = [
		SceneData.new("scene_01", "", "", "", "ナレーション", "物語が始まります..."),
		SceneData.new("scene_02", "", "", "", "ソウマ", "こんにちは！僕の名前はソウマです。"),
		SceneData.new("scene_03", "", "", "", "ユズキ", "私はユズキ。よろしくお願いします。"),
		SceneData.new("scene_04", "", "", "", "ソウマ", "学校に到着しました。今日はどうしましょうか？", ["教室に向かう", "屋上に行く", "図書館に行く"])
	]

func initialize_with_scene(scene: TextScene):
	"""テキストシーンと連携を初期化"""
	text_scene = scene
	text_scene.text_finished.connect(_on_text_finished)
	text_scene.choice_selected.connect(_on_choice_selected)
	
	# 最初のシーンを表示
	current_scene_index = 0
	if scenario_data.size() > 0:
		_display_current_scene()

func _display_current_scene():
	"""現在のシーンを表示"""
	if current_scene_index >= scenario_data.size():
		_finish_scenario()
		return
	
	current_scene_data = scenario_data[current_scene_index]
	
	# 背景設定
	if not current_scene_data.background_path.is_empty():
		text_scene.set_background(current_scene_data.background_path)
	
	# 立ち絵設定
	text_scene.set_character_portrait("left", current_scene_data.character_left_path)
	text_scene.set_character_portrait("right", current_scene_data.character_right_path)
	
	# テキスト表示
	text_scene.show_text(current_scene_data.speaker_name, current_scene_data.text)
	
	is_waiting_for_input = true
	print("シーン表示: %s" % current_scene_data.scene_id)

func _on_text_finished():
	"""テキスト表示完了時の処理"""
	if not is_waiting_for_input:
		return
	
	is_waiting_for_input = false
	
	# 選択肢がある場合
	if current_scene_data.choices.size() > 0:
		_show_choices()
	else:
		# 次のシーンへ進む
		_advance_to_next_scene()

func _show_choices():
	"""選択肢を表示"""
	print("選択肢表示: %s" % current_scene_data.choices)
	# TODO: 選択肢UIの実装
	# 現在はデバッグ用に最初の選択肢を自動選択
	_on_choice_selected(0)

func _on_choice_selected(choice_index: int):
	"""選択肢選択時の処理"""
	if choice_index < 0 or choice_index >= current_scene_data.choices.size():
		print("不正な選択肢インデックス: %d" % choice_index)
		return
	
	var selected_choice = current_scene_data.choices[choice_index]
	print("選択肢選択: %s" % selected_choice)
	
	choice_made.emit(choice_index)
	
	# 選択に応じた次のシーンへ
	_advance_to_next_scene()

func _advance_to_next_scene():
	"""次のシーンへ進む"""
	current_scene_index += 1
	_display_current_scene()

func _finish_scenario():
	"""シナリオ終了処理"""
	print("シナリオ終了")
	scene_finished.emit()
	
	# メインシーンに戻る（または他の処理）
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

# 外部からのシーン制御API
func load_scenario_from_file(file_path: String):
	"""外部ファイルからシナリオを読み込み"""
	# TODO: JSONやCSVからのシナリオ読み込み実装
	print("シナリオファイル読み込み: %s" % file_path)

func jump_to_scene(scene_id: String):
	"""指定されたシーンIDにジャンプ"""
	for i in range(scenario_data.size()):
		if scenario_data[i].scene_id == scene_id:
			current_scene_index = i
			_display_current_scene()
			return
	
	print("シーンIDが見つかりません: %s" % scene_id)

func set_background(background_path: String):
	"""現在のシーンの背景を変更"""
	if text_scene:
		text_scene.set_background(background_path)

func set_character(position: String, character_path: String):
	"""現在のシーンの立ち絵を変更"""
	if text_scene:
		text_scene.set_character_portrait(position, character_path)

func show_message(speaker: String, message: String):
	"""即座にメッセージを表示"""
	if text_scene:
		text_scene.show_text(speaker, message)

func get_current_scene_id() -> String:
	"""現在のシーンIDを取得"""
	if current_scene_data:
		return current_scene_data.scene_id
	return ""

func get_text_history() -> Array[Dictionary]:
	"""テキスト履歴を取得"""
	if text_scene:
		return text_scene.get_log_history()
	return []