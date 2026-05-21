class_name EosinofilProjectile
extends Area2D

@export var cloud_scene : PackedScene
@export var speed       : float = 600.0

var _direction     : Vector2
var _target        : Node2D
var _eo_stats      : EosinophilStats
var _start_pos     : Vector2
var _max_distance  : float

func setup(dir: Vector2, target: Node2D, stats: EosinophilStats) -> void:
	_direction = dir
	_target    = target
	_eo_stats  = stats
	_start_pos = global_position
	
	if is_instance_valid(target):
		_max_distance = _start_pos.distance_to(target.global_position)
	else:
		_max_distance = 1000.0 # Default jika musuh keburu mati
	
	# Memutar proyektil searah dengan arah terbang
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Bergerak lurus ke depan
	position += _direction * speed * delta
	
	# Cek batas jangkauan. Meledak tepat di posisi musuh saat ditembakkan.
	if global_position.distance_to(_start_pos) >= _max_distance:
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
