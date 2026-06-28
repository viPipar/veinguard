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
	
	_show_pre_battle_presentation()

func _show_pre_battle_presentation() -> void:
	get_tree().paused = true
	var pres = PreBattlePresentation.new()
	
	# Mapping kartu per level
	var lvl = GameManager.current_level
	var list = []
	
	if lvl == 1:
		list = [
			["res://units/player/eritrosit/eritrosit_stats.tres", "res://assets/ui/unit_cards/card_front_eritrosit.png", "res://assets/ui/unit_cards/card_back_eritrosit.png"],
			["res://units/player/trombosit/trombosit_stats.tres", "res://assets/ui/unit_cards/card_front_trombosit.png", "res://assets/ui/unit_cards/card_back_trombosit.png"],
			["res://units/player/natural_killer/nkiller_stats.tres", "res://assets/ui/unit_cards/card_front_natural_killer.png", "res://assets/ui/unit_cards/card_back_natural_killer.png"],
			["res://units/enemies/bacteria/ecoli_stats.tres", "res://assets/ui/unit_cards/Card Front E. Coli.png", "res://assets/ui/unit_cards/Card Back E.Coli.png"]
		]
	elif lvl == 2:
		list = [
			["res://units/player/killer_t/killert_stats.tres", "res://assets/ui/unit_cards/card_front_t_killer.png", "res://assets/ui/unit_cards/card_back_t_killer.png"],
			["res://units/enemies/streptococcus/streptococcus_stats.tres", "res://assets/ui/unit_cards/Card Front Streptococcus.png", "res://assets/ui/unit_cards/Card Back Streptococcus.png"]
		]
	elif lvl == 3:
		list = [
			["res://units/player/makrofag/makrofag_stats.tres", "res://assets/ui/unit_cards/card_front_makrofag.png", "res://assets/ui/unit_cards/card_back_makrofag.png"],
			["res://units/enemies/hiv/hiv_stats.tres", "res://assets/ui/unit_cards/Card Front HIV.png", "res://assets/ui/unit_cards/Card Back HIV.png"]
		]
	elif lvl == 4:
		list = [
			["res://units/player/limfosit_b/limfosit_b_stats.tres", "res://assets/ui/unit_cards/card_front_limfosit_b.png", "res://assets/ui/unit_cards/card_back_limfosit_b.png"],
			["res://units/enemies/bacteria/clostridium/clostridium_stats.tres", "res://assets/ui/unit_cards/Card Front Clostridium tetani.png", "res://assets/ui/unit_cards/Card Back Clostridium tetani.png"]
		]
		
	for c in list:
		pres.cards_to_show.append({
			"stats": load(c[0]),
			"front": load(c[1]),
			"back": load(c[2])
		})
		
	pres.presentation_finished.connect(func():
		if GameManager.current_level == 1:
			var tut = TutorialManager.new()
			add_child(tut)
		else:
			get_tree().paused = false
	)
	add_child(pres)


func _on_game_over() -> void:
	game_over_screen.show_lose()


func _on_player_won() -> void:
	AudioManager.stop_bgm()
	AudioManager.play_winning_sfx()
	game_over_screen.show_win()
