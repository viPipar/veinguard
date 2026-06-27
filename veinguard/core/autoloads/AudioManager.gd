extends Node

var bgm_player: AudioStreamPlayer

var select_sfx = preload("res://audio/select.mp3")
var in_game_bgm = preload("res://audio/Stronghold 1 Soundtrack - 03 Castlejam.mp3")
var plop_sfx = preload("res://audio/plop.mp3")
var winning_sfx = preload("res://audio/winning.mp3")
var last_second_sfx = preload("res://audio/Stronghold 1 Soundtrack - 03 Castlejam.mp3")

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)

func play_select_sfx() -> void:
	_play_one_shot(select_sfx)

func play_plop_sfx() -> void:
	_play_one_shot(plop_sfx)

func play_winning_sfx() -> void:
	bgm_player.stream = winning_sfx
	bgm_player.play()

func play_last_second_sfx() -> void:
	_play_one_shot(last_second_sfx)

func _play_one_shot(stream: AudioStream) -> void:
	var p = AudioStreamPlayer.new()
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func play_in_game_bgm() -> void:
	if bgm_player.stream != in_game_bgm:
		bgm_player.stream = in_game_bgm
	if not bgm_player.playing:
		bgm_player.play()



func stop_bgm() -> void:
	bgm_player.stop()
