# Lane.gd
# Scene utama "pembuluh darah" — container semua yang ada di map

class_name Lane
extends Node2D

# Referensi ke sub-scene penting (assign di Inspector)
@onready var player_base     : Area2D  = $PlayerBase
@onready var enemy_base      : Area2D  = $EnemyBase
@onready var unit_spawn_point: Marker2D = $UnitSpawnPoint
@onready var oxygen_zone     : Area2D  = $OxygenZone
@export var bacteria_scene : PackedScene

func _ready() -> void:
	# Spawn 1 bacteria untuk testing
	if bacteria_scene:
		var b = bacteria_scene.instantiate()
		add_child(b)
		b.global_position = Vector2(540, 200)
		enemy_base.start_spawning()
