extends Area2D

@export var speed: float = 250.0
@export var damage: float = 8.0

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
		
		# Terapkan Slow (50% speed selama 3.0 detik)
		if body.has_method("apply_slow"):
			body.apply_slow(0.5, 3.0)
			print("[ClostridiumProjectile] Terapkan Slow ke: ", body.name)
		
		# Terapkan Stun / Immobilize (100% peluang untuk stun selama 0.2 detik)
		if body.has_method("apply_stun"):
			body.apply_stun(0.2)
			print("[ClostridiumProjectile] Terapkan Stun/Immobilize ke: ", body.name)
			
		queue_free()
	elif body.is_in_group("player_base"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
