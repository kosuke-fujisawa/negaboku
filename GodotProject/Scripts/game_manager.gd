extends Node

# ゲーム全体の管理を行うシングルトンクラス
# UnityのGameManagerクラスの機能をGodotに移行

signal game_initialized
signal scene_changed(scene_name: String)

var relationship_system
var battle_system
var current_scene_name: String = ""
var is_initialized: bool = false

# ゲーム状態
var party_members: Array = []
var current_dungeon: String = ""
var game_progress: Dictionary = {}

func _ready():
	# シングルトンとして初期化
	initialize_game()

func initialize_game():
	print("GameManager: ゲーム初期化開始...")
	
	# 各システムの初期化
	setup_systems()
	setup_initial_party()
	
	is_initialized = true
	game_initialized.emit()
	print("GameManager: ゲーム初期化完了")

func setup_systems():
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

func setup_initial_party():
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

func change_scene(scene_path: String):
	print("GameManager: シーン変更 -> ", scene_path)
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(current_scene_name)

func start_new_game():
	print("GameManager: 新規ゲーム開始")
	# ゲーム状態をリセット
	game_progress.clear()
	current_dungeon = ""
	
	# パーティとシステムを再初期化
	setup_initial_party()
	
	# メインゲームシーンに遷移
	change_scene("res://Scenes/Main.tscn")

func return_to_title():
	print("GameManager: タイトル画面に戻る")
	change_scene("res://Scenes/MainMenu.tscn")

func get_party_member(character_id: String):
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