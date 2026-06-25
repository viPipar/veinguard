class_name EosinofilProjectile
extends Area2D

@export var cloud_scene : PackedScene
@export var speed       : float = 600.0

var _direction     : Vector2
var _target        : Node2D
var _eo_stats      : EosinophilStats
var _start_pos     : Vector2
var _max_distance  : float
var _trail_points  : Array[Vector2] = []

@onready var trail : Line2D = get_node_or_null("Trail")

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
	
	# --- Squash & Stretch Proyektil (Droplet) ---
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		# Meregang ke depan, memipih ke samping
		sprite.scale = Vector2(0.18, 0.08)
		# Beri warna merah-muda asam menyala khas eosinofil
		sprite.modulate = Color(1.0, 0.35, 0.72)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if trail:
		# Supaya koordinat line2d tetap berada di world space
		trail.set_as_top_level(true)
		trail.clear_points()


func _process(delta: float) -> void:
	# Bergerak lurus ke depan
	position += _direction * speed * delta
	
	# --- Update Trail Line2D ---
	if trail:
		_trail_points.push_back(global_position)
		if _trail_points.size() > 10:
			_trail_points.pop_front()
		
		trail.clear_points()
		for pt in _trail_points:
			trail.add_point(pt)
	
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
