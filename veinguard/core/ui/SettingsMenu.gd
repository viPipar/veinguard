extends CanvasLayer

@onready var master_slider = $Overlay/Panel/MarginContainer/VBoxContainer/MasterContainer/MasterSlider
@onready var music_slider = $Overlay/Panel/MarginContainer/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider = $Overlay/Panel/MarginContainer/VBoxContainer/SFXContainer/SFXSlider
@onready var fullscreen_button = $Overlay/Panel/MarginContainer/VBoxContainer/FullscreenButton
@onready var close_button = $Overlay/Panel/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	# Set initial slider values from AudioManager
	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	
	# Connect signals
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _on_fullscreen_pressed() -> void:
	AudioManager.play_select_sfx()
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	if not $SFXTestPlayer.playing:
		$SFXTestPlayer.play()

func _on_close_pressed() -> void:
	AudioManager.play_select_sfx()
	queue_free()
