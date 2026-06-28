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
var _ghost_timer     : float = 0.0


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
	
	add_to_group("players")
	change_state(State.IDLE)


func _on_animation_finished() -> void:
	if sprite and sprite.animation == "dash":
		_is_slashing = false

func _on_state_changed(new_state: State) -> void:
	if new_state == State.DIE:
		_is_slashing = false


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
				AudioManager.play_sword_slash_sfx()
				_spawn_sword_slash_arc() # Efek tebasan pedang sabit bercahaya
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
			
			# Spawn ghost trail
			_ghost_timer += delta
			if _ghost_timer >= 0.04:
				_ghost_timer = 0.0
				_spawn_ghost_trail()
			
			# Berikan damage ke musuh yang dilewati
			_check_dash_hits()
			
		if _dash_timer >= _charge_duration + _dash_duration:
			_end_dash()


func _start_dash() -> void:
	_attack_phase = KillerAttackPhase.DASHING
	_dash_timer   = 0.0
	_ghost_timer  = 0.0
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
	var nearest : Node2D = null
	var nearest_dist : float = INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is UnitBase and body.current_state != State.DIE:
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


func _spawn_sword_slash_arc() -> void:
	# Efek tebasan pedang/cakar berbentuk sabit bercahaya cyan
	var slash_arc = Line2D.new()
	get_parent().add_child(slash_arc)
	slash_arc.width = 18.0
	slash_arc.default_color = Color(0.2, 0.85, 1.0, 0.95) # Cyan bercahaya
	
	var dir = _dash_dir
	if dir == Vector2.ZERO:
		dir = Vector2(0, -1)
		
	var perp = dir.orthogonal()
	
	var points : Array[Vector2] = []
	var num_points = 10
	var arc_length = 70.0
	var width_spread = 45.0
	
	for i in range(num_points):
		var t = float(i) / (num_points - 1)
		var angle = lerp(-PI/2.5, PI/2.5, t)
		var pt = dir * cos(angle) * arc_length + perp * sin(angle) * width_spread
		points.append(pt)
		
	slash_arc.points = PackedVector2Array(points)
	slash_arc.global_position = global_position
	
	# Animasi slash melebar lalu memudar
	var tween = create_tween().set_parallel(true)
	tween.tween_property(slash_arc, "modulate:a", 0.0, 0.22)
	tween.tween_property(slash_arc, "width", 0.0, 0.22)
	tween.chain().tween_callback(slash_arc.queue_free)


func _spawn_ghost_trail() -> void:
	if not sprite:
		return
	var ghost = Sprite2D.new()
	get_parent().add_child(ghost)
	
	# Dapatkan tekstur frame saat ini
	var current_frame = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.texture = current_frame
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.25, 0.8, 1.0, 0.55) # Bayangan cyan transparan
	
	# Animasi memudar
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tween.tween_callback(ghost.queue_free)
