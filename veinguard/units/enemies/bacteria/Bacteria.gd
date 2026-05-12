class_name Bacteria
extends UnitBase

var _attack_timer   : float = 0.0
var _retarget_timer : float = 0.0  # periodic re-check nearest target


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
		if is_instance_valid(current_target):
			current_target.take_damage(stats.damage)

func _process_die(_delta: float) -> void:
	if sprite: sprite.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _pick_nearest_target() -> void:
	var nearest : Node2D = null
	var nearest_dist : float = INF
	for body in aggro_area.get_overlapping_bodies():
		if body is UnitBase and not body.is_in_group("enemies"):
			var d := global_position.distance_to(body.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = body
	current_target = nearest
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
