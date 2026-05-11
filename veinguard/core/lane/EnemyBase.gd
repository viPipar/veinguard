# EnemyBase.gd
# Sumber spawn musuh + target PATCHING Trombosit

class_name EnemyBase
extends Area2D

@export var enemy_scene  : PackedScene
@export var spawn_interval: float = 5.0  # detik antar spawn musuh

var _timer : float = 0.0
var _is_patched : bool = false


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
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position


# Dipanggil oleh Trombosit saat PATCHING selesai
func get_patched() -> void:
	_is_patched = true
	GameManager.trigger_win()
	print("Enemy Base berhasil di-PATCH!")
