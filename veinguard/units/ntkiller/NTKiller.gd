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
	
	add_to_group("players")
	
	change_state(State.MOVE)


func _process_move(_delta: float) -> void:
	velocity = Vector2(0, -stats.move_speed)
	move_and_slide()
	sprite.play("walk")


func _process_attack(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= 1.0 / stats.attack_speed:
		_attack_timer = 0.0
		_deal_damage()


func _deal_damage() -> void:
	if not is_instance_valid(current_target):
		change_state(State.MOVE)
		return
	if current_target is UnitBase:
		current_target.take_damage(stats.damage)


func _process_die(_delta: float) -> void:
	sprite.play("die")
	sprite.animation_finished.connect(queue_free)


func _on_aggro_entered(body: Node2D) -> void:
	if body is UnitBase and current_state == State.MOVE:
		current_target = body
		change_state(State.ATTACK)


func _on_aggro_exited(body: Node2D) -> void:
	if body == current_target:
		current_target = null
		change_state(State.MOVE)
