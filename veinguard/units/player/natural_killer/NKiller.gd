# NTKiller.gd

class_name NTKiller
extends UnitBase

var _attack_timer   : float = 0.0


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
	
	add_to_group("players")
	
	change_state(State.IDLE)


func _on_animation_finished() -> void:
	if sprite and sprite.animation == "attack":
		if current_state == State.ATTACK:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")


func _on_state_changed(new_state: State) -> void:
	if sprite:
		if new_state != State.MOVE:
			sprite.scale = get_sprite_base_scale()
			sprite.rotation = 0.0
			
		if new_state == State.IDLE:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		elif new_state == State.MOVE:
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		elif new_state == State.ATTACK:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")


func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	if sprite and sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")
		
	# Lakukan pemindaian target berkala jika idle
	_retarget_timer += delta
	if _retarget_timer >= 0.5:
		_retarget_timer = 0.0
		_pick_nearest_target()


func _process_move(_delta: float) -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
	var dir := global_position.direction_to(current_target.global_position)
	velocity = dir * stats.move_speed
	move_and_slide()
	
	if sprite:
		if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
			sprite.play("walk")
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0


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
					sprite.flip_h = velocity.x < 0
		else:
			# Mulai ancang-ancang (Windup)
			current_attack_phase = AttackPhase.WINDUP
			_windup_timer = 0.0
			velocity = Vector2.ZERO
			move_and_slide()
			if sprite:
				var dir := global_position.direction_to(current_target.global_position)
				if dir.x != 0: sprite.flip_h = dir.x < 0
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
			_deal_damage()
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


func _deal_damage() -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
		
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		
	if current_target is UnitBase:
		current_target.take_damage(stats.damage)


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
	# Jika sedang ATTACK, biarkan retarget timer yang handle
	if current_state != State.ATTACK:
		_pick_nearest_target()


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		_retarget_timer = 0.0
		_pick_nearest_target()

func take_damage(amount: float) -> void:
	AudioManager.play_hit_natural_killer_sfx()
	super.take_damage(amount)
