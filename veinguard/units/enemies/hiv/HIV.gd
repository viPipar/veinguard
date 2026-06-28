class_name HIV
extends UnitBase

var projectile_scene: PackedScene = preload("res://units/enemies/hiv/HIVProjectile.tscn")

var _sparky_charge: float = 0.0
var _max_charge: float = 4.0
var _is_fully_charged: bool = false
var _charge_pulse_tween: Tween

func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	if not aggro_area.body_entered.is_connected(_on_aggro_entered):
		aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)

	add_to_group("enemies")
	change_state(State.MOVE)
	
	if not stats:
		stats = preload("res://units/enemies/hiv/hiv_stats.tres")

func _physics_process(delta: float) -> void:
	if current_state == State.DIE:
		super._physics_process(delta)
		return

	if self.is_stunned:
		velocity = Vector2.ZERO
		return
		
	# --- SPARK CHARGE LOGIC (PASSIVE) ---
	if not _is_fully_charged:
		_sparky_charge += delta
		if _sparky_charge >= _max_charge:
			_sparky_charge = _max_charge
			_is_fully_charged = true
			_start_pulse_effect()
	
	# Update animation based on charge state (while moving/idle, not attacking)
	if current_state != State.ATTACK:
		if _is_fully_charged:
			if sprite: sprite.play("charged")
		else:
			if sprite: sprite.play("charge")
			
	_retarget_timer += delta
	if _retarget_timer >= 0.5:
		_retarget_timer = 0.0
		_pick_nearest_target()

	if is_instance_valid(current_target) and (not (current_target is UnitBase) or current_target.current_state != State.DIE):
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= stats.attack_range:
			change_state(State.ATTACK)
		else:
			change_state(State.MOVE)
	else:
		var base = get_tree().get_first_node_in_group("player_base")
		if base:
			current_target = base
			var dist = global_position.distance_to(current_target.global_position)
			if dist <= stats.attack_range:
				change_state(State.ATTACK)
			else:
				change_state(State.MOVE)
		else:
			change_state(State.IDLE)
			
	super._physics_process(delta)

func _on_state_changed(new_state: State) -> void:
	if new_state == State.DIE:
		_stop_pulse_effect()

func _start_pulse_effect() -> void:
	if sprite:
		if _charge_pulse_tween and _charge_pulse_tween.is_valid():
			_charge_pulse_tween.kill()
		_charge_pulse_tween = create_tween().set_loops()
		_charge_pulse_tween.tween_property(sprite, "modulate", Color(2.0, 0.5, 0.5, 1.0), 0.5)
		_charge_pulse_tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func _stop_pulse_effect() -> void:
	if _charge_pulse_tween and _charge_pulse_tween.is_valid():
		_charge_pulse_tween.kill()
	if sprite:
		sprite.modulate = Color.WHITE

func _process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO

func _process_move(_delta: float) -> void:
	if is_instance_valid(current_target):
		var dir = (current_target.global_position - global_position).normalized()
		velocity = dir * stats.move_speed
		move_and_slide()
		if sprite and dir.x != 0:
			sprite.flip_h = dir.x > 0

func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	
	if not is_instance_valid(current_target):
		current_attack_phase = AttackPhase.READY
		_pick_nearest_target()
		return
		
	var dist := global_position.distance_to(current_target.global_position)
	
	# Hanya menyerang jika charge sudah penuh
	if not _is_fully_charged:
		# Jika belum penuh tapi di dalam range, tunggu sampai penuh!
		return

	if current_attack_phase == AttackPhase.READY:
		if dist > stats.attack_range:
			change_state(State.MOVE)
		else:
			current_attack_phase = AttackPhase.WINDUP
			_windup_timer = 0.0
			
	elif current_attack_phase == AttackPhase.WINDUP:
		if dist > stats.attack_range + 20.0:
			current_attack_phase = AttackPhase.READY
			change_state(State.MOVE)
			return
			
		_windup_timer += delta
		if _windup_timer >= stats.windup_time:
			if is_instance_valid(current_target):
				_shoot_projectile()
				
			# Reset Charge
			_is_fully_charged = false
			_sparky_charge = 0.0
			_stop_pulse_effect()
			
			current_attack_phase = AttackPhase.COOLDOWN
			_cooldown_timer = 0.0
			
			# Recoil / Impact Juice
			if sprite:
				var base = get_sprite_base_scale()
				var tween = create_tween()
				tween.tween_property(sprite, "scale", Vector2(base.x * 1.3, base.y * 0.7), 0.1)
				tween.tween_property(sprite, "scale", base, 0.2)
				
			# Lompat mundur sedikit (Knockback mandiri menggunakan Tween posisi)
			var dir = (current_target.global_position - global_position).normalized()
			var knockback_tween = create_tween()
			knockback_tween.tween_property(self, "global_position", global_position - dir * 40.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	elif current_attack_phase == AttackPhase.COOLDOWN:
		_cooldown_timer += delta
		if _cooldown_timer >= (1.0 / stats.attack_speed - stats.windup_time):
			current_attack_phase = AttackPhase.READY

func _shoot_projectile() -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	
	var dir = (current_target.global_position - global_position).normalized()
	proj.setup(dir, stats.damage, current_target)

func _pick_nearest_target() -> void:
	if not aggro_area or not aggro_area.monitoring:
		return
	var nearest: Node2D = null
	var nearest_dist: float = INF
	
	if aggro_area:
		for body in aggro_area.get_overlapping_bodies():
			if body is UnitBase and body.is_in_group("players") and body.current_state != State.DIE:
				var d = global_position.distance_to(body.global_position)
				if d < nearest_dist:
					nearest_dist = d
					nearest = body
					
	current_target = nearest

func _on_aggro_entered(body: Node2D) -> void:
	if body is UnitBase and body.is_in_group("players"):
		_pick_nearest_target()

func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		_pick_nearest_target()


