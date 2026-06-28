class_name Trombosit
extends UnitBase

@onready var patch_progress : ProgressBar = get_node_or_null("PatchProgress")

var _enemy_base   : Node2D = null
var _attack_timer : float  = 0.0


func _on_ready() -> void:
	sprite     = $AnimatedSprite2D
	aggro_area = $AggroArea

	if not aggro_area.body_entered.is_connected(_on_body_entered):
		aggro_area.body_entered.connect(_on_body_entered)

	_enemy_base = get_tree().get_first_node_in_group("enemy_base")

	add_to_group("players")
	change_state(State.MOVE)
	if patch_progress:
		patch_progress.visible = false


func _on_state_changed(new_state: State) -> void:
	if sprite:
		if new_state == State.ATTACK:
			sprite.play("Attack")
		elif new_state == State.MOVE:
			sprite.play("walk")
		elif new_state == State.IDLE:
			sprite.play("idle")


# Jalan terus ke atas menuju EnemyBase
func _process_move(_delta: float) -> void:
	if not is_instance_valid(_enemy_base):
		change_state(State.IDLE)
		return

	# Jika sudah masuk range serangan, berhenti dan serang
	var dist := global_position.distance_to(_enemy_base.global_position)
	if dist <= stats.attack_range:
		change_state(State.ATTACK)
		return

	var dir  := global_position.direction_to(_enemy_base.global_position)
	velocity  = dir * stats.move_speed
	move_and_slide()
	if sprite: sprite.play("walk")


# Fokus menyerang base musuh dengan animasi throw (Attack)
func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if not is_instance_valid(_enemy_base):
		change_state(State.IDLE)
		return

	# Pastikan animasi Attack berjalan
	if sprite and sprite.animation != "Attack":
		sprite.play("Attack")

	_attack_timer += delta
	if _attack_timer >= 1.0 / stats.attack_speed:
		_attack_timer = 0.0
		_throw_clot_projectile()


func _throw_clot_projectile() -> void:
	if not is_instance_valid(_enemy_base):
		return

	# Animasi recoil pada tubuh Trombosit saat melempar (squash & stretch)
	if sprite:
		var base_scale = get_sprite_base_scale()
		var spr_tween = create_tween()
		spr_tween.tween_property(sprite, "scale", Vector2(base_scale.x * 1.15, base_scale.y * 0.8), 0.08)
		spr_tween.tween_property(sprite, "scale", Vector2(base_scale.x * 0.85, base_scale.y * 1.2), 0.08)
		spr_tween.tween_property(sprite, "scale", base_scale, 0.12)

	# Buat proyektil keping plasma (clot) secara programatik menggunakan ProjectileB (putih)
	var proj := Sprite2D.new()
	proj.texture = load("res://assets/ui/Character/ProjectileB.png")
	proj.scale = Vector2(0.4, 0.4)
	proj.modulate = Color(1.0, 1.0, 1.0, 1.0) # Putih bersih
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	# Target dengan sedikit variasi acak agar terlihat natural mendarat di base
	var target_pos = _enemy_base.global_position + Vector2(randf_range(-40, 40), randf_range(-20, 40))
	var fly_duration := 0.45

	var tween = create_tween()
	# Efek terbang parabolik (arc/tinggi lemparan)
	tween.tween_method(
		func(progress: float):
			if not is_instance_valid(proj): return
			var current_pos = global_position.lerp(target_pos, progress)
			# Tambahkan efek arc melengkung ke atas
			var arc_height = sin(progress * PI) * -80.0
			proj.global_position = current_pos + Vector2(0, arc_height)
			
			# Skala membesar di puncak busur (tengah penerbangan) untuk ilusi ketinggian 3D
			var current_scale = lerp(0.4, 0.8, sin(progress * PI))
			proj.scale = Vector2(current_scale, current_scale)
			
			# Putar proyektil saat terbang
			proj.rotation += 0.2,
		0.0, 1.0, fly_duration
	)

	await tween.finished
	if not is_instance_valid(proj):
		return

	# Kurangi HP Base saat mendarat
	if is_instance_valid(_enemy_base) and _enemy_base.has_method("take_damage"):
		AudioManager.play_punch_sfx()
		_enemy_base.take_damage(stats.damage)
		
		# Efek ledakan plasma kecil berwarna putih
		var splash := Sprite2D.new()
		splash.texture = load("res://assets/ui/Character/ProjectileB.png")
		splash.scale = Vector2(0.6, 0.6)
		splash.modulate = Color(1.0, 1.0, 1.0, 0.7) # Putih semi-transparan
		get_tree().current_scene.add_child(splash)
		splash.global_position = proj.global_position
		
		var s_tween = create_tween()
		s_tween.set_parallel(true)
		s_tween.tween_property(splash, "scale", Vector2(0.2, 0.2), 0.15)
		s_tween.tween_property(splash, "modulate:a", 0.0, 0.15)
		await s_tween.finished
		splash.queue_free()

	proj.queue_free()


# Kalau ada musuh di jalan — Trombosit mengabaikannya, tidak membalas, dan tetap fokus ke base
func _on_body_entered(_body: Node2D) -> void:
	pass

func take_damage(amount: float) -> void:
	super.take_damage(amount)
