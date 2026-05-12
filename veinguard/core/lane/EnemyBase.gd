class_name EnemyBase
extends Area2D

@export var enemy_scene     : PackedScene
@export var spawn_interval  : float = 12.0
@export var max_enemies     : int   = 5

var _timer      : float = 0.0
var _is_patched : bool  = false


func _process(delta: float) -> void:
	if _is_patched or not GameManager.is_wave_active:
		return

	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position


func get_patched() -> void:
	_is_patched = true
	GameManager.trigger_win()


func start_spawning() -> void:
	GameManager.start_wave()
