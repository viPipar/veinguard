# NTKiller.gd

class_name NTKiller
extends UnitBase

var _attack_timer : float = 0.0


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

	aggro_area.body_entered.connect(_on_aggro_entered)
	aggro_area.body_exited.connect(_on_aggro_exited)
	attack_area.body_entered.connect(_on_attack_entered)
	attack_area.body_exited.connect(_on_attack_exited)
	
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
		change_state(State.MOVE)
	else:
		change_state(State.IDLE)


func _on_aggro_entered(_body: Node2D) -> void:
	if current_state == State.IDLE or current_state == State.MOVE:
		_pick_nearest_target()


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		_pick_nearest_target()


func _on_attack_entered(body: Node2D) -> void:
	# Musuh masuk jangkauan serang → langsung ATTACK
	if body is UnitBase and body.is_in_group("enemies"):
		if current_state == State.MOVE:
			current_target = body
			change_state(State.ATTACK)


func _on_attack_exited(body: Node2D) -> void:
	# Musuh keluar jangkauan serang → kejar lagi jika masih di aggro
	if body == current_target:
		var still_in_aggro := aggro_area.get_overlapping_bodies()
		if current_target in still_in_aggro:
			change_state(State.MOVE)
		else:
			_pick_nearest_target()
