class_name EffectLayer
extends Control

# エフェクトレイヤー
# Unity版の演出システムをGodotで再実装
# 爆発、斬撃、光、カメラ揺れなどの演出を管理

signal effect_completed(effect_name: String)

var camera_2d: Camera2D
var flash_overlay: ColorRect
var particle_container: Node2D
var animation_player: AnimationPlayer

# エフェクト定義
var effects_data: Dictionary = {}
var active_effects = []

func _ready():
	setup_ui()
	setup_effects_data()

func setup_ui():
	# フラッシュオーバーレイ
	flash_overlay = ColorRect.new()
	flash_overlay.name = "FlashOverlay"
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.color = Color.TRANSPARENT
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_overlay)
	
	# パーティクル用コンテナ
	particle_container = Node2D.new()
	particle_container.name = "ParticleContainer"
	add_child(particle_container)
	
	# アニメーションプレイヤー
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	add_child(animation_player)
	
	# カメラ参照を取得（親から）
	call_deferred("find_camera")

func find_camera():
	camera_2d = get_viewport().get_camera_2d()
	if not camera_2d:
		print("EffectLayer: Camera2Dが見つかりません")

func setup_effects_data():
	# 爆発エフェクト
	effects_data["explosion"] = {
		"type": "particle",
		"particle_type": "explosion",
		"duration": 1.0,
		"screen_shake": 0.3,
		"flash_color": Color.YELLOW,
		"flash_duration": 0.2
	}
	
	# 斬撃エフェクト
	effects_data["slash"] = {
		"type": "animated_sprite",
		"animation": "slash_animation",
		"duration": 0.8,
		"screen_shake": 0.2,
		"flash_color": Color.CYAN,
		"flash_duration": 0.1
	}
	
	# 光エフェクト
	effects_data["light"] = {
		"type": "flash",
		"flash_color": Color.WHITE,
		"flash_duration": 0.5,
		"fade_duration": 0.3
	}
	
	# 回復エフェクト
	effects_data["heal"] = {
		"type": "particle",
		"particle_type": "heal",
		"duration": 1.5,
		"flash_color": Color.GREEN,
		"flash_duration": 0.3
	}

# メインのエフェクト再生API
func play_effect(effect_name: String, position: Vector2 = Vector2.ZERO):
	if effect_name in active_effects:
		print("EffectLayer: エフェクト '%s' は既に再生中です" % effect_name)
		return
	
	if not effects_data.has(effect_name):
		print("EffectLayer: 不明なエフェクト '%s'" % effect_name)
		return
	
	var effect_data = effects_data[effect_name]
	active_effects.append(effect_name)
	
	print("EffectLayer: エフェクト '%s' を再生開始" % effect_name)
	
	# エフェクトタイプ別の処理
	match effect_data.type:
		"particle":
			play_particle_effect(effect_name, effect_data, position)
		"animated_sprite":
			play_animated_sprite_effect(effect_name, effect_data, position)
		"flash":
			play_flash_effect(effect_name, effect_data)
	
	# 画面フラッシュ
	if effect_data.has("flash_color"):
		play_screen_flash(effect_data.flash_color, effect_data.get("flash_duration", 0.2))
	
	# 画面揺れ
	if effect_data.has("screen_shake"):
		shake_camera(effect_data.screen_shake)
	
	# エフェクト終了タイマー
	var duration = effect_data.get("duration", 1.0)
	await get_tree().create_timer(duration).timeout
	finish_effect(effect_name)

func play_particle_effect(effect_name: String, effect_data: Dictionary, position: Vector2):
	var particles = CPUParticles2D.new()
	particles.name = effect_name + "_particles"
	particles.position = position
	particle_container.add_child(particles)
	
	match effect_data.particle_type:
		"explosion":
			setup_explosion_particles(particles)
		"heal":
			setup_heal_particles(particles)
		_:
			setup_default_particles(particles)
	
	particles.emitting = true

func setup_explosion_particles(particles: CPUParticles2D):
	particles.amount = 50
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	
	# 白いドット放射
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 2.0
	particles.color = Color.WHITE

func setup_heal_particles(particles: CPUParticles2D):
	particles.amount = 30
	particles.lifetime = 1.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	
	# 緑の光が上昇
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, -50)
	
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 1.0
	particles.color = Color.GREEN

func setup_default_particles(particles: CPUParticles2D):
	particles.amount = 25
	particles.lifetime = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 100.0

func play_animated_sprite_effect(effect_name: String, effect_data: Dictionary, position: Vector2):
	var sprite = AnimatedSprite2D.new()
	sprite.name = effect_name + "_sprite"
	sprite.position = position
	particle_container.add_child(sprite)
	
	# TODO: アニメーションリソースの設定
	# sprite.sprite_frames = load("res://Assets/effects/slash_animation.tres")
	# sprite.play("default")
	
	# 仮実装：単純な拡大縮小アニメーション
	sprite.modulate = Color.CYAN
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(2.0, 0.1), 0.2)
	tween.tween_property(sprite, "scale", Vector2(0, 0), 0.6)
	tween.tween_callback(sprite.queue_free)

func play_flash_effect(effect_name: String, effect_data: Dictionary):
	var flash_color = effect_data.get("flash_color", Color.WHITE)
	var duration = effect_data.get("flash_duration", 0.5)
	play_screen_flash(flash_color, duration)

func play_screen_flash(color: Color, duration: float):
	flash_overlay.color = color
	
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.7, duration * 0.2)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, duration * 0.8)

func shake_camera(intensity: float, duration: float = 0.5):
	if camera_2d == null:
		push_warning("EffectLayer: Camera2Dが見つかりません。カメラシェイクをスキップします")
		return
	
	if intensity <= 0:
		push_warning("EffectLayer: カメラシェイクの強度が0以下です - intensity: %f" % intensity)
		return
	
	if duration <= 0:
		push_warning("EffectLayer: カメラシェイクの持続時間が0以下です - duration: %f" % duration)
		return
	
	# 既存のシェイクを停止
	stop_camera_shake()
	
	var original_offset = camera_2d.offset
	var shake_frequency = 30.0  # より滑らかな揺れのため頻度を上げる
	var shake_amplitude = clamp(intensity * 8.0, 1.0, 20.0)  # 適切な振幅に調整
	
	# ダンピング（徐々に弱くなる）効果
	var tween = create_tween()
	tween.set_loops(int(duration * shake_frequency))
	
	var steps = int(duration * shake_frequency)
	for i in steps:
		var progress = float(i) / float(steps)
		var damping = 1.0 - progress  # 時間経過で弱くなる
		
		var shake_offset = Vector2(
			randf_range(-shake_amplitude, shake_amplitude) * damping,
			randf_range(-shake_amplitude, shake_amplitude) * damping
		)
		
		tween.parallel().tween_property(camera_2d, "offset", 
			original_offset + shake_offset, 1.0 / shake_frequency)
	
	# 最後に原点に戻す
	tween.tween_property(camera_2d, "offset", original_offset, 0.1)
	
	# シェイクの状態を追跡
	_current_shake_tween = tween
	_original_camera_offset = original_offset

func stop_camera_shake():
	if _current_shake_tween != null and _current_shake_tween.is_valid():
		_current_shake_tween.kill()
	
	# カメラを元の位置に戻す
	if camera_2d != null and _original_camera_offset != Vector2.ZERO:
		camera_2d.offset = _original_camera_offset

# カメラシェイク状態追跡用変数
var _current_shake_tween: Tween
var _original_camera_offset: Vector2 = Vector2.ZERO

func finish_effect(effect_name: String):
	active_effects.erase(effect_name)
	
	# パーティクルやスプライトのクリーンアップ
	var particle_node = particle_container.get_node_or_null(effect_name + "_particles")
	if particle_node:
		particle_node.queue_free()
	
	var sprite_node = particle_container.get_node_or_null(effect_name + "_sprite")
	if sprite_node:
		sprite_node.queue_free()
	
	print("EffectLayer: エフェクト '%s' 完了" % effect_name)
	effect_completed.emit(effect_name)

# バトル用の特殊エフェクト
func play_battle_effect(effect_type: String, attacker_pos: Vector2, target_pos: Vector2):
	match effect_type:
		"physical_attack":
			play_effect("slash", target_pos)
		"magic_attack":
			play_effect("explosion", target_pos)
		"heal":
			play_effect("heal", target_pos)
		"critical_hit":
			play_effect("explosion", target_pos)
			shake_camera(0.5)

# ダンジョン探索用エフェクト
func play_dungeon_effect(effect_type: String):
	match effect_type:
		"door_open":
			play_effect("light")
		"treasure_found":
			play_effect("light")
			shake_camera(0.2)
		"trap_triggered":
			play_effect("explosion", get_viewport_rect().size / 2)

# エフェクトのカスタマイズ
func add_custom_effect(effect_name: String, effect_data: Dictionary):
	effects_data[effect_name] = effect_data
	print("EffectLayer: カスタムエフェクト '%s' を登録" % effect_name)

# エフェクトの停止
func stop_effect(effect_name: String):
	if effect_name in active_effects:
		finish_effect(effect_name)

func stop_all_effects():
	var effects_to_stop = active_effects.duplicate()
	for effect_name in effects_to_stop:
		stop_effect(effect_name)