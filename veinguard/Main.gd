# Main.gd
extends Node2D

@onready var game_over_screen : GameOverScreen = $GameOverScreen


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.player_won.connect(_on_player_won)
	$Lane/EnemyBase.start_spawning()


func _on_game_over() -> void:
	game_over_screen.show_lose()


func _on_player_won() -> void:
	game_over_screen.show_win()
