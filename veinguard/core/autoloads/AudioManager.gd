extends Node

var bgm_player: AudioStreamPlayer
var config_path = "user://audio_settings.cfg"

var select_sfx = preload("res://audio/select.mp3")
var in_game_bgm = preload("res://audio/Stronghold 1 Soundtrack - 03 Castlejam.mp3")
var plop_sfx = preload("res://audio/plop.mp3")
var winning_sfx = preload("res://audio/winning.mp3")
var last_second_sfx = preload("res://audio/Stronghold 1 Soundtrack - 03 Castlejam.mp3")
var sword_slash_sfx = preload("res://audio/54427377-sword-slash-476148.mp3")
var hit_natural_killer_sfx = preload("res://audio/hitnaturaltkiller.mp3")
var eat_sfx = preload("res://audio/audiopapkin-monster-eating-295849.mp3")
var punch_sfx = preload("res://audio/universfield-punch-03-352040.mp3")
var idle_bgm = preload("res://audio/music idle.mp3")

# Volume properties (linear 0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.bus = "Music"
	# Auto loop BGM
	bgm_player.finished.connect(func(): bgm_player.play())
	add_child(bgm_player)
	
	load_settings()
	apply_all_volumes()

func play_select_sfx() -> void:
	_play_one_shot(select_sfx)

func play_plop_sfx() -> void:
	_play_one_shot(plop_sfx)

func play_winning_sfx() -> void:
	bgm_player.stream = winning_sfx
	bgm_player.play()

func play_last_second_sfx() -> void:
	_play_one_shot(last_second_sfx, -5.0)

func play_sword_slash_sfx() -> void:
	_play_one_shot(sword_slash_sfx)

func play_hit_natural_killer_sfx() -> void:
	_play_one_shot(hit_natural_killer_sfx, -12.0)

func play_eat_sfx() -> void:
	_play_one_shot(eat_sfx)

func play_punch_sfx() -> void:
	_play_one_shot(punch_sfx, -12.0)

func _play_one_shot(stream: AudioStream, vol: float = 0.0) -> void:
	var p = AudioStreamPlayer.new()
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.bus = "SFX"
	p.stream = stream
	p.volume_db = vol
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func play_in_game_bgm() -> void:
	if bgm_player.stream != in_game_bgm:
		bgm_player.stream = in_game_bgm
		bgm_player.volume_db = -10.0
	if not bgm_player.playing:
		bgm_player.play()

func play_idle_bgm() -> void:
	if bgm_player.stream != idle_bgm:
		bgm_player.stream = idle_bgm
		bgm_player.volume_db = -8.0
	if not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

# --- Volume Controls ---

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))
	AudioServer.set_bus_mute(bus_idx, master_volume == 0.0)
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))
	AudioServer.set_bus_mute(bus_idx, music_volume == 0.0)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))
	AudioServer.set_bus_mute(bus_idx, sfx_volume == 0.0)
	save_settings()

func apply_all_volumes() -> void:
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(config_path)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(config_path)
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	else:
		master_volume = 1.0
		music_volume = 1.0
		sfx_volume = 1.0
