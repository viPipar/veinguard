# NTKiller.gd

class_name NTKiller
extends UnitBase

var _attack_timer   : float = 0.0
var _retarget_timer : float = 0.0


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


func _process_move(_delta: float) -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
	var dir := global_position.direction_to(current_target.global_position)
	velocity = dir * stats.move_speed
	move_and_slide()
	sprite.play("walk")


func _process_attack(delta: float) -> void:
	# Jika target tidak valid (mati/queue_free), langsung cari target baru
	if not is_instance_valid(current_target):
		_pick_nearest_target()
		return

	# Periodic re-targeting setiap 0.5 detik → pilih yang terdekat
	_retarget_timer += delta
	if _retarget_timer >= 0.5:
		_retarget_timer = 0.0
		_pick_nearest_target()
		return

	# Cek apakah target sudah masuk AttackArea
	var bodies_in_attack := attack_area.get_overlapping_bodies()
	if not current_target in bodies_in_attack:
		# Masih di luar jangkauan serang, kejar target
		var dir := global_position.direction_to(current_target.global_position)
		velocity = dir * stats.move_speed
		move_and_slide()
		sprite.play("walk")
		return

	# Sudah dalam jangkauan serang, berhenti dan deal damage
	velocity = Vector2.ZERO
	move_and_slide()

	_attack_timer += delta
	if _attack_timer >= 1.0 / stats.attack_speed:
		_attack_timer = 0.0
		_deal_damage()


func _deal_damage() -> void:
	if not is_instance_valid(current_target):
		change_state(State.IDLE)
		return
	if current_target is UnitBase:
		current_target.take_damage(stats.damage)


func _process_die(_delta: float) -> void:
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
	# Jika sedang ATTACK, biarkan retarget timer yang handle
	if current_state != State.ATTACK:
		_pick_nearest_target()


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		_retarget_timer = 0.0
		_pick_nearest_target()
