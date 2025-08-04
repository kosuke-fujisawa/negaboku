class_name ScenarioLoader
extends RefCounted

# シナリオデータ構造（型安全版）
class SceneBlock:
	var block_id: String = ""
	var commands: Array[MarkdownParser.ParsedElement] = []
	var text_elements: Array[MarkdownParser.ParsedElement] = []
	var metadata: Dictionary = {}
	
	func _init(p_block_id: String = ""):
		block_id = p_block_id
	
	func add_element(element):
		# 要素をシーンブロックに追加# 
		# 型チェックを緩和
		if element and element.has("type"):
			match element.type:
				0: # COMMAND
					commands.append(element)
				1, 2: # SPEAKER, TEXT
					text_elements.append(element)
	
	func get_all_elements() -> Array:
		# すべての要素を順序通りに取得# 
		var all_elements: Array = []
		all_elements.append_array(commands)
		all_elements.append_array(text_elements)
		return all_elements

class ScenarioData:
	var file_path: String = ""
	var title: String = ""
	var scenes: Array[SceneBlock] = []
	var metadata: Dictionary = {}
	
	func _init(p_file_path: String = "", p_title: String = ""):
		file_path = p_file_path
		title = p_title

# パーサーインスタンス
var markdown_parser: MarkdownParser

# 読み込み済みシナリオキャッシュ
var loaded_scenarios: Dictionary = {}

func _init():
	markdown_parser = MarkdownParser.new()

func load_scenario_file(file_path: String) -> ScenarioData:
	# マークダウンシナリオファイルを読み込み# 
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
	# ファイルパスからタイトルを抽出# 
	var file_name = file_path.get_file()
	var title = file_name.get_basename()
	return title.capitalize()

func _build_scenario_blocks(parsed_elements: Array, scenario_data: ScenarioData):
	# 解析済み要素からシーンブロックを構築# 
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

func load_multiple_scenarios(file_paths: Array) -> Dictionary:
	# 複数のシナリオファイルを読み込み# 
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
	# シナリオディレクトリからファイルリストを取得# 
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

func convert_to_text_scene_data(scenario_data: ScenarioData) -> Array:
	# ScenarioDataをTextSceneManager.SceneDataに変換# 
	var scene_data_array: Array = []
	
	if scenario_data == null:
		return scene_data_array
	
	for block_index in range(scenario_data.scenes.size()):
		var scene_block = scenario_data.scenes[block_index]
		var converted_scenes = _convert_block_to_scene_data(scene_block, block_index)
		scene_data_array.append_array(converted_scenes)
	
	print("シーンデータ変換完了: %d シーン" % scene_data_array.size())
	return scene_data_array

func _convert_block_to_scene_data(scene_block: SceneBlock, block_index: int) -> Array:
	# シーンブロックをTextSceneManager.SceneDataに変換# 
	var scene_data_array: Array = []
	
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
	# アセット名をフルパスに解決# 
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
	# キャラクター名と表情からパスを解決# 
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
	# シナリオキャッシュをクリア# 
	loaded_scenarios.clear()
	print("シナリオキャッシュをクリア")

func force_reload_scenario_file(file_path: String) -> ScenarioData:
	# ファイルを強制的に再読み込み（キャッシュ無視）# 
	print("シナリオファイル強制再読み込み: %s" % file_path)
	
	# キャッシュから削除
	if loaded_scenarios.has(file_path):
		loaded_scenarios.erase(file_path)
	
	# 通常の読み込み処理を実行
	return load_scenario_file(file_path)

func get_scenario_metadata(file_path: String) -> Dictionary:
	# シナリオのメタデータを取得# 
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
	# シナリオ内の総テキスト要素数をカウント# 
	var total_count = 0
	for scene_block in scenario_data.scenes:
		total_count += scene_block.text_elements.size()
	return total_count

# デバッグ・テスト用ユーティリティ
func print_scenario_info(scenario_data: ScenarioData):
	# シナリオ情報をデバッグ出力# 
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

# ===========================================
# Phase 3: 高度なシナリオファイルベース管理機能
# ===========================================

class ScenarioLibrary:
	# シナリオライブラリ管理クラス# 
	var scenarios: Dictionary = {}  # scenario_id -> ScenarioData
	var scenario_dependencies: Dictionary = {}  # scenario_id -> [dependency_ids]
	var scenario_metadata: Dictionary = {}  # scenario_id -> metadata
	var library_path: String = "res://Assets/scenarios/"
	
	func add_scenario(scenario_id: String, scenario_data: ScenarioData, dependencies: Array = []):
		scenarios[scenario_id] = scenario_data
		scenario_dependencies[scenario_id] = dependencies
		scenario_metadata[scenario_id] = {
			"added_time": Time.get_unix_time_from_system(),
			"scene_count": scenario_data.scenes.size(),
			"file_path": scenario_data.file_path
		}
	
	func get_scenario(scenario_id: String) -> ScenarioData:
		return scenarios.get(scenario_id, null)
	
	func get_all_scenario_ids() -> Array:
		return scenarios.keys()
	
	func has_scenario(scenario_id: String) -> bool:
		return scenarios.has(scenario_id)
	
	func remove_scenario(scenario_id: String) -> bool:
		if scenarios.has(scenario_id):
			scenarios.erase(scenario_id)
			scenario_dependencies.erase(scenario_id)
			scenario_metadata.erase(scenario_id)
			return true
		return false

# シナリオライブラリインスタンス
var scenario_library: ScenarioLibrary

func _init():
	markdown_parser = MarkdownParser.new()
	scenario_library = ScenarioLibrary.new()

# 高度なシナリオ管理機能
func load_scenario_library(config_file_path: String = "res://Assets/scenarios/library_config.json") -> bool:
	# シナリオライブラリ設定ファイルを読み込み# 
	print("シナリオライブラリ読み込み開始: %s" % config_file_path)
	
	if not FileAccess.file_exists(config_file_path):
		print("警告: ライブラリ設定ファイルが存在しません: %s" % config_file_path)
		return load_default_scenario_library()
	
	var file = FileAccess.open(config_file_path, FileAccess.READ)
	if file == null:
		print("エラー: ライブラリ設定ファイルを開けません: %s" % config_file_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		print("エラー: ライブラリ設定ファイルのJSON解析失敗: %s" % config_file_path)
		return false
	
	var config = json.data
	if not config is Dictionary:
		print("エラー: ライブラリ設定の形式が不正です")
		return false
	
	# シナリオを順次読み込み
	var scenarios_config = config.get("scenarios", [])
	var success_count = 0
	
	for scenario_config in scenarios_config:
		if _load_scenario_from_config(scenario_config):
			success_count += 1
	
	print("シナリオライブラリ読み込み完了: %d/%d シナリオ" % [success_count, scenarios_config.size()])
	return success_count > 0

func _load_scenario_from_config(config: Dictionary) -> bool:
	# 設定からシナリオを読み込み# 
	var scenario_id = config.get("id", "")
	var file_path = config.get("file", "")
	var dependencies = config.get("dependencies", [])
	
	if scenario_id.is_empty() or file_path.is_empty():
		print("警告: シナリオ設定が不完全です: %s" % config)
		return false
	
	var full_path = scenario_library.library_path + file_path
	var scenario_data = load_scenario_file(full_path)
	
	if scenario_data == null:
		print("エラー: シナリオ読み込み失敗: %s -> %s" % [scenario_id, full_path])
		return false
	
	scenario_library.add_scenario(scenario_id, scenario_data, dependencies)
	print("シナリオ登録: %s (%s)" % [scenario_id, file_path])
	return true

func load_default_scenario_library() -> bool:
	# デフォルトのシナリオライブラリを読み込み# 
	print("デフォルトシナリオライブラリ読み込み")
	
	var default_scenarios = [
		{"id": "prologue", "file": "scene01.md", "dependencies": []},
		{"id": "chapter1", "file": "scene02.md", "dependencies": ["prologue"]},
		{"id": "test_scenario", "file": "phase2_test.md", "dependencies": []}
	]
	
	var success_count = 0
	for config in default_scenarios:
		if _load_scenario_from_config(config):
			success_count += 1
	
	print("デフォルトライブラリ読み込み完了: %d シナリオ" % success_count)
	return success_count > 0

func get_scenario_from_library(scenario_id: String) -> ScenarioData:
	# ライブラリからシナリオを取得# 
	return scenario_library.get_scenario(scenario_id)

func get_available_scenarios_from_library() -> Array:
	# ライブラリから利用可能なシナリオIDリストを取得# 
	return scenario_library.get_all_scenario_ids()

func check_scenario_dependencies(scenario_id: String) -> Array:
	# シナリオの依存関係をチェック# 
	return scenario_library.scenario_dependencies.get(scenario_id, [])

func can_load_scenario(scenario_id: String, completed_scenarios: Array = []) -> bool:
	# シナリオが読み込み可能かチェック（依存関係考慮）# 
	var dependencies = check_scenario_dependencies(scenario_id)
	
	for dependency in dependencies:
		if not dependency in completed_scenarios:
			print("依存関係未満足: %s には %s が必要" % [scenario_id, dependency])
			return false
	
	return true

# 複数シーンファイル管理機能
func load_scenario_sequence(scenario_ids: Array) -> Dictionary:
	# シナリオシーケンスを読み込み（順序保持）# 
	print("シナリオシーケンス読み込み: %s" % scenario_ids)
	
	var sequence_data = {}
	var all_scenes = []
	var scene_to_scenario_map = {}
	
	for scenario_id in scenario_ids:
		var scenario_data = get_scenario_from_library(scenario_id)
		if scenario_data == null:
			print("警告: シナリオが見つかりません: %s" % scenario_id)
			continue
		
		# シーンデータを変換して追加
		var converted_scenes = convert_to_text_scene_data(scenario_data)
		for scene in converted_scenes:
			# シーンIDにシナリオIDプレフィックスを追加
			var prefixed_scene_id = "%s_%s" % [scenario_id, scene.scene_id]
			scene.scene_id = prefixed_scene_id
			all_scenes.append(scene)
			scene_to_scenario_map[prefixed_scene_id] = scenario_id
		
		sequence_data[scenario_id] = {
			"scenario_data": scenario_data,
			"scene_count": converted_scenes.size()
		}
	
	print("シナリオシーケンス読み込み完了: %d シナリオ, %d シーン" % [sequence_data.size(), all_scenes.size()])
	
	return {
		"scenarios": sequence_data,
		"all_scenes": all_scenes,
		"scene_to_scenario_map": scene_to_scenario_map
	}

func create_scenario_collection(collection_name: String, scenario_ids: Array) -> Dictionary:
	# シナリオコレクションを作成# 
	print("シナリオコレクション作成: %s -> %s" % [collection_name, scenario_ids])
	
	var collection = {
		"name": collection_name,
		"scenarios": {},
		"total_scenes": 0,
		"creation_time": Time.get_unix_time_from_system()
	}
	
	for scenario_id in scenario_ids:
		var scenario_data = get_scenario_from_library(scenario_id)
		if scenario_data != null:
			collection["scenarios"][scenario_id] = scenario_data
			collection["total_scenes"] += scenario_data.scenes.size()
		else:
			print("警告: コレクションに追加できません: %s" % scenario_id)
	
	print("シナリオコレクション作成完了: %s (%d シナリオ)" % [collection_name, collection["scenarios"].size()])
	return collection

# シーン間ジャンプ機能
func create_scene_transition_map(scenario_data: ScenarioData) -> Dictionary:
	# シーン遷移マップを作成# 
	var transition_map = {}
	var scenes = scenario_data.scenes
	
	for i in range(scenes.size()):
		var scene_block = scenes[i]
		var scene_id = scene_block.block_id
		
		# 次のシーンを設定
		var next_scenes = []
		if i + 1 < scenes.size():
			next_scenes.append(scenes[i + 1].block_id)
		
		# 選択肢による分岐を解析（将来実装）
		# TODO: コマンド内の選択肢分析により分岐先を特定
		
		transition_map[scene_id] = {
			"next_scenes": next_scenes,
			"previous_scene": scenes[i - 1].block_id if i > 0 else "",
			"scene_index": i
		}
	
	return transition_map

func find_scene_by_id(scenario_data: ScenarioData, scene_id: String) -> SceneBlock:
	# シーンIDでシーンブロックを検索# 
	for scene_block in scenario_data.scenes:
		if scene_block.block_id == scene_id:
			return scene_block
	return null

func get_scene_jump_targets(scenario_data: ScenarioData, current_scene_id: String) -> Array:
	# 現在のシーンからジャンプ可能なシーンIDリストを取得# 
	var transition_map = create_scene_transition_map(scenario_data)
	var current_info = transition_map.get(current_scene_id, {})
	return current_info.get("next_scenes", [])

# デバッグ・テスト機能
func test_scenario_loading(file_path: String):
	# シナリオ読み込みテスト# 
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

func test_scenario_library():
	# シナリオライブラリテスト# 
	print("=== シナリオライブラリテスト ===")
	
	# デフォルトライブラリ読み込み
	load_default_scenario_library()
	
	# 利用可能シナリオ表示
	var available_scenarios = get_available_scenarios_from_library()
	print("利用可能シナリオ: %s" % available_scenarios)
	
	# シーケンス読み込みテスト
	var sequence = load_scenario_sequence(["prologue", "chapter1"])
	print("シーケンステスト: %d シナリオ, %d シーン" % [sequence["scenarios"].size(), sequence["all_scenes"].size()])

func get_library_status() -> Dictionary:
	# ライブラリの状態を取得# 
	return {
		"total_scenarios": scenario_library.scenarios.size(),
		"scenario_ids": scenario_library.get_all_scenario_ids(),
		"library_path": scenario_library.library_path,
		"cache_size": loaded_scenarios.size()
	}