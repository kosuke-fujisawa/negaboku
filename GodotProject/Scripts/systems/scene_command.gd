class_name SceneCommandExecutor
extends Node

# コマンド実行結果
class CommandResult:
	enum Status {
		SUCCESS,    # 成功
		FAILED,     # 失敗
		PENDING,    # 実行中（非同期）
		SKIPPED     # スキップ
	}
	
	var status: Status
	var message: String = ""
	var execution_time: float = 0.0
	
	func _init(p_status: Status, p_message: String = ""):
		status = p_status
		message = p_message

# Signal定義
signal command_executed(command_name: String, result: CommandResult)
signal background_changed(texture_path: String)
signal character_shown(name: String, position: String, face: String)
signal character_hidden(name: String)
signal wait_completed()

# 実行状態管理
var is_executing: bool = false
var current_text_scene: Control = null
var command_queue: Array[MarkdownParser.ParsedElement] = []
var execution_delay: float = 0.1  # コマンド間の遅延

# アニメーション設定
var background_transition_time: float = 0.5
var character_transition_time: float = 0.3

func initialize(text_scene: Control):
	"""テキストシーンとの連携を初期化"""
	current_text_scene = text_scene
	print("SceneCommandExecutor初期化完了")

func execute_command(command: MarkdownParser.ParsedElement) -> CommandResult:
	"""単一コマンドを実行"""
	if command.type != MarkdownParser.ParsedElement.Type.COMMAND:
		return CommandResult.new(CommandResult.Status.SKIPPED, "コマンド要素ではありません")
	
	var start_time = Time.get_time_dict_from_system()
	var result: CommandResult = null
	
	match command.content:
		"bg":
			result = _execute_bg_command(command)
		"chara_show":
			result = _execute_chara_show_command(command)
		"chara_hide":
			result = _execute_chara_hide_command(command)
		"wait":
			result = _execute_wait_command(command)
		"choice":
			result = _execute_choice_command(command)
		_:
			result = CommandResult.new(CommandResult.Status.FAILED, "未知のコマンド: %s" % command.content)
	
	# 実行時間計算
	var end_time = Time.get_time_dict_from_system()
	result.execution_time = _calculate_time_diff(start_time, end_time)
	
	# Signal発信
	command_executed.emit(command.content, result)
	
	print("コマンド実行: %s -> %s (%s)" % [command.content, _status_to_string(result.status), result.message])
	return result

func execute_command_sequence(commands: Array[MarkdownParser.ParsedElement]) -> void:
	"""コマンドシーケンスを順次実行"""
	if is_executing:
		print("警告: 既にコマンド実行中です")
		return
	
	command_queue = commands.duplicate()
	is_executing = true
	
	print("コマンドシーケンス実行開始: %d コマンド" % command_queue.size())
	_process_command_queue()

func _process_command_queue():
	"""コマンドキューを処理"""
	if command_queue.is_empty():
		is_executing = false
		print("コマンドシーケンス実行完了")
		return
	
	var command = command_queue.pop_front()
	var result = execute_command(command)
	
	# 非同期コマンドの場合は完了を待つ
	if result.status == CommandResult.Status.PENDING:
		# 特定のコマンドの完了を待つ
		match command.content:
			"wait":
				await wait_completed
			"bg":
				await background_changed
			"chara_show":
				await character_shown
			"chara_hide":
				await character_hidden
	
	# 次のコマンドへ
	if execution_delay > 0:
		await get_tree().create_timer(execution_delay).timeout
	
	_process_command_queue()

func _execute_bg_command(command: MarkdownParser.ParsedElement) -> CommandResult:
	"""背景変更コマンド実行"""
	if not current_text_scene:
		return CommandResult.new(CommandResult.Status.FAILED, "TextSceneが設定されていません")
	
	var storage = command.parameters.get("storage", "")
	if storage.is_empty():
		return CommandResult.new(CommandResult.Status.FAILED, "storageパラメータが必要です")
	
	var time_param = command.parameters.get("time", "")
	var transition_time = background_transition_time
	
	if not time_param.is_empty():
		transition_time = time_param.to_float() / 1000.0  # ミリ秒から秒に変換
	
	# アセットパス解決
	var full_path = _resolve_background_path(storage)
	if full_path.is_empty():
		return CommandResult.new(CommandResult.Status.FAILED, "背景ファイルが見つかりません: %s" % storage)
	
	# 背景設定（非同期）
	_set_background_with_transition(full_path, transition_time)
	
	return CommandResult.new(CommandResult.Status.SUCCESS, "背景変更: %s" % storage)

func _execute_chara_show_command(command: MarkdownParser.ParsedElement) -> CommandResult:
	"""立ち絵表示コマンド実行"""
	if not current_text_scene:
		return CommandResult.new(CommandResult.Status.FAILED, "TextSceneが設定されていません")
	
	var name = command.parameters.get("name", "")
	var face = command.parameters.get("face", "normal")
	var pos = command.parameters.get("pos", "left")
	
	if name.is_empty():
		return CommandResult.new(CommandResult.Status.FAILED, "nameパラメータが必要です")
	
	# ポジション検証
	if pos != "left" and pos != "right":
		return CommandResult.new(CommandResult.Status.FAILED, "posは'left'または'right'である必要があります")
	
	# キャラクターパス解決
	var character_path = _resolve_character_path(name, face)
	if character_path.is_empty():
		return CommandResult.new(CommandResult.Status.FAILED, "キャラクターファイルが見つかりません: %s_%s" % [name, face])
	
	# 立ち絵設定（非同期）
	_set_character_with_transition(pos, character_path, character_transition_time)
	
	# Signal発信
	character_shown.emit(name, pos, face)
	
	return CommandResult.new(CommandResult.Status.SUCCESS, "立ち絵表示: %s (%s, %s)" % [name, face, pos])

func _execute_chara_hide_command(command: MarkdownParser.ParsedElement) -> CommandResult:
	"""立ち絵非表示コマンド実行"""
	if not current_text_scene:
		return CommandResult.new(CommandResult.Status.FAILED, "TextSceneが設定されていません")
	
	var name = command.parameters.get("name", "")
	if name.is_empty():
		return CommandResult.new(CommandResult.Status.FAILED, "nameパラメータが必要です")
	
	# 立ち絵非表示（全ポジション）
	if current_text_scene.has_method("set_character_portrait"):
		current_text_scene.set_character_portrait("left", "")
		current_text_scene.set_character_portrait("right", "")
	
	# Signal発信
	character_hidden.emit(name)
	
	return CommandResult.new(CommandResult.Status.SUCCESS, "立ち絵非表示: %s" % name)

func _execute_wait_command(command: MarkdownParser.ParsedElement) -> CommandResult:
	"""待機コマンド実行"""
	var time_param = command.parameters.get("time", "")
	if time_param.is_empty():
		return CommandResult.new(CommandResult.Status.FAILED, "timeパラメータが必要です")
	
	var wait_time = time_param.to_float() / 1000.0  # ミリ秒から秒に変換
	if wait_time <= 0:
		return CommandResult.new(CommandResult.Status.FAILED, "待機時間は正の値である必要があります")
	
	# 非同期待機
	_execute_wait_async(wait_time)
	
	return CommandResult.new(CommandResult.Status.PENDING, "待機中: %.2f秒" % wait_time)

func _execute_choice_command(command: MarkdownParser.ParsedElement) -> CommandResult:
	"""選択肢コマンド実行（将来実装）"""
	return CommandResult.new(CommandResult.Status.SKIPPED, "選択肢コマンドは未実装です")

func _set_background_with_transition(texture_path: String, transition_time: float):
	"""背景をトランジション付きで設定"""
	if not current_text_scene:
		return
	
	# 即座設定（将来的にフェード効果を追加可能）
	if current_text_scene.has_method("set_background"):
		current_text_scene.set_background(texture_path)
	
	# トランジション時間待機
	if transition_time > 0:
		await get_tree().create_timer(transition_time).timeout
	
	background_changed.emit(texture_path)

func _set_character_with_transition(position: String, character_path: String, transition_time: float):
	"""立ち絵をトランジション付きで設定"""
	if not current_text_scene:
		return
	
	# 即座設定（将来的にフェード効果を追加可能）
	if current_text_scene.has_method("set_character_portrait"):
		current_text_scene.set_character_portrait(position, character_path)
	
	# トランジション時間待機
	if transition_time > 0:
		await get_tree().create_timer(transition_time).timeout

func _execute_wait_async(wait_time: float):
	"""非同期待機実行"""
	await get_tree().create_timer(wait_time).timeout
	wait_completed.emit()

func _resolve_background_path(asset_name: String) -> String:
	"""背景アセット名をフルパスに解決"""
	if asset_name.is_empty():
		return ""
	
	# 既にフルパスの場合
	if asset_name.begins_with("res://"):
		return asset_name
	
	# デフォルトパス
	var full_path = "res://Assets/images/backgrounds/" + asset_name
	
	# ファイル存在確認
	if ResourceLoader.exists(full_path):
		return full_path
	else:
		print("警告: 背景ファイルが見つかりません: %s" % full_path)
		return ""

func _resolve_character_path(character_name: String, face_expression: String) -> String:
	"""キャラクター名と表情からパスを解決"""
	if character_name.is_empty():
		return ""
	
	var full_path = "res://Assets/images/characters/%s_%s.png" % [character_name.to_lower(), face_expression]
	
	# ファイル存在確認
	if ResourceLoader.exists(full_path):
		return full_path
	else:
		# フォールバック: ノーマル表情
		var fallback_path = "res://Assets/images/characters/%s_normal.png" % character_name.to_lower()
		if ResourceLoader.exists(fallback_path):
			print("警告: 表情ファイルが見つからないため通常表情を使用: %s" % fallback_path)
			return fallback_path
		else:
			print("警告: キャラクターファイルが見つかりません: %s" % full_path)
			return ""

func _calculate_time_diff(start_time: Dictionary, end_time: Dictionary) -> float:
	"""時間差を計算（秒）"""
	var start_total = start_time.hour * 3600 + start_time.minute * 60 + start_time.second
	var end_total = end_time.hour * 3600 + end_time.minute * 60 + end_time.second
	return float(end_total - start_total)

func _status_to_string(status: CommandResult.Status) -> String:
	"""ステータスを文字列に変換"""
	match status:
		CommandResult.Status.SUCCESS:
			return "成功"
		CommandResult.Status.FAILED:
			return "失敗"
		CommandResult.Status.PENDING:
			return "実行中"
		CommandResult.Status.SKIPPED:
			return "スキップ"
		_:
			return "不明"

# 外部API
func stop_execution():
	"""コマンド実行を停止"""
	command_queue.clear()
	is_executing = false
	print("コマンド実行を停止")

func is_command_executing() -> bool:
	"""コマンド実行中かどうか"""
	return is_executing

func set_execution_delay(delay: float):
	"""コマンド間の実行遅延を設定"""
	execution_delay = max(0.0, delay)

func set_transition_times(bg_time: float, char_time: float):
	"""トランジション時間を設定"""
	background_transition_time = max(0.0, bg_time)
	character_transition_time = max(0.0, char_time)

# デバッグ・テスト用
func test_command_execution(command_text: String):
	"""コマンド実行テスト"""
	print("=== コマンド実行テスト ===")
	print("コマンド: %s" % command_text)
	
	# 疑似的なコマンド要素を作成
	var fake_element = MarkdownParser.ParsedElement.new(MarkdownParser.ParsedElement.Type.COMMAND)
	
	# 簡易的なコマンド解析
	if command_text.contains("bg"):
		fake_element.content = "bg"
		fake_element.parameters = {"storage": "test_background.jpg"}
	elif command_text.contains("chara_show"):
		fake_element.content = "chara_show"
		fake_element.parameters = {"name": "souma", "face": "normal", "pos": "left"}
	elif command_text.contains("wait"):
		fake_element.content = "wait"
		fake_element.parameters = {"time": "1000"}
	
	var result = execute_command(fake_element)
	print("実行結果: %s - %s" % [_status_to_string(result.status), result.message])