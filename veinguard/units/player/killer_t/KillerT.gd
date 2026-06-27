class_name KillerT
extends UnitBase

enum KillerAttackPhase { IDLE, DASHING }
var _attack_phase    : KillerAttackPhase = KillerAttackPhase.IDLE
var _dash_timer      : float = 0.0
var _dash_dir        : Vector2 = Vector2.ZERO
var _dash_speed      : float = 800.0  # Kecepatan dash
var _dash_duration   : float = 0.2    # Lama waktu dash
var _charge_duration : float = 2.5    # Lama waktu charge
var _hit_enemies     : Array[Node2D] = []
var _has_started_moving : bool = false
var _is_slashing     : bool = false
var _slash_audio_player: AudioStreamPlayer2D


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	if not aggro_area.body_entered.is_connected(_on_aggro_entered):
		aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)
	
	if sprite:
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)
		sprite.animation_changed.connect(_on_animation_changed)
	
	_slash_audio_player = AudioStreamPlayer2D.new()
	_slash_audio_player.stream = AudioManager.sword_slash_sfx
	_slash_audio_player.volume_db = -8.0
	_slash_audio_player.finished.connect(func(): if _is_slashing: _slash_audio_player.play())
	add_child(_slash_audio_player)
	
	add_to_group("players")
	change_state(State.IDLE)


func _on_animation_finished() -> void:
	if sprite and sprite.animation == "dash":
		_is_slashing = false
		if _slash_audio_player and _slash_audio_player.playing:
			_slash_audio_player.stop()


func _on_animation_changed() -> void:
	if sprite:
		sprite.scale = get_sprite_base_scale()
		if sprite.animation != "dash":
			sprite.speed_scale = 1.0 # Reset speed scale untuk animasi selain dash


func get_sprite_base_scale() -> Vector2:
	var base = super.get_sprite_base_scale()
	if sprite:
		if sprite.animation == "charge" or sprite.animation == "die":
			return base * 1.3
	return base

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	if sprite and sprite.sprite_frames.has_animation("idle") and not _is_slashing:
		sprite.play("idle")
		
	# Lakukan pemindaian target berkala jika idle
	_retarget_timer += delta
	if _retarget_timer >= 0.5:
		_retarget_timer = 0.0
		_pick_nearest_target()


func _process_move(delta: float) -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
	
	# Bergerak ke target terdekat
	var dir := global_position.direction_to(current_target.global_position)
	velocity = dir * stats.move_speed
	move_and_slide()
	
	if sprite and sprite.sprite_frames.has_animation("walk") and not _is_slashing:
		sprite.play("walk")
	if velocity.x != 0 and sprite:
		sprite.flip_h = velocity.x < 0


func _process_attack(delta: float) -> void:
	if not is_instance_valid(current_target) and _attack_phase != KillerAttackPhase.DASHING:
		_pick_nearest_target()
		return

	# Periodic re-targeting jika masih mengejar/idle
	if _attack_phase == KillerAttackPhase.IDLE:
		_retarget_timer += delta
		if _retarget_timer >= 0.5:
			_retarget_timer = 0.0
			_pick_nearest_target()
			if not current_target: return
			
		# Cek apakah target masuk area serangan
		var bodies_in_attack := attack_area.get_overlapping_bodies()
		if not current_target in bodies_in_attack:
			# Kejar target kalau belum sampai
			var dir := global_position.direction_to(current_target.global_position)
			velocity = dir * stats.move_speed
			attack_area.look_at(current_target.global_position) # <-- Fix: Area harus ikut muter saat ngejar
			move_and_slide()
			if sprite and sprite.sprite_frames.has_animation("walk") and not _is_slashing:
				sprite.play("walk")
			if velocity.x != 0 and sprite:
				sprite.flip_h = velocity.x < 0
			return
		
		# Masuk jangkauan, mulai dash sequence (charging & dashing)
		_start_dash()

	elif _attack_phase == KillerAttackPhase.DASHING:
		_dash_timer += delta
		
		if _dash_timer < _charge_duration:
			# --- FASE CHARGE ---
			velocity = Vector2.ZERO
			move_and_slide()
			
			# Visual feedback untuk charging (kedap-kedip putih)
			if int(_dash_timer * 10) % 2 == 0:
				sprite.modulate = Color(1.5, 1.5, 1.5)
			else:
				sprite.modulate = Color.WHITE
		else:
			# --- FASE GERAKAN DASH ---
			if not _has_started_moving:
				_has_started_moving = true
				_is_slashing = true
				if _slash_audio_player and not _slash_audio_player.playing:
					_slash_audio_player.play()
				if sprite:
					sprite.modulate = Color.WHITE # reset warna
					sprite.scale = get_sprite_base_scale() # Kembalikan ke normal secara instan saat dash
					if sprite.sprite_frames.has_animation("dash"):
						# Sesuaikan speed_scale agar seluruh frame tebasan selesai tepat saat gerakan dash berakhir
						var anim_len : float = sprite.sprite_frames.get_frame_count("dash") / sprite.sprite_frames.get_animation_speed("dash")
						sprite.speed_scale = anim_len / _dash_duration
						sprite.play("dash")
				
				if is_instance_valid(current_target):
					_dash_dir = global_position.direction_to(current_target.global_position)
				else:
					_dash_dir = Vector2(0, -1) # default lurus ke atas kalau target tiba-tiba mati
					
				if _dash_dir.x != 0 and sprite:
					sprite.flip_h = _dash_dir.x < 0
					
				# Matikan tabrakan fisik dengan musuh (asumsi musuh di layer 2) agar bisa nembus
				set_collision_mask_value(2, false)
				print("[%s] DASH MOVEMENT STARTED!" % name)
			
			# Lakukan pergerakan dash
			velocity = _dash_dir * _dash_speed
			move_and_slide()
			
			# Berikan damage ke musuh yang dilewati
			_check_dash_hits()
			
		if _dash_timer >= _charge_duration + _dash_duration:
			_end_dash()


func _start_dash() -> void:
	_attack_phase = KillerAttackPhase.DASHING
	_dash_timer   = 0.0
	_has_started_moving = false
	_hit_enemies.clear()
	
	if sprite and sprite.sprite_frames.has_animation("charge"):
		sprite.play("charge")
		sprite.scale = get_sprite_base_scale() # Perbesar secara otomatis via get_sprite_base_scale
	
	if is_instance_valid(current_target):
		attack_area.look_at(current_target.global_position)
		if sprite:
			var dir := global_position.direction_to(current_target.global_position)
			if dir.x != 0:
				sprite.flip_h = dir.x < 0
				
	print("[%s] DASH SEQUENCE STARTED (Charging)!" % name)


func _check_dash_hits() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body is UnitBase and body.is_in_group("enemies"):
			if not body in _hit_enemies:
				_hit_enemies.append(body)
				body.take_damage(stats.damage)
				print("[%s] Hit %s saat dash!" % [name, body.name])


func _end_dash() -> void:
	_attack_phase = KillerAttackPhase.IDLE
	_has_started_moving = false
	_is_slashing = false
	if _slash_audio_player and _slash_audio_player.playing:
		_slash_audio_player.stop()
	_hit_enemies.clear()
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = get_sprite_base_scale() # Pastikan skala kembali normal
	
	# Nyalakan kembali tabrakan fisik dengan musuh
	set_collision_mask_value(2, true)
	
	# Langsung cari target berikutnya, jika ada langsung serang lagi/kejar
	_pick_nearest_target()




func _pick_nearest_target() -> void:
	if not aggro_area or not aggro_area.monitoring:
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
	if body == current_target and _attack_phase == KillerAttackPhase.IDLE:
		_retarget_timer = 0.0
		_pick_nearest_target()
