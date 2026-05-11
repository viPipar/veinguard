class_name Bacteria
extends UnitBase

var _attack_timer : float = 0.0


func _on_ready() -> void:
	sprite      = $AnimatedSprite2D
	aggro_area  = $AggroArea
	attack_area = $AttackArea

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
	velocity = Vector2.ZERO
	
	# Cek jarak dulu sebelum damage!
	if not is_instance_valid(current_target):
		change_state(State.MOVE)
		return
	
	var dist := global_position.distance_to(current_target.global_position)
	if dist > stats.attack_range:
		# Target masih jauh, kejar dulu
		var dir := global_position.direction_to(current_target.global_position)
		velocity = dir * stats.move_speed
		move_and_slide()
		return
	
	# Baru boleh damage kalau sudah dalam range
	_attack_timer += delta
	if _attack_timer >= 1.0 / stats.attack_speed:
		_attack_timer = 0.0
		current_target.take_damage(stats.damage)

func _process_die(_delta: float) -> void:
	if sprite: sprite.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _on_aggro_entered(body: Node2D) -> void:
	if body == current_target:
		return
	if body is UnitBase and not body.is_in_group("enemies"):
		current_target = body
		change_state(State.ATTACK)


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		current_target = null
		change_state(State.MOVE)
