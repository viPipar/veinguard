# PlayerBase.gd
# Base pemain — kalau musuh sampai sini, game over!

class_name PlayerBase
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# Kalau musuh (enemy) menyentuh base ini
	if body.is_in_group("enemies"):
		GameManager.trigger_game_over()
