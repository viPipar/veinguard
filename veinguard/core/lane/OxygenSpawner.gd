# OxygenSpawner.gd
# Spawn objek Oxygen secara berkala menyebar di sisi kiri/kanan sepanjang lane vertikal
class_name OxygenSpawner
extends Node2D

@export var oxygen_scene    : PackedScene
@export var spawn_interval  : float = 4.0      # detik antar spawn
@export var max_oxygen_count: int   = 5        # maks oxygen di layar sekaligus

# --- PENGATURAN UNTUK MODE PORTRAIT (VERTIKAL) ---
@export var lane_x       : float = 540.0
@export var lane_y_min   : float = 500.0
@export var lane_y_max   : float = 600.0
@export var spawn_x_offset: float = 200.0  # seberapa jauh ke kiri/kanan

var _timer : float = 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_try_spawn()

func _try_spawn() -> void:
	var current_count := get_tree().get_nodes_in_group("oxygen_objects").size()
	if current_count >= max_oxygen_count:
		return

	var oxygen : Oxygen = oxygen_scene.instantiate()
	get_parent().add_child(oxygen)
	oxygen.add_to_group("oxygen_objects")

	var rand_y : float = randf_range(lane_y_min, lane_y_max)
	var side   : float = 1.0 if randi() % 2 == 0 else -1.0

	# Spawn dari luar layar (kiri: x=-50, kanan: x=1130)
	var start_x : float = -50.0 if side < 0 else 1130.0
	# Target masuk ke dalam layar
	var end_x   : float = lane_x + side * spawn_x_offset

	oxygen.global_position = Vector2(start_x, rand_y)

	# Tween masuk dari luar ke dalam
	var tween := oxygen.create_tween()
	tween.tween_property(oxygen, "position:x", end_x, 0.5)\
		 .set_ease(Tween.EASE_OUT)
