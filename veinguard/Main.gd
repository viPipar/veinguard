# Main.gd
extends Node2D

@onready var game_over_screen : GameOverScreen = $GameOverScreen

var _hand_manager : HandManager


func _ready() -> void:
	AudioManager.play_in_game_bgm()
	GameManager.game_over.connect(_on_game_over)
	GameManager.player_won.connect(_on_player_won)
	$Lane/EnemyBase.start_spawning()

	# Buat HandManager secara programatik (mengelola 3 kartu di tangan)
	_hand_manager      = HandManager.new()
	_hand_manager.name = "HandManager"
	add_child(_hand_manager)


func _on_game_over() -> void:
	game_over_screen.show_lose()


func _on_player_won() -> void:
	AudioManager.stop_bgm()
	AudioManager.play_winning_sfx()
	game_over_screen.show_win()
