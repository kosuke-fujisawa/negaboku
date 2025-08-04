class_name MarkdownSequenceController
extends Node

# シーケンシャル実行制御システム
# マークダウンファイルを上から順に読み込み、コマンドとテキストを順次処理

signal sequence_completed
signal command_executed(command_name: String, parameters: Dictionary)
signal text_displayed(speaker: String, text: String)
signal sequence_paused
signal sequence_resumed

# 実行状態
enum State {
	IDLE,           # 待機中
	LOADING,        # ファイル読み込み中
	EXECUTING,      # 順次実行中
	PAUSED,         # 一時停止
	COMPLETED       # 実行完了
}

var current_state: State = State.IDLE
var current_elements: Array[MarkdownParser.ParsedElement] = []
var current_element_index: int = 0
var is_auto_advance: bool = false

# システム参照
var markdown_parser: MarkdownParser
var scene_command_executor: SceneCommandExecutor
var text_scene: Control

# 背景・キャラクター状態管理
var current_background: String = ""
var current_character_left: String = ""
var current_character_right: String = ""

# 実行設定
var command_execution_delay: float = 0.5  # コマンド間の遅延
var text_advance_mode: String = "manual"  # "manual" or "auto"
var auto_advance_delay: float = 2.0       # 自動進行時の遅延

func _init():
	name = "MarkdownSequenceController"
	markdown_parser = MarkdownParser.new()
	scene_command_executor = SceneCommandExecutor.new()
	add_child(scene_command_executor)

func initialize(target_text_scene: Control):
	# テキストシーンとの連携を初期化# 
	text_scene = target_text_scene
	scene_command_executor.initialize(text_scene)
	
	# SceneCommandExecutorのシグナル接続
	scene_command_executor.command_executed.connect(_on_command_executed)
	scene_command_executor.background_changed.connect(_on_background_changed)
	scene_command_executor.character_shown.connect(_on_character_shown)
	scene_command_executor.character_hidden.connect(_on_character_hidden)
	
	print("MarkdownSequenceController: 初期化完了")

func load_and_execute_markdown_file(file_path: String):
	# マークダウンファイルを読み込み、順次実行を開始# 
	if current_state != State.IDLE:
		print("警告: 既に実行中または処理中です")
		return
	
	print("MarkdownSequenceController: ファイル読み込み開始 - %s" % file_path)
	current_state = State.LOADING
	
	# マークダウンファイルを解析
	current_elements = markdown_parser.parse_markdown_file(file_path)
	
	if current_elements.is_empty():
		print("エラー: マークダウン解析に失敗")
		current_state = State.IDLE
		return
	
	# 構文検証
	var validation = markdown_parser.validate_syntax(current_elements)
	if not validation.is_valid:
		print("エラー: マークダウン構文エラー")
		for error in validation.errors:
			print("  - %s" % error)
		current_state = State.IDLE
		return
	
	print("マークダウン解析完了: %d 要素" % current_elements.size())
	
	# 順次実行開始
	current_element_index = 0
	current_state = State.EXECUTING
	_execute_next_element()

func _execute_next_element():
	# 次の要素を実行# 
	if current_state != State.EXECUTING:
		return
	
	# 実行完了チェック
	if current_element_index >= current_elements.size():
		_complete_sequence()
		return
	
	var element = current_elements[current_element_index]
	print("要素実行 [%d/%d]: %s" % [current_element_index + 1, current_elements.size(), _element_to_string(element)])
	
	match element.type:
		MarkdownParser.ParsedElement.Type.COMMAND:
			await _execute_command_element(element)
		MarkdownParser.ParsedElement.Type.SPEAKER:
			await _execute_speaker_element(element)
		MarkdownParser.ParsedElement.Type.TEXT:
			await _execute_text_element(element)
		MarkdownParser.ParsedElement.Type.SEPARATOR:
			await _execute_separator_element(element)
	
	# 次の要素へ進む
	current_element_index += 1
	
	# 遅延後に次の要素を実行
	if current_state == State.EXECUTING:
		if element.type == MarkdownParser.ParsedElement.Type.COMMAND:
			await get_tree().create_timer(command_execution_delay).timeout
		
		_execute_next_element()

func _execute_command_element(element: MarkdownParser.ParsedElement):
	# コマンド要素を実行# 
	var result = scene_command_executor.execute_command(element)
	
	# 成功したコマンドの状態を記録
	if result.status == SceneCommandExecutor.CommandResult.Status.SUCCESS:
		match element.content:
			"bg":
				if element.parameters.has("storage"):
					current_background = element.parameters["storage"]
			"chara_show":
				if element.parameters.has("name") and element.parameters.has("pos"):
					var pos = element.parameters["pos"]
					var character_name = element.parameters["name"]
					if pos == "left":
						current_character_left = character_name
					elif pos == "right":
						current_character_right = character_name
			"chara_hide":
				if element.parameters.has("name"):
					var character_name = element.parameters["name"]
					# 該当キャラクターを非表示にする
					if current_character_left == character_name:
						current_character_left = ""
					if current_character_right == character_name:
						current_character_right = ""
	
	command_executed.emit(element.content, element.parameters)
	
	# 非同期コマンドの完了を待つ
	if result.status == SceneCommandExecutor.CommandResult.Status.PENDING:
		match element.content:
			"bg":
				await scene_command_executor.background_changed
			"chara_show":
				await scene_command_executor.character_shown
			"chara_hide":
				await scene_command_executor.character_hidden
			"wait":
				await scene_command_executor.wait_completed

func _execute_speaker_element(element: MarkdownParser.ParsedElement):
	# スピーカー要素を実行# 
	if text_scene and text_scene.has_method("show_text"):
		text_scene.show_text(element.speaker, element.content)
		text_displayed.emit(element.speaker, element.content)
		
		# テキスト進行モードに応じて待機
		if text_advance_mode == "manual":
			# 手動進行: ユーザー入力を待つ
			await _wait_for_user_input()
		elif text_advance_mode == "auto":
			# 自動進行: 指定時間待機
			await get_tree().create_timer(auto_advance_delay).timeout

func _execute_text_element(element: MarkdownParser.ParsedElement):
	# テキスト要素を実行（地の文など）# 
	if text_scene and text_scene.has_method("show_text"):
		text_scene.show_text("", element.content)  # スピーカー名なし
		text_displayed.emit("", element.content)
		
		# テキスト進行モードに応じて待機
		if text_advance_mode == "manual":
			await _wait_for_user_input()
		elif text_advance_mode == "auto":
			await get_tree().create_timer(auto_advance_delay).timeout

func _execute_separator_element(element: MarkdownParser.ParsedElement):
	# セパレーター要素を実行# 
	# セパレーターは区切りなので、短い遅延のみ
	await get_tree().create_timer(0.2).timeout

func _wait_for_user_input():
	# ユーザー入力待機# 
	# テキストシーンからのtext_finishedシグナルを待つ
	if text_scene and text_scene.has_signal("text_finished"):
		await text_scene.text_finished

func _complete_sequence():
	# シーケンス実行完了# 
	current_state = State.COMPLETED
	print("MarkdownSequenceController: シーケンス実行完了")
	sequence_completed.emit()

func _on_command_executed(command_name: String, result):
	# コマンド実行完了時の処理# 
	print("コマンド実行完了: %s" % command_name)

func _on_background_changed(texture_path: String):
	# 背景変更完了時の処理# 
	print("背景変更完了: %s" % texture_path)

func _on_character_shown(name: String, position: String, face: String):
	# キャラクター表示完了時の処理# 
	print("キャラクター表示完了: %s (%s, %s)" % [name, face, position])

func _on_character_hidden(name: String):
	# キャラクター非表示完了時の処理# 
	print("キャラクター非表示完了: %s" % name)

# 制御メソッド

func pause_sequence():
	# シーケンス実行を一時停止# 
	if current_state == State.EXECUTING:
		current_state = State.PAUSED
		sequence_paused.emit()
		print("シーケンス一時停止")

func resume_sequence():
	# シーケンス実行を再開# 
	if current_state == State.PAUSED:
		current_state = State.EXECUTING
		sequence_resumed.emit()
		print("シーケンス再開")
		_execute_next_element()

func stop_sequence():
	# シーケンス実行を停止# 
	current_state = State.IDLE
	current_element_index = 0
	current_elements.clear()
	scene_command_executor.stop_execution()
	print("シーケンス停止")

func set_text_advance_mode(mode: String):
	# テキスト進行モードを設定 ("manual" or "auto")# 
	if mode in ["manual", "auto"]:
		text_advance_mode = mode
		print("テキスト進行モード: %s" % mode)

func set_auto_advance_delay(delay: float):
	# 自動進行時の遅延時間を設定# 
	auto_advance_delay = max(0.5, delay)
	print("自動進行遅延: %.1f秒" % auto_advance_delay)

func set_command_execution_delay(delay: float):
	# コマンド実行間の遅延時間を設定# 
	command_execution_delay = max(0.0, delay)
	print("コマンド実行遅延: %.1f秒" % command_execution_delay)

# 状態取得メソッド

func get_current_state() -> State:
	# 現在の実行状態を取得# 
	return current_state

func get_progress() -> Dictionary:
	# 実行進捗を取得# 
	return {
		"current_index": current_element_index,
		"total_elements": current_elements.size(),
		"progress_percent": (float(current_element_index) / float(current_elements.size())) * 100.0 if current_elements.size() > 0 else 0.0
	}

func get_current_scene_state() -> Dictionary:
	# 現在のシーン状態を取得# 
	return {
		"background": current_background,
		"character_left": current_character_left,
		"character_right": current_character_right
	}

# ユーティリティメソッド

func _element_to_string(element: MarkdownParser.ParsedElement) -> String:
	# 要素を文字列表現に変換# 
	match element.type:
		MarkdownParser.ParsedElement.Type.COMMAND:
			return "COMMAND: %s %s" % [element.content, element.parameters]
		MarkdownParser.ParsedElement.Type.SPEAKER:
			return "SPEAKER: %s「%s」" % [element.speaker, element.content]
		MarkdownParser.ParsedElement.Type.TEXT:
			return "TEXT: %s" % element.content
		MarkdownParser.ParsedElement.Type.SEPARATOR:
			return "SEPARATOR"
		_:
			return "UNKNOWN"

# デバッグ機能

func debug_print_sequence():
	# シーケンス内容をデバッグ出力# 
	print("=== シーケンス内容 (%d要素) ===" % current_elements.size())
	for i in range(current_elements.size()):
		var element = current_elements[i]
		var prefix = "-> " if i == current_element_index else "   "
		print("%s[%d] %s" % [prefix, i, _element_to_string(element)])

func debug_print_state():
	# 現在の状態をデバッグ出力# 
	print("=== 実行状態 ===")
	print("State: %s" % _state_to_string(current_state))
	print("Progress: %d/%d (%.1f%%)" % [current_element_index, current_elements.size(), get_progress().progress_percent])
	print("Scene State: %s" % get_current_scene_state())

func _state_to_string(state: State) -> String:
	# 状態を文字列に変換# 
	match state:
		State.IDLE:
			return "IDLE"
		State.LOADING:
			return "LOADING"
		State.EXECUTING:
			return "EXECUTING"
		State.PAUSED:
			return "PAUSED"
		State.COMPLETED:
			return "COMPLETED"
		_:
			return "UNKNOWN"