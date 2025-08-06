class_name Phase3TestScene
extends Control

# Phase 3: シーン遷移システム統合テストシーン
# 全ての機能を一画面でテストできるデバッグUI

signal test_completed(test_name: String, success: bool)

# UI要素
@onready var test_log: TextEdit = $VBoxContainer/TestLog
@onready var scenario_list: OptionButton = $VBoxContainer/Controls/ScenarioList
@onready var scene_list: OptionButton = $VBoxContainer/Controls/SceneList
@onready var transition_type: OptionButton = $VBoxContainer/Controls/TransitionType
@onready var status_label: Label = $VBoxContainer/StatusLabel

# システム参照
var game_manager: GameManager
var scene_transition_manager: SceneTransitionManager
var text_scene_manager: TextSceneManager

# テスト状態
var test_results: Dictionary = {}
var current_test_index: int = 0


func _ready():
	print("Phase3TestScene: 初期化開始")

	# GameManagerの取得
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null

	if game_manager == null:
		add_log("エラー: GameManagerが見つかりません")
		return

	# システム参照の取得
	scene_transition_manager = game_manager.scene_transition_manager
	text_scene_manager = game_manager.text_scene_manager

	if scene_transition_manager == null or text_scene_manager == null:
		add_log("エラー: シーン遷移システムが初期化されていません")
		return

	# UI初期化
	setup_ui()

	# シナリオライブラリを読み込み
	await initialize_scenario_library()

	add_log("Phase3TestScene: 初期化完了")


func setup_ui():
	# UI要素の初期化#
	# 遷移タイプの設定
	transition_type.clear()
	transition_type.add_item("フェード", SceneTransitionManager.TransitionType.FADE)
	transition_type.add_item("左スライド", SceneTransitionManager.TransitionType.SLIDE_LEFT)
	transition_type.add_item("右スライド", SceneTransitionManager.TransitionType.SLIDE_RIGHT)
	transition_type.add_item("上スライド", SceneTransitionManager.TransitionType.SLIDE_UP)
	transition_type.add_item("下スライド", SceneTransitionManager.TransitionType.SLIDE_DOWN)
	transition_type.add_item("ディゾルブ", SceneTransitionManager.TransitionType.DISSOLVE)
	transition_type.add_item("即座", SceneTransitionManager.TransitionType.INSTANT)

	# ボタンイベント接続
	$VBoxContainer/Controls/TestAllButton.pressed.connect(_on_test_all_pressed)
	$VBoxContainer/Controls/LoadScenariosButton.pressed.connect(_on_load_scenarios_pressed)
	$VBoxContainer/Controls/StartScenarioButton.pressed.connect(_on_start_scenario_pressed)
	$VBoxContainer/Controls/JumpSceneButton.pressed.connect(_on_jump_scene_pressed)
	$VBoxContainer/Controls/GoBackButton.pressed.connect(_on_go_back_pressed)
	$VBoxContainer/Controls/GetStatusButton.pressed.connect(_on_get_status_pressed)
	$VBoxContainer/Controls/ClearLogButton.pressed.connect(_on_clear_log_pressed)

	scenario_list.item_selected.connect(_on_scenario_selected)


func initialize_scenario_library():
	# シナリオライブラリの初期化#
	add_log("シナリオライブラリ読み込み開始...")

	var success = await game_manager.load_scenario_library()
	if success:
		add_log("シナリオライブラリ読み込み成功")
		update_scenario_list()
	else:
		add_log("エラー: シナリオライブラリ読み込み失敗")


func update_scenario_list():
	# シナリオリストUIを更新#
	scenario_list.clear()

	var available_scenarios = game_manager.get_available_scenarios()
	for scenario_id in available_scenarios:
		scenario_list.add_item(scenario_id)

	add_log("利用可能シナリオ: %s" % available_scenarios)


func update_scene_list(scenario_id: String):
	# 指定シナリオのシーンリストを更新#
	scene_list.clear()

	if scene_transition_manager == null:
		return

	# シナリオのシーン情報を取得（簡易実装）
	add_log("シナリオ '%s' のシーン情報を取得中..." % scenario_id)

	# TODO: SceneTransitionManagerにシーンリスト取得メソッドを追加
	# 現在は仮のシーンIDを追加
	scene_list.add_item("scene_01")
	scene_list.add_item("scene_02")
	scene_list.add_item("scene_03")


func add_log(message: String):
	# ログに項目を追加#
	var timestamp = Time.get_datetime_string_from_system()
	var log_entry = "[%s] %s" % [timestamp, message]

	if test_log:
		test_log.text += log_entry + "\n"
		# 自動スクロール
		test_log.scroll_vertical = test_log.get_line_count()

	print("Phase3TestScene: %s" % message)


func update_status():
	# ステータス表示を更新#
	if game_manager == null:
		return

	var status = game_manager.get_phase3_status()
	var status_text = "システム状態:\n"
	status_text += (
		"- SceneTransitionManager: %s\n"
		% ("準備済み" if status.scene_transition_manager_ready else "未準備")
	)
	status_text += (
		"- TextSceneManager: %s\n" % ("準備済み" if status.text_scene_manager_ready else "未準備")
	)
	status_text += "- シナリオライブラリ: %s\n" % ("読み込み済み" if status.scenario_library_loaded else "未読み込み")
	status_text += "- 利用可能シナリオ数: %d" % status.available_scenarios.size()

	if status_label:
		status_label.text = status_text


# ===========================================
# イベントハンドラ
# ===========================================


func _on_test_all_pressed():
	# 全機能テストを実行#
	add_log("=== 全機能テスト開始 ===")

	test_results.clear()
	current_test_index = 0

	# テスト1: シナリオライブラリ読み込み
	await run_test("scenario_library_load", test_scenario_library_load)

	# テスト2: シナリオ遷移
	await run_test("scenario_transition", test_scenario_transition)

	# テスト3: シーン間ジャンプ
	await run_test("scene_jump", test_scene_jump)

	# テスト4: 戻る機能
	await run_test("go_back", test_go_back)

	# テスト結果表示
	show_test_results()

	add_log("=== 全機能テスト完了 ===")


func run_test(test_name: String, test_function: Callable) -> bool:
	# 個別テストを実行#
	add_log("テスト実行: %s" % test_name)

	var start_time = Time.get_ticks_msec()
	var success = await test_function.call()
	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time

	test_results[test_name] = {
		"success": success, "duration": duration, "index": current_test_index
	}

	current_test_index += 1

	add_log("テスト結果: %s - %s (%d ms)" % [test_name, "成功" if success else "失敗", duration])
	test_completed.emit(test_name, success)

	return success


func test_scenario_library_load() -> bool:
	# シナリオライブラリ読み込みテスト#
	var available_scenarios = game_manager.get_available_scenarios()
	return available_scenarios.size() > 0


func test_scenario_transition() -> bool:
	# シナリオ遷移テスト#
	var available_scenarios = game_manager.get_available_scenarios()
	if available_scenarios.is_empty():
		return false

	var test_scenario = available_scenarios[0]
	var success = await game_manager.start_scenario(test_scenario)

	await get_tree().create_timer(1.0).timeout  # 1秒待機

	return success


func test_scene_jump() -> bool:
	# シーン間ジャンプテスト#
	# 簡易テスト: 現在のシーン情報を取得
	var scene_info = game_manager.get_current_scene_info()
	return scene_info.has("current_scene")


func test_go_back() -> bool:
	# 戻る機能テスト#
	var success = await game_manager.go_back_scene()

	await get_tree().create_timer(0.5).timeout  # 0.5秒待機

	return success


func show_test_results():
	# テスト結果を表示#
	add_log("=== テスト結果サマリー ===")

	var total_tests = test_results.size()
	var successful_tests = 0
	var total_duration = 0

	for test_name in test_results.keys():
		var result = test_results[test_name]
		if result.success:
			successful_tests += 1
		total_duration += result.duration

		add_log("- %s: %s (%d ms)" % [test_name, "成功" if result.success else "失敗", result.duration])

	add_log(
		(
			"成功率: %d/%d (%d%%)"
			% [successful_tests, total_tests, (successful_tests * 100) / total_tests]
		)
	)
	add_log("総実行時間: %d ms" % total_duration)


func _on_load_scenarios_pressed():
	# シナリオ読み込みボタン#
	await initialize_scenario_library()


func _on_start_scenario_pressed():
	# シナリオ開始ボタン#
	var selected_index = scenario_list.selected
	if selected_index < 0:
		add_log("エラー: シナリオが選択されていません")
		return

	var scenario_id = scenario_list.get_item_text(selected_index)
	add_log("シナリオ開始: %s" % scenario_id)

	var success = await game_manager.start_scenario(scenario_id)
	add_log("シナリオ開始結果: %s" % ("成功" if success else "失敗"))


func _on_jump_scene_pressed():
	# シーンジャンプボタン#
	var scene_selected_index = scene_list.selected
	if scene_selected_index < 0:
		add_log("エラー: シーンが選択されていません")
		return

	var scene_id = scene_list.get_item_text(scene_selected_index)
	add_log("シーンジャンプ: %s" % scene_id)

	var success = await game_manager.transition_to_scene(scene_id)
	add_log("シーンジャンプ結果: %s" % ("成功" if success else "失敗"))


func _on_go_back_pressed():
	# 戻るボタン#
	add_log("前のシーンに戻る")

	var success = await game_manager.go_back_scene()
	add_log("戻る結果: %s" % ("成功" if success else "失敗"))


func _on_get_status_pressed():
	# ステータス取得ボタン#
	update_status()

	var scene_info = game_manager.get_current_scene_info()
	add_log("現在のシーン情報: %s" % scene_info)


func _on_clear_log_pressed():
	# ログクリアボタン#
	if test_log:
		test_log.text = ""
	add_log("ログをクリアしました")


func _on_scenario_selected(index: int):
	# シナリオ選択イベント#
	if index >= 0:
		var scenario_id = scenario_list.get_item_text(index)
		update_scene_list(scenario_id)
		add_log("シナリオ選択: %s" % scenario_id)
