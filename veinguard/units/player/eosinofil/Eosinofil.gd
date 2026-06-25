class_name Eosinofil
extends UnitBase

@export var projectile_scene : PackedScene

var _attack_timer : float = 0.0
var _wobble_time  : float = 0.0
var _eo_stats     : EosinophilStats

func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	aggro_area.body_entered.connect(_on_aggro_entered)
	
	# Casting stat ke kelas spesifik Eosinofil agar bisa mengakses variabel khususnya
	if stats is EosinophilStats:
		_eo_stats = stats as EosinophilStats
	else:
		push_error("[%s] Resource stats BUKAN EosinophilStats!" % name)
		
	add_to_group("players")
	change_state(State.IDLE)


func _on_state_changed(new_state: State) -> void:
	# Jika keluar dari status MOVE, kembalikan skala & rotasi sprite ke default secara instan
	if new_state != State.MOVE and sprite:
		sprite.scale = Vector2.ONE
		sprite.rotation = 0.0


func _process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func _process_move(delta: float) -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
		
	var dir := global_position.direction_to(current_target.global_position)
	velocity = dir * stats.move_speed
	move_and_slide()
	
	if sprite:
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		# --- Animasi Gerak Amoeba (Squash & Stretch) ---
		_wobble_time += delta
		var wave = sin(_wobble_time * 14.0)
		# Bergantian memipih dan memanjang searah pergerakan
		sprite.scale = Vector2(1.0 + wave * 0.12, 1.0 - wave * 0.08)
		sprite.rotation = wave * 0.06


func _process_attack(delta: float) -> void:
	if not is_instance_valid(current_target):
		_pick_nearest_target()
		return
		
	# Di dalam jangkauan radar: STOP BERGERAK & BERSIAP NEMBAK
	velocity = Vector2.ZERO
	move_and_slide()
	
	_attack_timer += delta
	if _attack_timer >= (1.0 / stats.attack_speed):
		_attack_timer = 0.0
		_fire()


func _fire() -> void:
	if not is_instance_valid(current_target) or not _eo_stats:
		return
		
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		
	# --- Animasi Tembak (Squash & Stretch Punch) ---
	if sprite:
		var tween = create_tween()
		# Memampat keras saat menembakkan proyektil
		tween.tween_property(sprite, "scale", Vector2(1.3, 0.6), 0.08)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Kembali ke ukuran normal dengan efek elastis
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	var dir := global_position.direction_to(current_target.global_position)
	
	# 1. Munculkan Projectile
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position
		# Passing konfigurasi stat ke proyektil
		if proj.has_method("setup"):
			proj.setup(dir, current_target, _eo_stats)
			
	# 2. KNOCKBACK (Melompat Mundur)
	# Meng-override velocity berlawanan arah dengan tembakan
	velocity = -dir * _eo_stats.knockback_force
	move_and_slide()
	
	print("[%s] Menembak dan Knockback mundur!" % name)


func _on_aggro_entered(body: Node2D) -> void:
	if current_state != State.ATTACK:
		_pick_nearest_target()


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
