class_name EosinofilProjectile
extends Area2D

@export var cloud_scene : PackedScene
@export var speed       : float = 600.0

var _direction     : Vector2
var _target        : Node2D
var _eo_stats      : EosinophilStats
var _start_pos     : Vector2


func setup(dir: Vector2, target: Node2D, stats: EosinophilStats) -> void:
	_direction = dir
	_target    = target
	_eo_stats  = stats
	_start_pos = global_position
	
	# Memutar proyektil searah dengan arah terbang
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Bergerak lurus ke depan
	position += _direction * speed * delta
	
	# Cek batas jangkauan. Jika terbang melebihi attack_range, meledak otomatis.
	if _eo_stats and global_position.distance_to(_start_pos) >= _eo_stats.attack_range:
		_explode()


func _on_body_entered(body: Node2D) -> void:
	# Jika menabrak musuh, langsung meledak
	if body.is_in_group("enemies"):
		_explode()


func _explode() -> void:
	# Buat awan racun di posisi jatuhnya proyektil
	if cloud_scene and _eo_stats:
		var cloud = cloud_scene.instantiate()
		get_tree().current_scene.add_child(cloud)
		cloud.global_position = global_position
		
		# Setup awan racun dengan stats dari Eosinofil
		if cloud.has_method("setup"):
			cloud.setup(_eo_stats)
			
	# Hancurkan proyektil ini
	queue_free()
