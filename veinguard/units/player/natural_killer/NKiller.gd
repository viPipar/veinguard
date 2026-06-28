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
		
	# Tentukan arah hadap NTKiller (Kiri atau Kanan) berdasarkan flip_h sprite
	var facing_dir = Vector2.LEFT if (sprite and sprite.flip_h) else Vector2.RIGHT
	
	# Damage target utama secara langsung
	current_target.take_damage(stats.damage)
	print("[NTKiller] Shotgun blast hit primary target: ", current_target.name, " for ", stats.damage, " damage!")
	
	# Spawn efek visual "Shotgun Cone Blast" (Polygon2D berbentuk kerucut/sektor splashy)
	var poly = Polygon2D.new()
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	# Gambar busur/sektor 120 derajat dengan radius 200px (ditambah variasi agar splashy/tidak kaku)
	var radius = 200.0
	var steps = 14
	var start_angle = -PI / 3.0 # -60 derajat
	var end_angle = PI / 3.0   # +60 derajat
	for i in range(steps + 1):
		var angle = lerp(start_angle, end_angle, float(i) / steps)
		# Variasi radius acak untuk membuat tepi luar bergelombang/splashy
		var rand_r = radius + randf_range(-25.0, 15.0)
		if i % 3 == 0:
			rand_r -= 40.0 # Ceruk bagian dalam untuk efek cair
		points.append(Vector2(rand_r, 0).rotated(angle))
		
	poly.polygon = points
	poly.color = Color(1.0, 0.2, 0.2, 0.45) # Merah semi-transparan
	get_parent().add_child(poly)
	
	poly.global_position = global_position
	poly.rotation = facing_dir.angle()
	
	# Animasikan memudar (fade out)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(poly, "scale", Vector2(1.15, 1.1), 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(poly, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(poly.queue_free)
	
	# Tambahkan 4 partikel percikan droplet kecil terbang keluar
	for p_idx in range(4):
		var drop = Sprite2D.new()
		drop.texture = load("res://placeholder/Ellipse 1.png")
		drop.modulate = Color(1.0, 0.2, 0.2, 0.8) # Merah pekat
		drop.scale = Vector2(0.08, 0.08)
		get_parent().add_child(drop)
		drop.global_position = global_position
		
		# Tentukan arah sebaran acak dalam kerucut
		var spread_angle = facing_dir.angle() + randf_range(-PI / 4.0, PI / 4.0)
		var target_dist = randf_range(140.0, 240.0)
		var target_pos = global_position + Vector2(target_dist, 0).rotated(spread_angle)
		
		var drop_tween = create_tween().set_parallel(true)
		drop_tween.tween_property(drop, "global_position", target_pos, 0.3)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		drop_tween.tween_property(drop, "scale", Vector2.ZERO, 0.3)
		drop_tween.tween_property(drop, "modulate:a", 0.0, 0.3)
		drop_tween.chain().tween_callback(drop.queue_free)
	
	# Shotgun AOE damage: berikan damage cipratan ke musuh lain di arah hadap dalam kerucut (cone) 120 derajat
	for body in attack_area.get_overlapping_bodies():
		if body is UnitBase and body.is_in_group("enemies") and body != current_target and body.current_state != State.DIE:
			var dir_to_body := global_position.direction_to(body.global_position)
			# Dot product > 0.5 terhadap facing_dir berarti berada dalam kerucut 120 derajat arah hadap
			if facing_dir.dot(dir_to_body) > 0.5:
				var splash_damage = stats.damage * 0.7
				body.take_damage(splash_damage)
				print("[NTKiller] Shotgun collateral hit: ", body.name, " for ", splash_damage, " damage!")


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
