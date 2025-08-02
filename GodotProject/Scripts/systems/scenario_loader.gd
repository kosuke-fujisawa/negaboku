class_name ScenarioLoader
extends RefCounted

# シナリオデータ構造
class ScenarioData:
	var file_path: String = ""
	var title: String = ""
	var scenes: Array[SceneBlock] = []
	var metadata: Dictionary = {}
	
	func _init(p_file_path: String = "", p_title: String = ""):
		file_path = p_file_path
		title = p_title

class SceneBlock:
	var block_id: String = ""
	var commands: Array[MarkdownParser.ParsedElement] = []
	var text_elements: Array[MarkdownParser.ParsedElement] = []
	var metadata: Dictionary = {}
	
	func _init(p_block_id: String = ""):
		block_id = p_block_id
	
	func add_element(element: MarkdownParser.ParsedElement):
		"""要素をシーンブロックに追加"""
		match element.type:
			MarkdownParser.ParsedElement.Type.COMMAND:
				commands.append(element)
			MarkdownParser.ParsedElement.Type.SPEAKER, MarkdownParser.ParsedElement.Type.TEXT:
				text_elements.append(element)
	
	func get_all_elements() -> Array[MarkdownParser.ParsedElement]:
		"""すべての要素を順序通りに取得"""
		var all_elements: Array[MarkdownParser.ParsedElement] = []
		all_elements.append_array(commands)
		all_elements.append_array(text_elements)
		return all_elements

# パーサーインスタンス
var markdown_parser: MarkdownParser

# 読み込み済みシナリオキャッシュ
var loaded_scenarios: Dictionary = {}

func _init():
	markdown_parser = MarkdownParser.new()

func load_scenario_file(file_path: String) -> ScenarioData:
	"""マークダウンシナリオファイルを読み込み"""
	# キャッシュチェック
	if loaded_scenarios.has(file_path):
		print("キャッシュからシナリオを取得: %s" % file_path)
		return loaded_scenarios[file_path]
	
	print("シナリオファイル読み込み開始: %s" % file_path)
	
	# マークダウン解析
	var parsed_elements = markdown_parser.parse_markdown_file(file_path)
	if parsed_elements.is_empty():
		print("エラー: シナリオファイルの解析に失敗: %s" % file_path)
		return null
	
	# 構文検証
	var validation = markdown_parser.validate_syntax(parsed_elements)
	if not validation.is_valid:
		print("エラー: シナリオファイルの構文エラー:")
		for error in validation.errors:
			print("  - %s" % error)
		return null
	
	# 警告表示
	if validation.warnings.size() > 0:
		print("警告: シナリオファイルの警告:")
		for warning in validation.warnings:
			print("  - %s" % warning)
	
	# シナリオデータ構築
	var scenario_data = ScenarioData.new(file_path, _extract_title_from_path(file_path))
	_build_scenario_blocks(parsed_elements, scenario_data)
	
	# キャッシュに保存
	loaded_scenarios[file_path] = scenario_data
	
	print("シナリオ読み込み完了: %d ブロック" % scenario_data.scenes.size())
	return scenario_data

func _extract_title_from_path(file_path: String) -> String:
	"""ファイルパスからタイトルを抽出"""
	var file_name = file_path.get_file()
	var title = file_name.get_basename()
	return title.capitalize()

func _build_scenario_blocks(parsed_elements: Array[MarkdownParser.ParsedElement], scenario_data: ScenarioData):
	"""解析済み要素からシーンブロックを構築"""
	var current_block: SceneBlock = null
	var block_counter = 0
	
	for element in parsed_elements:
		# セパレーターで新しいブロックを開始
		if element.type == MarkdownParser.ParsedElement.Type.SEPARATOR:
			if current_block != null:
				scenario_data.scenes.append(current_block)
			
			block_counter += 1
			current_block = SceneBlock.new("block_%d" % block_counter)
			continue
		
		# 最初のブロックを作成
		if current_block == null:
			block_counter += 1
			current_block = SceneBlock.new("block_%d" % block_counter)
		
		# 要素をブロックに追加
		current_block.add_element(element)
	
	# 最後のブロックを追加
	if current_block != null:
		scenario_data.scenes.append(current_block)

func load_multiple_scenarios(file_paths: Array[String]) -> Dictionary:
	"""複数のシナリオファイルを読み込み"""
	var loaded_scenarios_dict = {}
	
	for file_path in file_paths:
		var scenario_data = load_scenario_file(file_path)
		if scenario_data != null:
			loaded_scenarios_dict[file_path] = scenario_data
		else:
			print("警告: シナリオ読み込み失敗をスキップ: %s" % file_path)
	
	print("複数シナリオ読み込み完了: %d/%d ファイル" % [loaded_scenarios_dict.size(), file_paths.size()])
	return loaded_scenarios_dict

func get_scenario_list(scenarios_directory: String = "res://Assets/scenarios/") -> Array[String]:
	"""シナリオディレクトリからファイルリストを取得"""
	var scenario_files: Array[String] = []
	
	# ディレクトリ存在チェック
	if not DirAccess.dir_exists_absolute(scenarios_directory):
		print("警告: シナリオディレクトリが存在しません: %s" % scenarios_directory)
		return scenario_files
	
	# ディレクトリスキャン
	var dir = DirAccess.open(scenarios_directory)
	if dir == null:
		print("エラー: シナリオディレクトリを開けません: %s" % scenarios_directory)
		return scenario_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".md"):
			var full_path = scenarios_directory + file_name
			scenario_files.append(full_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# ファイル名でソート
	scenario_files.sort()
	
	print("シナリオファイル発見: %d ファイル" % scenario_files.size())
	return scenario_files

func convert_to_text_scene_data(scenario_data: ScenarioData) -> Array[TextSceneManager.SceneData]:
	"""ScenarioDataをTextSceneManager.SceneDataに変換"""
	var scene_data_array: Array[TextSceneManager.SceneData] = []
	
	if scenario_data == null:
		return scene_data_array
	
	for block_index in range(scenario_data.scenes.size()):
		var scene_block = scenario_data.scenes[block_index]
		var converted_scenes = _convert_block_to_scene_data(scene_block, block_index)
		scene_data_array.append_array(converted_scenes)
	
	print("シーンデータ変換完了: %d シーン" % scene_data_array.size())
	return scene_data_array

func _convert_block_to_scene_data(scene_block: SceneBlock, block_index: int) -> Array[TextSceneManager.SceneData]:
	"""シーンブロックをTextSceneManager.SceneDataに変換"""
	var scene_data_array: Array[TextSceneManager.SceneData] = []
	
	# ブロック内のコマンドを解析して状態を保持
	var current_background = ""
	var current_character_left = ""
	var current_character_right = ""
	
	# コマンド処理
	for command in scene_block.commands:
		match command.content:
			"bg":
				if command.parameters.has("storage"):
					current_background = _resolve_asset_path(command.parameters["storage"])
			"chara_show":
				if command.parameters.has("name") and command.parameters.has("pos"):
					var character_path = _resolve_character_path(command.parameters["name"], command.parameters.get("face", "normal"))
					match command.parameters["pos"]:
						"left":
							current_character_left = character_path
						"right":
							current_character_right = character_path
			"chara_hide":
				if command.parameters.has("name"):
					# TODO: 将来的により細かい制御を実装
					pass
	
	# テキスト要素をシーンデータに変換
	for text_index in range(scene_block.text_elements.size()):
		var text_element = scene_block.text_elements[text_index]
		var scene_id = "%s_%d" % [scene_block.block_id, text_index]
		
		var speaker_name = ""
		var text_content = ""
		
		match text_element.type:
			MarkdownParser.ParsedElement.Type.SPEAKER:
				speaker_name = text_element.speaker
				text_content = text_element.content
			MarkdownParser.ParsedElement.Type.TEXT:
				text_content = text_element.content
		
		var scene_data = TextSceneManager.SceneData.new(
			scene_id,
			current_background,
			current_character_left,
			current_character_right,
			speaker_name,
			text_content
		)
		
		scene_data_array.append(scene_data)
	
	return scene_data_array

func _resolve_asset_path(asset_name: String) -> String:
	"""アセット名をフルパスに解決"""
	if asset_name.is_empty():
		return ""
	
	# 既にフルパスの場合はそのまま返す
	if asset_name.begins_with("res://"):
		return asset_name
	
	# 背景画像のデフォルトパス
	var full_path = "res://Assets/images/backgrounds/" + asset_name
	
	# ファイル存在確認
	if ResourceLoader.exists(full_path):
		return full_path
	else:
		print("警告: 背景ファイルが見つかりません: %s" % full_path)
		return ""

func _resolve_character_path(character_name: String, face_expression: String = "normal") -> String:
	"""キャラクター名と表情からパスを解決"""
	if character_name.is_empty():
		return ""
	
	# キャラクター画像のデフォルトパス
	var full_path = "res://Assets/images/characters/%s_%s.png" % [character_name.to_lower(), face_expression]
	
	# ファイル存在確認
	if ResourceLoader.exists(full_path):
		return full_path
	else:
		# フォールバック: 通常表情
		var fallback_path = "res://Assets/images/characters/%s_normal.png" % character_name.to_lower()
		if ResourceLoader.exists(fallback_path):
			print("警告: 表情ファイルが見つからないためノーマル表情を使用: %s -> %s" % [full_path, fallback_path])
			return fallback_path
		else:
			print("警告: キャラクターファイルが見つかりません: %s" % full_path)
			return ""

func clear_cache():
	"""シナリオキャッシュをクリア"""
	loaded_scenarios.clear()
	print("シナリオキャッシュをクリア")

func get_scenario_metadata(file_path: String) -> Dictionary:
	"""シナリオのメタデータを取得"""
	var scenario_data = load_scenario_file(file_path)
	if scenario_data == null:
		return {}
	
	return {
		"title": scenario_data.title,
		"file_path": scenario_data.file_path,
		"scene_count": scenario_data.scenes.size(),
		"total_text_elements": _count_total_text_elements(scenario_data)
	}

func _count_total_text_elements(scenario_data: ScenarioData) -> int:
	"""シナリオ内の総テキスト要素数をカウント"""
	var total_count = 0
	for scene_block in scenario_data.scenes:
		total_count += scene_block.text_elements.size()
	return total_count

# デバッグ・テスト用ユーティリティ
func print_scenario_info(scenario_data: ScenarioData):
	"""シナリオ情報をデバッグ出力"""
	if scenario_data == null:
		print("エラー: シナリオデータがnull")
		return
	
	print("=== シナリオ情報 ===")
	print("タイトル: %s" % scenario_data.title)
	print("ファイルパス: %s" % scenario_data.file_path)
	print("ブロック数: %d" % scenario_data.scenes.size())
	
	for i in range(scenario_data.scenes.size()):
		var block = scenario_data.scenes[i]
		print("  ブロック[%d] %s: コマンド=%d, テキスト=%d" % [
			i, block.block_id, block.commands.size(), block.text_elements.size()
		])

func test_scenario_loading(file_path: String):
	"""シナリオ読み込みテスト"""
	print("=== シナリオ読み込みテスト ===")
	print("ファイル: %s" % file_path)
	
	var scenario_data = load_scenario_file(file_path)
	if scenario_data == null:
		print("テスト失敗: シナリオ読み込み不可")
		return
	
	print_scenario_info(scenario_data)
	
	# TextSceneManager形式に変換テスト
	var converted_scenes = convert_to_text_scene_data(scenario_data)
	print("変換結果: %d シーン" % converted_scenes.size())
	
	for i in range(min(3, converted_scenes.size())):  # 最初の3シーンのみ表示
		var scene = converted_scenes[i]
		print("  シーン[%d] %s: %s「%s」" % [i, scene.scene_id, scene.speaker_name, scene.text])