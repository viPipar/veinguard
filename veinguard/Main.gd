# Main.gd
extends Node2D

@onready var game_over_screen : GameOverScreen = $GameOverScreen

var _hand_manager : HandManager


func _ready() -> void:
	AudioManager.play_in_game_bgm()
	GameManager.game_over.connect(_on_game_over)
	GameManager.player_won.connect(_on_player_won)
	$Lane/EnemyBase.start_spawning()

	# Spawn 2 unit Eritrosit tambahan di awal (Balancing Level 2)
	var eritrosit_scene = preload("res://units/player/eritrosit/Eritrosit.tscn")
	if eritrosit_scene:
		for i in range(2):
			var e = eritrosit_scene.instantiate()
			add_child(e)
			e.global_position = Vector2(460 + i * 160, 650)

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
