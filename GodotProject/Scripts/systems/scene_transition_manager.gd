class_name SceneTransitionManager
extends Node

# Phase 3: 高度なシーン遷移システム
# シーンの遷移、シナリオファイルベース管理、複数シーンファイル管理、シーン間ジャンプ機能

signal scene_loaded(scene_id: String)
signal transition_started(from_scene: String, to_scene: String)
signal transition_completed(scene_id: String)
signal scenario_completed(scenario_id: String)

# 遷移効果の種類
enum TransitionType { FADE, SLIDE_LEFT, SLIDE_RIGHT, SLIDE_UP, SLIDE_DOWN, DISSOLVE, INSTANT }  # フェードイン/アウト  # 左にスライド  # 右にスライド  # 上にスライド  # 下にスライド  # ディゾルブ効果  # 即座に切り替え

# 定数定義
const Z_INDEX_OVERLAY: int = 100


# シーン遷移の設定
class TransitionConfig:
	var type: TransitionType = TransitionType.FADE
	var duration: float = 0.5
	var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
	var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC

	func _init(p_type: TransitionType = TransitionType.FADE, p_duration: float = 0.5):
		type = p_type
		duration = p_duration


# シーン管理の状態
var current_scenario_id: String = ""
var current_scene_id: String = ""
var scene_stack: Array = []  # シーン履歴スタック
var scene_cache: Dictionary = {}  # シーンデータキャッシュ

# シナリオファイル管理
var scenario_loader: ScenarioLoader
var loaded_scenarios: Dictionary = {}  # scenario_id -> ScenarioData
var scene_transition_map: Dictionary = {}  # scene_id -> 次のシーンリスト

# 遷移エフェクト用ノード
var transition_overlay: ColorRect
var is_transitioning: bool = false

# リファレンス（GameManager無効化のため型なしに変更）
var text_scene_manager
var game_manager


func _ready():
	_initialize_transition_system()


func _initialize_transition_system():
	# 遷移システムの初期化 - エラーハンドリング付き
	if not _create_scenario_loader():
		return

	if not _create_transition_overlay():
		return

	print("SceneTransitionManager 初期化完了")


func _create_scenario_loader() -> bool:
	scenario_loader = ScenarioLoader.new()
	if scenario_loader == null:
		push_error("ScenarioLoaderの作成に失敗しました")
		return false
	return true


func _create_transition_overlay() -> bool:
	transition_overlay = ColorRect.new()
	if transition_overlay == null:
		push_error("遷移オーバーレイの作成に失敗しました")
		return false

	transition_overlay.color = Color.BLACK
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.visible = false
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition_overlay)
	return true


func initialize_with_managers(p_text_scene_manager, p_game_manager):
	# 他のマネージャーとの連携を初期化 - エラーハンドリング付き
	if p_text_scene_manager == null:
		push_error("TextSceneManagerがnullです")
		return

	if p_game_manager == null:
		push_error("GameManagerがnullです")
		return

	text_scene_manager = p_text_scene_manager
	game_manager = p_game_manager

	# TextSceneManagerのシグナル接続
	if text_scene_manager.has_signal("scene_finished"):
		text_scene_manager.scene_finished.connect(_on_scene_finished)
	else:
		push_warning("TextSceneManagerにscene_finishedシグナルがありません")

	if text_scene_manager.has_signal("choice_made"):
		text_scene_manager.choice_made.connect(_on_choice_made)
	else:
		push_warning("TextSceneManagerにchoice_madeシグナルがありません")

	print("マネージャー連携初期化完了")


# ===========================================
# シナリオファイルベース管理
# ===========================================


func load_scenario_file(scenario_id: String, file_path: String) -> bool:
	# シナリオファイルを読み込み#
	print("シナリオ読み込み開始: %s -> %s" % [scenario_id, file_path])

	var scenario_data = scenario_loader.load_scenario_file(file_path)
	if scenario_data == null:
		print("エラー: シナリオファイル読み込み失敗: %s" % file_path)
		return false

	loaded_scenarios[scenario_id] = scenario_data
	_build_scene_transition_map(scenario_id, scenario_data)

	print("シナリオ読み込み完了: %s (%d シーン)" % [scenario_id, scenario_data.scenes.size()])
	return true


func _build_scene_transition_map(scenario_id: String, scenario_data):
	# シーン遷移マップを構築#
	var scenes = scenario_data.scenes
	for i in range(scenes.size()):
		var scene_data = scenes[i]
		var scene_id = scene_data.scene_id if scene_data.has("scene_id") else "scene_%d" % i

		# 次のシーンを設定
		var next_scenes = []
		if i + 1 < scenes.size():
			var next_scene_data = scenes[i + 1]
			var next_scene_id = (
				next_scene_data.scene_id
				if next_scene_data.has("scene_id")
				else "scene_%d" % (i + 1)
			)
			next_scenes.append(next_scene_id)

		scene_transition_map[scene_id] = next_scenes
		print("シーン遷移マップ: %s -> %s" % [scene_id, next_scenes])


func load_multiple_scenarios(scenario_configs: Array) -> bool:
	# 複数のシナリオファイルを一括読み込み#
	print("複数シナリオ読み込み開始: %d ファイル" % scenario_configs.size())

	var success_count = 0
	for config in scenario_configs:
		if config.has("id") and config.has("path"):
			if load_scenario_file(config["id"], config["path"]):
				success_count += 1
			else:
				print("警告: シナリオ読み込み失敗: %s" % config["id"])

	print("複数シナリオ読み込み完了: %d/%d 成功" % [success_count, scenario_configs.size()])
	return success_count == scenario_configs.size()


func get_loaded_scenarios() -> Array:
	# 読み込み済みシナリオIDリストを取得#
	return loaded_scenarios.keys()


func get_scenario_scenes(scenario_id: String) -> Array:
	# 指定シナリオのシーンリストを取得#
	if scenario_id in loaded_scenarios:
		return loaded_scenarios[scenario_id].scenes
	return []


# ===========================================
# シーン遷移機能
# ===========================================


func transition_to_scene(scene_id: String, config: TransitionConfig = null) -> bool:
	# 指定シーンに遷移#
	if is_transitioning:
		print("警告: 既に遷移中のため無視: %s" % scene_id)
		return false

	if config == null:
		config = TransitionConfig.new()

	var from_scene = current_scene_id
	print("シーン遷移開始: %s -> %s" % [from_scene, scene_id])

	# 遷移開始シグナル
	transition_started.emit(from_scene, scene_id)

	# シーン履歴に追加
	if not current_scene_id.is_empty():
		scene_stack.append(current_scene_id)

	# 遷移エフェクトを実行
	await _execute_transition_effect(config, true)  # フェードアウト

	# シーンを変更
	var success = _change_to_scene(scene_id)
	if not success:
		print("エラー: シーン変更失敗: %s" % scene_id)
		await _execute_transition_effect(config, false)  # フェードイン（復帰）
		is_transitioning = false
		return false

	# フェードイン
	await _execute_transition_effect(config, false)

	current_scene_id = scene_id
	scene_loaded.emit(scene_id)
	transition_completed.emit(scene_id)
	is_transitioning = false

	print("シーン遷移完了: %s" % scene_id)
	return true


func _execute_transition_effect(config: TransitionConfig, is_fade_out: bool):
	# 遷移エフェクトを実行#
	is_transitioning = true
	transition_overlay.visible = true
	transition_overlay.z_index = Z_INDEX_OVERLAY  # 最前面に表示

	match config.type:
		TransitionType.FADE:
			await _fade_transition(config, is_fade_out)
		TransitionType.SLIDE_LEFT:
			await _slide_transition(config, Vector2(-1, 0), is_fade_out)
		TransitionType.SLIDE_RIGHT:
			await _slide_transition(config, Vector2(1, 0), is_fade_out)
		TransitionType.SLIDE_UP:
			await _slide_transition(config, Vector2(0, -1), is_fade_out)
		TransitionType.SLIDE_DOWN:
			await _slide_transition(config, Vector2(0, 1), is_fade_out)
		TransitionType.DISSOLVE:
			await _dissolve_transition(config, is_fade_out)
		TransitionType.INSTANT:
			# 即座に切り替え（エフェクトなし）
			pass

	if not is_fade_out:
		transition_overlay.visible = false


func _fade_transition(config: TransitionConfig, is_fade_out: bool):
	# フェード遷移 - Godot 4.x対応
	var start_alpha = 0.0 if is_fade_out else 1.0
	var end_alpha = 1.0 if is_fade_out else 0.0

	transition_overlay.color.a = start_alpha

	var tween = create_tween()
	tween.tween_method(
		func(alpha): transition_overlay.color.a = alpha, start_alpha, end_alpha, config.duration
	)
	tween.tween_callback(func(): print("フェード完了"))

	await tween.finished


func _slide_transition(config: TransitionConfig, direction: Vector2, is_fade_out: bool):
	# スライド遷移 - Godot 4.x対応
	var screen_size = get_viewport().get_visible_rect().size
	var start_pos = Vector2.ZERO if is_fade_out else direction * screen_size
	var end_pos = direction * screen_size if is_fade_out else Vector2.ZERO

	transition_overlay.position = start_pos

	var tween = create_tween()
	tween.tween_property(transition_overlay, "position", end_pos, config.duration)
	tween.set_ease(config.ease_type)
	tween.set_trans(config.trans_type)

	await tween.finished


func _dissolve_transition(config: TransitionConfig, is_fade_out: bool):
	# ディゾルブ遷移（粒子効果風）#
	# 簡単なディゾルブ効果（実装簡略化のためフェードベース）
	await _fade_transition(config, is_fade_out)


func _change_to_scene(scene_id: String) -> bool:
	# 実際のシーン変更処理#
	# シーンデータを検索
	var scene_data = _find_scene_data(scene_id)
	if scene_data == null:
		print("エラー: シーンデータが見つかりません: %s" % scene_id)
		return false

	# TextSceneManagerにシーンデータを適用
	if text_scene_manager:
		text_scene_manager._load_single_scene_data(scene_data)
		return true

	return false


func _find_scene_data(scene_id: String):
	# シーンIDからシーンデータを検索#
	for scenario_data in loaded_scenarios.values():
		for scene_data in scenario_data.scenes:
			var data_scene_id = scene_data.scene_id if scene_data.has("scene_id") else ""
			if data_scene_id == scene_id:
				return scene_data
	return null


# ===========================================
# シーン間ジャンプ機能
# ===========================================


func jump_to_scene(scene_id: String, transition_config: TransitionConfig = null) -> bool:
	# 指定シーンにジャンプ（履歴をクリア）#
	scene_stack.clear()  # 履歴をクリア
	return await transition_to_scene(scene_id, transition_config)


func jump_to_scenario(
	scenario_id: String, scene_id: String = "", transition_config: TransitionConfig = null
) -> bool:
	# 指定シナリオの指定シーンにジャンプ#
	if not scenario_id in loaded_scenarios:
		print("エラー: シナリオが読み込まれていません: %s" % scenario_id)
		return false

	current_scenario_id = scenario_id

	# シーンIDが指定されていない場合は最初のシーンに
	if scene_id.is_empty():
		var scenes = get_scenario_scenes(scenario_id)
		if scenes.size() > 0:
			var first_scene = scenes[0]
			scene_id = first_scene.scene_id if first_scene.has("scene_id") else "scene_0"
		else:
			print("エラー: シナリオにシーンがありません: %s" % scenario_id)
			return false

	return await jump_to_scene(scene_id, transition_config)


func go_back() -> bool:
	# 前のシーンに戻る#
	if scene_stack.is_empty():
		print("警告: 戻るシーンがありません")
		return false

	var previous_scene = scene_stack.pop_back()
	var config = TransitionConfig.new(TransitionType.SLIDE_RIGHT)  # 右から戻る演出
	return await transition_to_scene(previous_scene, config)


func restart_current_scenario() -> bool:
	# 現在のシナリオを最初から再開#
	if current_scenario_id.is_empty():
		print("警告: 現在のシナリオがありません")
		return false

	return await jump_to_scenario(current_scenario_id)


# ===========================================
# イベント処理
# ===========================================


func _on_scene_finished():
	# シーン終了時の処理#
	print("シーン終了: %s" % current_scene_id)

	# 次のシーンに自動遷移
	var next_scenes = scene_transition_map.get(current_scene_id, [])
	if next_scenes.size() > 0:
		var next_scene_id = next_scenes[0]  # 最初の選択肢を使用
		await transition_to_scene(next_scene_id)
	else:
		print("シナリオ完了: %s" % current_scenario_id)
		scenario_completed.emit(current_scenario_id)


func _on_choice_made(choice_index: int):
	# 選択肢選択時の処理#
	print("選択肢選択: %d (シーン: %s)" % [choice_index, current_scene_id])

	# 選択肢に応じたシーン分岐処理
	var next_scenes = scene_transition_map.get(current_scene_id, [])
	if choice_index < next_scenes.size():
		var next_scene_id = next_scenes[choice_index]
		await transition_to_scene(next_scene_id)


# ===========================================
# デバッグ・テスト機能
# ===========================================


func load_test_scenarios():
	# テスト用シナリオを読み込み#
	var test_configs = [
		{"id": "scene01", "path": "res://Assets/scenarios/scene01.md"},
		{"id": "scene02", "path": "res://Assets/scenarios/scene02.md"}
	]

	load_multiple_scenarios(test_configs)


func test_scene_transitions():
	# シーン遷移のテスト#
	print("シーン遷移テスト開始")

	# テストシナリオを読み込み
	load_test_scenarios()

	# scene01から開始
	await jump_to_scenario("scene01")

	await get_tree().create_timer(2.0).timeout

	# scene02に遷移
	var fade_config = TransitionConfig.new(TransitionType.FADE, 1.0)
	await transition_to_scene("scene02", fade_config)

	await get_tree().create_timer(2.0).timeout

	# 戻る
	await go_back()

	print("シーン遷移テスト完了")


func get_transition_status() -> Dictionary:
	# 遷移システムの状態を取得#
	return {
		"current_scenario": current_scenario_id,
		"current_scene": current_scene_id,
		"is_transitioning": is_transitioning,
		"scene_stack_size": scene_stack.size(),
		"loaded_scenarios": loaded_scenarios.keys(),
		"scene_cache_size": scene_cache.size()
	}
