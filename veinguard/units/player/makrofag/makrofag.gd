class_name Makrofag
extends UnitBase

# --- Config ---
@export var chew_duration : float = 12.0  # Durasi mengunyah (cooldown) dalam detik

# --- Runtime variables ---
var _chew_timer     : float = 0.0
var _eat_audio_player: AudioStreamPlayer2D


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	if not aggro_area.body_entered.is_connected(_on_aggro_entered):
		aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)
	
	_eat_audio_player = AudioStreamPlayer2D.new()
	_eat_audio_player.stream = AudioManager.eat_sfx
	_eat_audio_player.volume_db = -8.0
	_eat_audio_player.finished.connect(func(): if current_state == State.EAT: _eat_audio_player.play())
	add_child(_eat_audio_player)
	
	add_to_group("players")
	change_state(State.IDLE)


func _on_state_changed(new_state: State) -> void:
	if new_state == State.EAT:
		_chew_timer = 0.0
		if sprite:
			# Modulasi warna hijau-kecoklatan (warna asam lambung/pencernaan)
			sprite.modulate = Color(0.8, 1.0, 0.8)
			if sprite.sprite_frames.has_animation("eat"):
				sprite.play("eat")
		if _eat_audio_player and not _eat_audio_player.playing:
			_eat_audio_player.play()
	else:
		if sprite:
			sprite.scale = get_sprite_base_scale()
			sprite.modulate = Color.WHITE
		if _eat_audio_player and _eat_audio_player.playing:
			_eat_audio_player.stop()


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
	# Fase Makan (Biting / One-Shot) dengan Windup
	if not is_instance_valid(current_target):
		current_attack_phase = AttackPhase.READY
		_pick_nearest_target()
		return
		
	var dist := global_position.distance_to(current_target.global_position)
	
	if current_attack_phase == AttackPhase.READY:
		var bodies_in_attack := attack_area.get_overlapping_bodies()
		if not current_target in bodies_in_attack:
			# Target berada di luar jangkauan, kejar kembali
			change_state(State.MOVE)
			return
			
		# Target dalam jangkauan, mulai ancang-ancang
		current_attack_phase = AttackPhase.WINDUP
		_windup_timer = 0.0
		velocity = Vector2.ZERO
		move_and_slide()
		if sprite:
			if sprite.sprite_frames.has_animation("eat"):
				sprite.play("eat")
				
	elif current_attack_phase == AttackPhase.WINDUP:
		var bodies_in_attack := attack_area.get_overlapping_bodies()
		if not current_target in bodies_in_attack and dist > stats.attack_range + 20.0:
			current_attack_phase = AttackPhase.READY
			change_state(State.MOVE)
			return
			
		_windup_timer += delta
		if _windup_timer >= stats.windup_time:
			print("[%s] MEMAKAN %s secara one-shot!" % [name, current_target.name])
			if is_instance_valid(current_target):
				current_target.take_damage(stats.damage)
				
			# Squash & Stretch
			if sprite:
				var base = get_sprite_base_scale()
				var tween = create_tween()
				tween.tween_property(sprite, "scale", Vector2(base.x * 1.1, base.y * 0.9), 0.05)
				tween.tween_property(sprite, "scale", base, 0.1)
				
			current_attack_phase = AttackPhase.READY
			change_state(State.EAT)


func _process_eat(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	if sprite and sprite.sprite_frames.has_animation("eat") and sprite.animation != "eat":
		sprite.play("eat")
		
	_chew_timer += delta
	
	if _chew_timer >= chew_duration:
		print("[%s] Selesai mengunyah, siap makan lagi!" % name)
		change_state(State.IDLE)
		_pick_nearest_target()


func _pick_nearest_target() -> void:
	if current_state == State.EAT:
		return
		
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
	if current_state != State.ATTACK and current_state != State.EAT:
		_pick_nearest_target()


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target and current_state != State.EAT:
		_retarget_timer = 0.0
		_pick_nearest_target()
