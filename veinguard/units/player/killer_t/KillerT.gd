class_name KillerT
extends UnitBase

enum AttackPhase { IDLE, CHARGING, DASHING }
var _attack_phase    : AttackPhase = AttackPhase.IDLE
var _charge_timer    : float = 0.0
var _dash_timer      : float = 0.0
var _dash_dir        : Vector2 = Vector2.ZERO
var _dash_speed      : float = 800.0  # Kecepatan dash
var _dash_duration   : float = 0.2    # Lama waktu dash
var _charge_duration : float = 2.5    # Lama waktu charge
var _hit_enemies     : Array[Node2D] = []

var _retarget_timer  : float = 0.0


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)
	
	add_to_group("players")
	change_state(State.IDLE)


func _process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func _process_move(delta: float) -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
	
	# Bergerak ke target terdekat
	var dir := global_position.direction_to(current_target.global_position)
	velocity = dir * stats.move_speed
	move_and_slide()
	
	if sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")


func _process_attack(delta: float) -> void:
	if not is_instance_valid(current_target) and _attack_phase != AttackPhase.DASHING:
		_pick_nearest_target()
		return

	# Periodic re-targeting jika masih mengejar/idle
	if _attack_phase == AttackPhase.IDLE:
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
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
			return
		
		# Masuk jangkauan, mulai charge!
		_start_charge()

	elif _attack_phase == AttackPhase.CHARGING:
		velocity = Vector2.ZERO
		move_and_slide()
		
		_charge_timer += delta
		
		# Visual feedback untuk charging (kedap-kedip putih)
		if int(_charge_timer * 10) % 2 == 0:
			sprite.modulate = Color(1.5, 1.5, 1.5)
		else:
			sprite.modulate = Color.WHITE
			
		if _charge_timer >= _charge_duration:
			_start_dash()

	elif _attack_phase == AttackPhase.DASHING:
		_dash_timer += delta
		
		# Lakukan pergerakan dash
		velocity = _dash_dir * _dash_speed
		move_and_slide()
		
		# Berikan damage ke musuh yang dilewati
		_check_dash_hits()
		
		if _dash_timer >= _dash_duration:
			_end_dash()


func _start_charge() -> void:
	_attack_phase = AttackPhase.CHARGING
	_charge_timer = 0.0
	velocity = Vector2.ZERO
	if sprite.sprite_frames.has_animation("charge"):
		sprite.play("charge")
		
	# Putar area serangan agar menghadap target
	if is_instance_valid(current_target):
		attack_area.look_at(current_target.global_position)
		
	print("[%s] Mulai Charge!" % name)


func _start_dash() -> void:
	_attack_phase = AttackPhase.DASHING
	_dash_timer   = 0.0
	_hit_enemies.clear()
	sprite.modulate = Color.WHITE # reset warna
	
	if sprite.sprite_frames.has_animation("dash"):
		sprite.play("dash")
	
	if is_instance_valid(current_target):
		_dash_dir = global_position.direction_to(current_target.global_position)
	else:
		_dash_dir = Vector2(0, -1) # default lurus ke atas kalau target tiba-tiba mati
		
	# Matikan tabrakan fisik dengan musuh (asumsi musuh di layer 2) agar bisa nembus
	set_collision_mask_value(2, false)
		
	print("[%s] DASH!" % name)


func _check_dash_hits() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body is UnitBase and body.is_in_group("enemies"):
			if not body in _hit_enemies:
				_hit_enemies.append(body)
				body.take_damage(stats.damage)
				print("[%s] Hit %s saat dash!" % [name, body.name])


func _end_dash() -> void:
	_attack_phase = AttackPhase.IDLE
	_hit_enemies.clear()
	velocity = Vector2.ZERO
	
	# Nyalakan kembali tabrakan fisik dengan musuh
	set_collision_mask_value(2, true)
	
	# Langsung cari target berikutnya, jika ada langsung serang lagi/kejar
	_pick_nearest_target()


func _process_die(_delta: float) -> void:
	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
	if not sprite.animation_finished.is_connected(queue_free):
		sprite.animation_finished.connect(queue_free)


func _pick_nearest_target() -> void:
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
	if body == current_target and _attack_phase == AttackPhase.IDLE:
		_retarget_timer = 0.0
		_pick_nearest_target()
