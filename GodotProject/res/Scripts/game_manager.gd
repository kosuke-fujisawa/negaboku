extends Node

# ゲーム全体の管理を行うシングルトンクラス
# UnityのGameManagerクラスの機能をGodotに移行

signal game_initialized
signal scene_changed(scene_name: String)

var relationship_system: RelationshipSystem
var battle_system: BattleSystem
var current_scene_name: String = ""
var is_initialized: bool = false

# ゲーム状態
var party_members: Array[Character] = []
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
	# 関係値システムの初期化
	relationship_system = RelationshipSystem.new()
	add_child(relationship_system)
	
	# バトルシステムの初期化
	battle_system = BattleSystem.new()
	add_child(battle_system)

func setup_initial_party():
	# 初期2人パーティの設定
	var char1 = Character.new()
	char1.character_id = "player"
	char1.name = "プレイヤー"
	
	var char2 = Character.new()
	char2.character_id = "partner"
	char2.name = "パートナー"
	
	party_members = [char1, char2]
	
	# 初期関係値設定（普通レベル：50）
	relationship_system.set_relationship("player", "partner", 50)

func change_scene(scene_path: String):
	print("GameManager: シーン変更 -> ", scene_path)
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(current_scene_name)

func get_party_member(character_id: String) -> Character:
	for member in party_members:
		if member.character_id == character_id:
			return member
	return null

func save_game():
	var save_data = {
		"party_members": [],
		"relationships": relationship_system.get_all_relationships(),
		"game_progress": game_progress,
		"current_dungeon": current_dungeon
	}
	
	for member in party_members:
		save_data.party_members.append(member.to_dict())
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("GameManager: ゲームデータ保存完了")
	else:
		print("GameManager: セーブファイル作成に失敗")

func load_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if not save_file:
		print("GameManager: セーブファイルが見つかりません")
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("GameManager: セーブデータの解析に失敗")
		return false
	
	var save_data = json.data
	
	# パーティメンバーの復元
	party_members.clear()
	for member_data in save_data.party_members:
		var character = Character.new()
		character.from_dict(member_data)
		party_members.append(character)
	
	# 関係値の復元
	relationship_system.load_relationships(save_data.relationships)
	
	# 進行状況の復元
	game_progress = save_data.game_progress
	current_dungeon = save_data.current_dungeon
	
	print("GameManager: ゲームデータ読み込み完了")
	return true