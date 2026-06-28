class_name HIVProjectile
extends Area2D

@export var speed: float = 300.0
@export var explosion_radius: float = 80.0

var direction: Vector2 = Vector2.ZERO
var damage: float = 0.0
var _lifetime: float = 0.0

@onready var sprite = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, dmg: float, _target: Node2D) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	# Rotasi sprite (visual)
	if sprite:
		sprite.rotation += 10.0 * delta
		
	_lifetime += delta
	if _lifetime > 5.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is UnitBase and body.is_in_group("players"):
		explode()

func explode() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Area of Effect (AoE) Damage
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if is_instance_valid(player) and player is UnitBase:
			var dist = global_position.distance_to(player.global_position)
			if dist <= explosion_radius:
				player.take_damage(damage)
				
	# Visual Ledakan (AoE Shockwave)
	if sprite:
		sprite.rotation = 0.0
		sprite.modulate = Color(2.0, 0.0, 0.0, 0.7) # Merah menyala transparan
		
		var tween = create_tween()
		tween.set_parallel(true)
		# Target scale disesuaikan dengan explosion_radius (tekstur asli 128px)
		var target_scale = Vector2.ONE * (explosion_radius * 2.5 / 128.0)
		tween.tween_property(sprite, "scale", target_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		tween.set_parallel(false)
		tween.tween_callback(queue_free)
	else:
		queue_free()
