class_name AudioManager
extends Node

signal bgm_started(file_path: String)
signal bgm_stopped
signal se_played(file_path: String)
signal voice_played(file_path: String)

var bgm_player: AudioStreamPlayer
var se_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer

var current_bgm_path: String = ""
var bgm_volume: float = 0.8
var se_volume: float = 0.6
var voice_volume: float = 0.7

# ボイス設定
var voice_enabled: bool = true

var bgm_fade_tween: Tween


func _ready():
	bgm_player = AudioStreamPlayer.new()
	se_player = AudioStreamPlayer.new()
	voice_player = AudioStreamPlayer.new()

	add_child(bgm_player)
	add_child(se_player)
	add_child(voice_player)

	bgm_player.volume_db = linear_to_db(bgm_volume)
	se_player.volume_db = linear_to_db(se_volume)
	voice_player.volume_db = linear_to_db(voice_volume)


func play_bgm(file_path: String, volume: float = 0.8, loop: bool = true, fade_in: bool = false):
	var full_path = _resolve_bgm_path(file_path)

	if not ResourceLoader.exists(full_path):
		print("BGMファイルが見つかりません: ", full_path)
		return false

	var audio_stream = load(full_path)
	if audio_stream == null:
		print("BGM読み込みに失敗しました: ", full_path)
		return false

	if bgm_player.playing:
		stop_bgm()

	bgm_player.stream = audio_stream
	bgm_player.stream.loop = loop
	bgm_player.volume_db = linear_to_db(volume) if not fade_in else linear_to_db(0.0)
	bgm_player.play()

	current_bgm_path = file_path
	bgm_volume = volume

	if fade_in:
		_fade_bgm_to(volume, 1.0)

	bgm_started.emit(file_path)
	print("BGM再生開始: ", file_path, " (音量: ", volume, ", ループ: ", loop, ")")
	return true


func stop_bgm(fade_time: float = 0.0):
	if not bgm_player.playing:
		return

	if fade_time > 0.0:
		_fade_bgm_to(0.0, fade_time)
		await bgm_fade_tween.finished

	bgm_player.stop()
	current_bgm_path = ""
	bgm_stopped.emit()
	print("BGM停止" + (" (フェードアウト: " + str(fade_time) + "秒)" if fade_time > 0.0 else ""))


func play_se(file_path: String, volume: float = 0.6):
	var full_path = _resolve_se_path(file_path)

	if not ResourceLoader.exists(full_path):
		print("効果音ファイルが見つかりません: ", full_path)
		return false

	var audio_stream = load(full_path)
	if audio_stream == null:
		print("効果音読み込みに失敗しました: ", full_path)
		return false

	se_player.stream = audio_stream
	se_player.volume_db = linear_to_db(volume)
	se_player.play()

	se_played.emit(file_path)
	print("効果音再生: ", file_path, " (音量: ", volume, ")")
	return true


func play_voice(file_path: String, volume: float = 0.7):
	# ボイスが無効化されている場合はスキップ
	if not voice_enabled:
		print("ボイス再生スキップ（ボイス無効設定）: ", file_path)
		return true

	var full_path = _resolve_voice_path(file_path)

	if not ResourceLoader.exists(full_path):
		print("音声ファイルが見つかりません: ", full_path)
		return false

	var audio_stream = load(full_path)
	if audio_stream == null:
		print("音声読み込みに失敗しました: ", full_path)
		return false

	if voice_player.playing:
		voice_player.stop()

	voice_player.stream = audio_stream
	voice_player.volume_db = linear_to_db(volume)
	voice_player.play()

	voice_played.emit(file_path)
	print("音声再生: ", file_path, " (音量: ", volume, ")")
	return true


func set_bgm_volume(volume: float):
	bgm_volume = clamp(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume)


func set_se_volume(volume: float):
	se_volume = clamp(volume, 0.0, 1.0)
	se_player.volume_db = linear_to_db(se_volume)


func set_voice_volume(volume: float):
	voice_volume = clamp(volume, 0.0, 1.0)
	voice_player.volume_db = linear_to_db(voice_volume)


func set_voice_enabled(enabled: bool):
	voice_enabled = enabled
	if not enabled and voice_player.playing:
		voice_player.stop()
	print("ボイス設定変更: ", "有効" if enabled else "無効")


func is_voice_enabled() -> bool:
	return voice_enabled


func is_bgm_playing() -> bool:
	return bgm_player.playing


func is_se_playing() -> bool:
	return se_player.playing


func is_voice_playing() -> bool:
	return voice_player.playing


func get_current_bgm() -> String:
	return current_bgm_path


func _resolve_bgm_path(file_path: String) -> String:
	if file_path.begins_with("res://"):
		return file_path
	return "res://Assets/sounds/bgm/" + file_path


func _resolve_se_path(file_path: String) -> String:
	if file_path.begins_with("res://"):
		return file_path
	return "res://Assets/sounds/se/" + file_path


func _resolve_voice_path(file_path: String) -> String:
	if file_path.begins_with("res://"):
		return file_path

	if "/" in file_path:
		return "res://Assets/sounds/voice/" + file_path
	else:
		return "res://Assets/sounds/voice/" + file_path


func _fade_bgm_to(target_volume: float, duration: float):
	if bgm_fade_tween:
		bgm_fade_tween.kill()
	bgm_fade_tween = create_tween()
	var current_volume = db_to_linear(bgm_player.volume_db)
	bgm_fade_tween.tween_method(_set_bgm_fade_volume, current_volume, target_volume, duration)


func _set_bgm_fade_volume(volume: float):
	bgm_player.volume_db = linear_to_db(volume)


func get_debug_info() -> Dictionary:
	return {
		"bgm_playing": is_bgm_playing(),
		"current_bgm": current_bgm_path,
		"bgm_volume": bgm_volume,
		"se_playing": is_se_playing(),
		"se_volume": se_volume,
		"voice_playing": is_voice_playing(),
		"voice_volume": voice_volume,
		"voice_enabled": voice_enabled
	}
