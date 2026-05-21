class_name Makrofag
extends UnitBase

# --- Config ---
@export var chew_duration : float = 6.0  # Durasi mengunyah (cooldown) dalam detik

# --- Runtime variables ---
var _chew_timer     : float = 0.0
var _is_chewing     : bool  = false
var _retarget_timer : float = 0.0


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)
	
	add_to_group("players")
	change_state(State.IDLE)


func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
		
	# Lakukan pemindaian target berkala jika idle
	_retarget_timer += delta
	if _retarget_timer >= 0.5:
		_retarget_timer = 0.0
		_pick_nearest_target()


func _process_move(delta: float) -> void:
	# Jika sedang mengunyah, jangan bergerak!
	if _is_chewing:
		change_state(State.ATTACK)
		return
		
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
		
	# Bergerak ke target terdekat
	var dir := global_position.direction_to(current_target.global_position)
	velocity = dir * stats.move_speed
	move_and_slide()
	
	if sprite and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
		
	# Cek apakah target masuk area serangan
	var bodies_in_attack := attack_area.get_overlapping_bodies()
	if current_target in bodies_in_attack:
		change_state(State.ATTACK)


func _process_attack(delta: float) -> void:
	if _is_chewing:
		# Fase Mengunyah (Chewing) - diam di tempat
		velocity = Vector2.ZERO
		move_and_slide()
		
		if sprite and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
			
		_chew_timer += delta
		
		# Efek visual mengunyah (Procedural Squish and Stretch)
		# Menggunakan fungsi sine untuk mensimulasikan gerakan mengunyah naik-turun secara berkala
		var chew_speed := 12.0
		var chew_amplitude := 0.15
		var scale_y := 1.0 + sin(_chew_timer * chew_speed) * chew_amplitude
		var scale_x := 1.0 - sin(_chew_timer * chew_speed) * chew_amplitude
		sprite.scale = Vector2(scale_x, scale_y)
		
		# Modulasi warna hijau-kecoklatan (warna asam lambung/pencernaan)
		sprite.modulate = Color(0.8, 1.0, 0.8)
		
		if _chew_timer >= chew_duration:
			# Selesai mengunyah! Kembalikan ke bentuk normal
			_is_chewing = false
			sprite.scale = Vector2(1.0, 1.0)
			sprite.modulate = Color.WHITE
			print("[%s] Selesai mengunyah, siap makan lagi!" % name)
			_pick_nearest_target()
		return

	# Fase Makan (Biting / One-Shot)
	if not is_instance_valid(current_target):
		_pick_nearest_target()
		return
		
	var bodies_in_attack := attack_area.get_overlapping_bodies()
	if not current_target in bodies_in_attack:
		# Target berada di luar jangkauan, kejar kembali
		change_state(State.MOVE)
		return
		
	# Target dalam jangkauan dan siap dimakan!
	velocity = Vector2.ZERO
	move_and_slide()
	
	print("[%s] MEMAKAN %s secara one-shot!" % [name, current_target.name])
	
	# Efek lunge & gulp menggunakan Tween
	var tween := create_tween()
	# 1. Mulut terbuka / meregang tinggi (lunge)
	tween.tween_property(sprite, "scale", Vector2(0.7, 1.4), 0.12)
	# 2. Menelan / gepeng melebar (gulp)
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.7), 0.08)
	# 3. Kembali ke ukuran normal saat mulai mengunyah
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Hancurkan musuh seketika
	current_target.take_damage(stats.damage)
	
	# Aktifkan fase chewing
	_is_chewing = true
	_chew_timer = 0.0


func _process_die(_delta: float) -> void:
	if sprite:
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = Color.WHITE
		if sprite.sprite_frames.has_animation("die"):
			sprite.play("die")
			if not sprite.animation_finished.is_connected(queue_free):
				sprite.animation_finished.connect(queue_free)
			return
	queue_free()


func _pick_nearest_target() -> void:
	if _is_chewing:
		return
		
	var nearest : Node2D = null
	var nearest_dist : float = INF
	for body in aggro_area.get_overlapping_bodies():
		if body is UnitBase and body.is_in_group("enemies"):
			var d := global_position.distance_to(body.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = body
	current_target = nearest
	if current_target:
		change_state(State.ATTACK)
	else:
		change_state(State.IDLE)


func _on_aggro_entered(_body: Node2D) -> void:
	if current_state != State.ATTACK:
		_pick_nearest_target()


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target and not _is_chewing:
		_retarget_timer = 0.0
		_pick_nearest_target()
