extends Area2D

@export var speed: float = 300.0
@export var damage: float = 15.0

var velocity: Vector2 = Vector2.ZERO
var _target: Node2D = null

func setup(dir: Vector2, dmg: float, target: Node2D = null) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	_target = target

func _physics_process(delta: float) -> void:
	if is_instance_valid(_target):
		var dir = (_target.global_position - global_position).normalized()
		# Interpolasi velocity agar ada efek belok (curve) tidak instan kaku
		velocity = velocity.lerp(dir * speed, 5.0 * delta)
		
	position += velocity * delta
	rotation = velocity.angle()

func _on_body_entered(body: Node2D) -> void:
	if body is UnitBase and body.is_in_group("players"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("player_base"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
