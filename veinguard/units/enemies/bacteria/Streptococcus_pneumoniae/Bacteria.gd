class_name Bacteria
extends UnitBase

var _attack_timer   : float = 0.0


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	if not aggro_area.body_entered.is_connected(_on_aggro_entered):
		aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)

	add_to_group("enemies")
	change_state(State.MOVE)


# Bergerak diam
func _process_move(_delta: float) -> void:
	velocity = Vector2(0, 0)
	move_and_slide()
	if sprite: sprite.play("walk")


func _process_attack(delta: float) -> void:
	if not is_instance_valid(current_target):
		current_attack_phase = AttackPhase.READY
		_pick_nearest_target()
		return

	# Cek jarak
	var dist := global_position.distance_to(current_target.global_position)

	if current_attack_phase == AttackPhase.READY:
		# Periodic re-targeting jika masih mengejar
		_retarget_timer += delta
		if _retarget_timer >= 0.5:
			_retarget_timer = 0.0
			_pick_nearest_target()
			if not current_target: return
			
		if dist > stats.attack_range:
			# Kejar target
			var dir := global_position.direction_to(current_target.global_position)
			velocity = dir * stats.move_speed
			move_and_slide()
			if sprite:
				if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
					sprite.play("walk")
				if velocity.x != 0:
					sprite.flip_h = velocity.x > 0
		else:
			# Mulai ancang-ancang (Windup)
			current_attack_phase = AttackPhase.WINDUP
			_windup_timer = 0.0
			velocity = Vector2.ZERO
			move_and_slide()
			if sprite:
				var dir := global_position.direction_to(current_target.global_position)
				if dir.x != 0: sprite.flip_h = dir.x > 0
				if sprite.sprite_frames.has_animation("attack"):
					sprite.play("attack")
					
	elif current_attack_phase == AttackPhase.WINDUP:
		if dist > stats.attack_range + 20.0:
			# Target kabur, batalkan serangan
			current_attack_phase = AttackPhase.READY
			return
			
		_windup_timer += delta
		if _windup_timer >= stats.windup_time:
			# Titik Impact: Beri damage
			if is_instance_valid(current_target):
				current_target.take_damage(stats.damage)
			current_attack_phase = AttackPhase.COOLDOWN
			_cooldown_timer = 0.0
			
			# Squash & Stretch Hit Effect
			if sprite:
				var base = get_sprite_base_scale()
				var tween = create_tween()
				tween.tween_property(sprite, "scale", Vector2(base.x * 1.1, base.y * 0.9), 0.05)
				tween.tween_property(sprite, "scale", base, 0.1)

	elif current_attack_phase == AttackPhase.COOLDOWN:
		_cooldown_timer += delta
		var total_attack_duration = 1.0 / stats.attack_speed
		var remaining_cooldown = max(0.0, total_attack_duration - stats.windup_time)
		
		# Jika animasi serangan sudah selesai tapi masih cooldown, kembali ke idle
		if sprite and sprite.animation == "attack" and not sprite.is_playing():
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
				
		if _cooldown_timer >= remaining_cooldown:
			current_attack_phase = AttackPhase.READY




func _pick_nearest_target() -> void:
	if not aggro_area.monitoring:
		return
	var nearest : Node2D = null
	var nearest_dist : float = INF
	for body in aggro_area.get_overlapping_bodies():
		if body is UnitBase and not body.is_in_group("enemies"):
			var d := global_position.distance_to(body.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = body
	current_target = nearest
	if current_target == null:
		var base = get_tree().get_first_node_in_group("player_base")
		if base:
			current_target = base
	if current_target:
		change_state(State.ATTACK)
	else:
		change_state(State.MOVE)


func _on_aggro_entered(_body: Node2D) -> void:
	# Setiap ada unit masuk, pilih ulang yang terdekat
	# Tapi jika sedang ATTACK, biarkan retarget timer yang handle (tiap 0.5s)
	if current_state != State.ATTACK:
		_pick_nearest_target()


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		_retarget_timer = 0.0
		_pick_nearest_target()


func _process_die(_delta: float) -> void:
	if _is_dying:
		return
	_is_dying = true
	
	collision_layer = 0
	collision_mask = 0
	if aggro_area:
		aggro_area.set_deferred("monitoring", false)
		aggro_area.set_deferred("monitorable", false)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)
		
	if sprite:
		sprite.stop()
		sprite.modulate = Color(1.0, 0.0, 0.0, 1.0) # Merah solid
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		await tween.finished
	else:
		await get_tree().create_timer(0.4).timeout
	queue_free()
