# PlayerBase.gd
# Base pemain — kalau musuh sampai sini, game over!

class_name PlayerBase
extends Area2D

@onready var sprite : Sprite2D = $Sprite2D

var _float_time : float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if sprite:
		_float_time += delta
		# Efek mengambang (floating) menggunakan gelombang sinus (sin wave)
		# Naik-turun sejauh 8 pixel dengan kecepatan halus
		sprite.position.y = sin(_float_time * 2.5) * 8.0


func _on_body_entered(body: Node2D) -> void:
	# Kalau musuh (enemy) menyentuh base ini
	if body.is_in_group("enemies"):
		GameManager.trigger_game_over()

func take_damage(amount: float) -> void:
	# Jika diserang jarak jauh / melee musuh
	GameManager.trigger_game_over()
