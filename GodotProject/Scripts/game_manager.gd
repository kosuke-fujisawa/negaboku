extends Node

# ゲーム全体の管理を行うシングルトンクラス
# UnityのGameManagerクラスの機能をGodotに移行

signal game_initialized
signal scene_changed(scene_name: String)

var relationship_system
var battle_system
var current_scene_name: String = ""
var is_initialized: bool = false

# Phase 3: シーン遷移システム
var scene_transition_manager
var text_scene_manager

# ゲーム状態
var party_members: Array = []
var current_dungeon: String = ""
var game_progress: Dictionary = {}

func _ready():
	print("GameManager: _ready()が呼び出されました")
	# シングルトンとして初期化
	initialize_game()

func initialize_game() -> void:
	print("GameManager: ゲーム初期化開始...")
	
	# 各システムの初期化
	setup_systems()
	setup_initial_party()
	
	is_initialized = true
	game_initialized.emit()
	print("GameManager: ゲーム初期化完了")
	
	# デバッグビルドでは診断情報を出力
	if OS.is_debug_build():
		print_system_diagnostics()

func setup_systems() -> void:
	# 関係值システムの初期化
	if relationship_system == null:
		var relationship_script = load("res://Scripts/systems/relationship.gd")
		if relationship_script == null:
			push_error("GameManager: RelationshipSystemスクリプトの読み込みに失敗しました")
			return
		
		relationship_system = relationship_script.new()
		if relationship_system == null:
			push_error("GameManager: RelationshipSystemの生成に失敗しました")
			return
		add_child(relationship_system)
		print("GameManager: RelationshipSystem初期化完了")
	
	# バトルシステムの初期化
	if battle_system == null:
		var battle_script = load("res://Scripts/systems/battle_system.gd")
		if battle_script == null:
			push_error("GameManager: BattleSystemスクリプトの読み込みに失敗しました")
			return
		
		battle_system = battle_script.new()
		if battle_system == null:
			push_error("GameManager: BattleSystemの生成に失敗しました")
			return
		add_child(battle_system)
		print("GameManager: BattleSystem初期化完了")
	
	# Phase 3: シーン遷移システムの初期化
	setup_scene_transition_system()

func setup_initial_party() -> void:
	if relationship_system == null:
		push_error("GameManager: RelationshipSystemが初期化されていません")
		return
	
	# 初期2人パーティの設定
	var character_script = load("res://Scripts/character.gd")
	if character_script == null:
		push_error("GameManager: Characterスクリプトの読み込みに失敗しました")
		return
	
	var char1 = character_script.new()
	if char1 == null:
		push_error("GameManager: プレイヤーキャラクターの生成に失敗しました")
		return
	char1.character_id = "player"
	char1.name = "プレイヤー"
	
	var char2 = character_script.new()
	if char2 == null:
		push_error("GameManager: パートナーキャラクターの生成に失敗しました")
		return
	char2.character_id = "partner"
	char2.name = "パートナー"
	
	party_members = [char1, char2]
	
	# 初期関係値設定（普通レベル：50）
	if not relationship_system.set_relationship("player", "partner", 50):
		push_error("GameManager: 初期関係値の設定に失敗しました")
	
	print("GameManager: 初期パーティ設定完了")

func change_scene(scene_path: String) -> void:
	print("GameManager: シーン変更 -> ", scene_path)
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(current_scene_name)

func start_new_game() -> void:
	print("GameManager: 新規ゲーム開始")
	
	# 初期化確認
	if not is_initialized:
		print("警告: GameManagerが初期化されていません。再初期化します...")
		initialize_game()
	
	# ゲーム状態をリセット
	game_progress.clear()
	current_dungeon = ""
	
	# パーティとシステムを再初期化
	setup_initial_party()
	
	# Phase 3システムの初期化確認
	if scene_transition_manager == null or text_scene_manager == null:
		print("警告: Phase 3システムが未初期化です。初期化します...")
		setup_scene_transition_system()
	
	# シナリオライブラリを読み込み
	print("GameManager: シナリオライブラリ読み込み中...")
	var library_loaded = await load_scenario_library()
	
	if library_loaded:
		# 利用可能なシナリオから最初のシナリオを開始
		var available_scenarios = get_available_scenarios()
		if available_scenarios.size() > 0:
			var first_scenario = available_scenarios[0]
			print("GameManager: 最初のシナリオを開始 - %s" % first_scenario)
			var success = await start_scenario(first_scenario)
			if success:
				print("GameManager: 新規ゲーム開始成功")
				return
			else:
				print("エラー: シナリオ開始に失敗しました")
		else:
			print("警告: 利用可能なシナリオがありません")
	else:
		print("警告: シナリオライブラリの読み込みに失敗しました")
	
	# フォールバック: メインテキストシーンに遷移
	print("GameManager: フォールバックシーンに遷移")
	change_scene("res://Scenes/MainTextScene.tscn")

func return_to_title() -> void:
	print("GameManager: タイトル画面に戻る")
	change_scene("res://Scenes/MainMenu.tscn")

func get_party_member(character_id: String) -> Character:
	if character_id.is_empty():
		push_error("GameManager: キャラクターIDが空です")
		return null
	
	if party_members.is_empty():
		push_warning("GameManager: パーティメンバーが設定されていません")
		return null
	
	for member in party_members:
		if member == null:
			push_warning("GameManager: nullのパーティメンバーが存在します")
			continue
		if member.character_id == character_id:
			return member
	
	push_warning("GameManager: 指定されたキャラクターが見つかりません - ID: '%s'" % character_id)
	return null

func save_game() -> bool:
	if relationship_system == null:
		push_error("GameManager: RelationshipSystemが初期化されていません")
		return false
	
	if party_members.is_empty():
		push_error("GameManager: パーティメンバーが設定されていません")
		return false
	
	var save_data = {
		"party_members": [],
		"relationships": relationship_system.get_all_relationships(),
		"game_progress": game_progress,
		"current_dungeon": current_dungeon
	}
	
	# パーティメンバーのシリアライズ
	for member in party_members:
		if member == null:
			push_error("GameManager: nullのパーティメンバーが存在します")
			return false
		
		if not member.has_method("to_dict"):
			push_error("GameManager: パーティメンバーにto_dictメソッドがありません")
			return false
		
		save_data.party_members.append(member.to_dict())
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file == null:
		push_error("GameManager: セーブファイルの作成に失敗しました")
		return false
	
	var json_string = JSON.stringify(save_data)
	if json_string.is_empty():
		push_error("GameManager: セーブデータのJSON変換に失敗しました")
		save_file.close()
		return false
	
	save_file.store_string(json_string)
	save_file.close()
	print("GameManager: ゲームデータ保存完了")
	return true

func load_game() -> bool:
	if relationship_system == null:
		push_error("GameManager: RelationshipSystemが初期化されていません")
		return false
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file == null:
		push_warning("GameManager: セーブファイルが見つかりません")
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	if json_string.is_empty():
		push_error("GameManager: セーブファイルが空です")
		return false
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("GameManager: セーブデータのJSON解析に失敗しました - エラー: %s" % json.get_error_message())
		return false
	
	var save_data = json.data
	if save_data == null:
		push_error("GameManager: セーブデータがnullです")
		return false
	
	if not save_data is Dictionary:
		push_error("GameManager: セーブデータの形式が不正です")
		return false
	
	# 必須キーの存在確認
	var required_keys = ["party_members", "relationships", "game_progress", "current_dungeon"]
	for key in required_keys:
		if not save_data.has(key):
			push_error("GameManager: セーブデータに必須キー '%s' がありません" % key)
			return false
	
	# パーティメンバーの復元
	party_members.clear()
	if save_data.party_members is Array:
		for member_data in save_data.party_members:
			if member_data == null:
				push_error("GameManager: パーティメンバーデータがnullです")
				return false
			
			var character_script = load("res://Scripts/character.gd")
			if character_script == null:
				push_error("GameManager: Characterスクリプトの読み込みに失敗しました")
				return false
			
			var character = character_script.new()
			if character == null:
				push_error("GameManager: キャラクターの生成に失敗しました")
				return false
			
			if not character.has_method("from_dict"):
				push_error("GameManager: キャラクターにfrom_dictメソッドがありません")
				return false
			
			character.from_dict(member_data)
			party_members.append(character)
	else:
		push_error("GameManager: パーティメンバーデータが配列ではありません")
		return false
	
	# 関係值の復元
	if not relationship_system.load_relationships(save_data.relationships):
		push_error("GameManager: 関係値データの読み込みに失敗しました")
		return false
	
	# 進行状況の復元
	if save_data.game_progress is Dictionary:
		game_progress = save_data.game_progress
	else:
		push_warning("GameManager: ゲーム進行データが辞書ではありません。初期化します")
		game_progress = {}
	
	if save_data.current_dungeon is String:
		current_dungeon = save_data.current_dungeon
	else:
		push_warning("GameManager: 現在のダンジョンデータが文字列ではありません。初期化します")
		current_dungeon = ""
	
	print("GameManager: ゲームデータ読み込み完了")
	return true

# ===========================================
# Phase 3: シーン遷移システム統合機能
# ===========================================

func setup_scene_transition_system() -> void:
	# 
	print("GameManager: シーン遷移システム初期化開始")
	
	# SceneTransitionManagerの初期化
	if scene_transition_manager == null:
		var transition_script = load("res://Scripts/systems/scene_transition_manager.gd")
		scene_transition_manager = transition_script.new()
		add_child(scene_transition_manager)
		print("GameManager: SceneTransitionManager初期化完了")
	
	# TextSceneManagerの初期化
	if text_scene_manager == null:
		var text_scene_script = load("res://Scripts/systems/text_scene_manager.gd")
		text_scene_manager = text_scene_script.new()
		add_child(text_scene_manager)
		print("GameManager: TextSceneManager初期化完了")
	
	# 相互連携の設定
	scene_transition_manager.initialize_with_managers(text_scene_manager, self)
	text_scene_manager.set_scene_transition_manager(scene_transition_manager)
	
	# シグナル接続
	scene_transition_manager.scenario_completed.connect(_on_scenario_completed)
	scene_transition_manager.transition_completed.connect(_on_scene_transition_completed)
	
	print("GameManager: シーン遷移システム統合完了")

func load_scenario_library() -> bool:
	# 
	if scene_transition_manager == null:
		print("エラー: SceneTransitionManagerが初期化されていません")
		return false
	
	# デフォルトライブラリを読み込み
	var scenario_loader_script = load("res://Scripts/systems/scenario_loader.gd")
	var scenario_loader = scenario_loader_script.new()
	var success = scenario_loader.load_default_scenario_library()
	
	if success:
		# シナリオライブラリからTransitionManagerにシナリオを転送
		var available_scenarios = scenario_loader.get_available_scenarios_from_library()
		for scenario_id in available_scenarios:
			var scenario_data = scenario_loader.get_scenario_from_library(scenario_id)
			if scenario_data != null:
				var file_path = scenario_data.file_path
				scene_transition_manager.load_scenario_file(scenario_id, file_path)
	
	return success

func start_scenario(scenario_id: String, scene_id: String = "") -> bool:
	# 
	if scene_transition_manager == null:
		print("エラー: SceneTransitionManagerが初期化されていません")
		return false
	
	print("GameManager: シナリオ開始 - %s" % scenario_id)
	return await scene_transition_manager.jump_to_scenario(scenario_id, scene_id)

func transition_to_scene(scene_id: String) -> bool:
	if scene_transition_manager == null:
		push_error("GameManager: SceneTransitionManagerが初期化されていません")
		return false
	
	if scene_id.is_empty():
		push_error("GameManager: シーンIDが空です")
		return false
	
	return await scene_transition_manager.transition_to_scene(scene_id)

func go_back_scene() -> bool:
	if scene_transition_manager == null:
		push_error("GameManager: SceneTransitionManagerが初期化されていません")
		return false
	
	return await scene_transition_manager.go_back()

func get_current_scene_info() -> Dictionary:
	# 
	var info = {
		"current_scene_name": current_scene_name,
		"is_transitioning": false,
		"text_scene_info": {}
	}
	
	if scene_transition_manager != null:
		var status = scene_transition_manager.get_transition_status()
		info["current_scenario"] = status.get("current_scenario", "")
		info["current_scene"] = status.get("current_scene", "")
		info["is_transitioning"] = status.get("is_transitioning", false)
	
	if text_scene_manager != null:
		info["text_scene_info"] = text_scene_manager.get_scene_info()
	
	return info

func get_available_scenarios() -> Array:
	# 
	if scene_transition_manager == null:
		return []
	
	return scene_transition_manager.get_loaded_scenarios()

# シーン遷移システムのイベントハンドラ
func _on_scenario_completed(scenario_id: String) -> void:
	# 
	print("GameManager: シナリオ完了 - %s" % scenario_id)
	
	# ゲーム進行状況を更新
	if not game_progress.has("completed_scenarios"):
		game_progress["completed_scenarios"] = []
	
	var completed_scenarios = game_progress["completed_scenarios"]
	if not scenario_id in completed_scenarios:
		completed_scenarios.append(scenario_id)
	
	# セーブデータを自動更新
	save_game()

func _on_scene_transition_completed(scene_id: String) -> void:
	# 
	print("GameManager: シーン遷移完了 - %s" % scene_id)
	current_scene_name = scene_id

# デバッグ・テスト機能
func test_phase3_systems() -> void:
	# 
	print("=== Phase 3 システムテスト開始 ===")
	
	# シナリオライブラリ読み込みテスト
	var library_loaded = load_scenario_library()
	print("シナリオライブラリ読み込み: %s" % ("成功" if library_loaded else "失敗"))
	
	# 利用可能シナリオ確認
	var scenarios = get_available_scenarios()
	print("利用可能シナリオ: %s" % scenarios)
	
	# シーン遷移テスト
	if scenarios.size() > 0:
		var test_scenario = scenarios[0]
		print("テストシナリオ開始: %s" % test_scenario)
		start_scenario(test_scenario)
	
	print("=== Phase 3 システムテスト完了 ===")

func get_phase3_status() -> Dictionary:
	# 
	var status = {
		"scene_transition_manager_ready": scene_transition_manager != null,
		"text_scene_manager_ready": text_scene_manager != null,
		"scenario_library_loaded": false,
		"available_scenarios": [],
		"current_scene_info": get_current_scene_info()
	}
	
	if scene_transition_manager != null:
		var loaded_scenarios = scene_transition_manager.get_loaded_scenarios()
		status["scenario_library_loaded"] = loaded_scenarios.size() > 0
		status["available_scenarios"] = loaded_scenarios
	
	return status

# デバッグ・診断機能
func print_system_diagnostics() -> void:
	# 
	print("=== GameManager システム診断 ===")
	print("初期化状態: %s" % ("完了" if is_initialized else "未完了"))
	print("RelationshipSystem: %s" % ("準備済み" if relationship_system != null else "未準備"))
	print("BattleSystem: %s" % ("準備済み" if battle_system != null else "未準備"))
	print("SceneTransitionManager: %s" % ("準備済み" if scene_transition_manager != null else "未準備"))
	print("TextSceneManager: %s" % ("準備済み" if text_scene_manager != null else "未準備"))
	print("パーティメンバー数: %d" % party_members.size())
	print("現在のシーン: %s" % current_scene_name)
	
	var phase3_status = get_phase3_status()
	print("Phase 3システム状態:")
	for key in phase3_status.keys():
		print("  %s: %s" % [key, phase3_status[key]])
	
	print("=== 診断完了 ===")