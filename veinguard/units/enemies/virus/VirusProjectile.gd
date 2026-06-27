extends Area2D

@export var speed: float = 300.0
@export var damage: float = 15.0

var velocity: Vector2 = Vector2.ZERO

func setup(dir: Vector2, dmg: float) -> void:
	velocity = dir.normalized() * speed
	damage = dmg

func _physics_process(delta: float) -> void:
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
