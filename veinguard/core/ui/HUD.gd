class_name HUD
extends CanvasLayer

# --- Node refs ---
@onready var oxygen_label    : Label       = $OxygenLabel
@onready var oxygen_bar      : ProgressBar = $OxygenBar
@onready var timer_label     : Label       = $TimerLabel
@onready var overtime_label  : Label       = $OvertimeLabel


func _ready() -> void:
	GameManager.oxygen_changed.connect(_on_oxygen_changed)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.overtime_started.connect(_on_overtime_started)
	
	# Hubungkan sinyal Heartbeat Rush
	if GameManager.has_signal("heartbeat_rush_started"):
		GameManager.heartbeat_rush_started.connect(_on_heartbeat_rush_started)
	if GameManager.has_signal("heartbeat_rush_ended"):
		GameManager.heartbeat_rush_ended.connect(_on_heartbeat_rush_ended)

	oxygen_bar.min_value   = 0
	oxygen_bar.max_value   = GameManager.MAX_OXYGEN
	oxygen_bar.value       = 0
	oxygen_label.text      = "O₂: 0.0 / %.1f" % GameManager.MAX_OXYGEN
	timer_label.text       = "2:00"
	overtime_label.visible = false
	
	_setup_oxygen_dividers()

func _setup_oxygen_dividers() -> void:
	await get_tree().process_frame # Wait for layout to calculate size
	
	var max_o2 = GameManager.MAX_OXYGEN
	var bar_width = oxygen_bar.size.x
	var bar_height = oxygen_bar.size.y
	
	for i in range(1, int(max_o2)):
		var divider = ColorRect.new()
		divider.color = Color(0, 0, 0, 0.6) # Dark transparent line
		divider.size = Vector2(2, bar_height)
		
		var x_pos = (float(i) / max_o2) * bar_width
		divider.position = Vector2(x_pos - (divider.size.x / 2.0), 0)
		
		oxygen_bar.add_child(divider)



# --- Oxygen ---
func _on_oxygen_changed(amount: float) -> void:
	oxygen_label.text = "O₂: %.1f / %.1f" % [amount, GameManager.MAX_OXYGEN]

	# Smooth bar update
	var tween: Tween = create_tween()
	tween.tween_property(oxygen_bar, "value", float(amount), 0.15)\
		 .set_ease(Tween.EASE_OUT)

	# Update warna bar berdasarkan level
	var ratio : float = float(amount) / float(GameManager.MAX_OXYGEN)
	if ratio < 0.3:
		oxygen_bar.modulate = Color(1.0, 0.3, 0.3)   # merah
	elif ratio < 0.7:
		oxygen_bar.modulate = Color(1.0, 0.85, 0.2)  # kuning
	else:
		oxygen_bar.modulate = Color(0.3, 1.0, 0.5)   # hijau

	# Flash pulse setiap kali oxygen bertambah
	var flash: Tween = create_tween()
	flash.tween_property(oxygen_bar, "modulate:v", 1.5, 0.07)
	flash.tween_property(oxygen_bar, "modulate:v", 1.0, 0.1)


# --- Timer ---
func _on_time_updated(seconds_remaining: float) -> void:
	if seconds_remaining <= 0.0:
		return
	var mins: int = int(seconds_remaining / 60.0)
	var secs: int = int(seconds_remaining) % 60
	timer_label.text = "%d:%02d" % [mins, secs]

	# Warna merah saat < 30 detik
	if seconds_remaining < 30.0:
		timer_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		timer_label.modulate = Color.WHITE


# --- Overtime ---
func _on_overtime_started() -> void:
	timer_label.text       = "OVERTIME"
	timer_label.modulate   = Color(1.0, 0.3, 0.3)
	overtime_label.visible = true

	# Animasi shake overtime label
	var tween: Tween = create_tween().set_loops(6)
	tween.tween_property(overtime_label, "position:x",
		overtime_label.position.x + 6, 0.05)
	tween.tween_property(overtime_label, "position:x",
		overtime_label.position.x - 6, 0.05)
	tween.tween_property(overtime_label, "position:x",
		overtime_label.position.x, 0.05)

# --- Settings ---
func _on_exit_button_pressed() -> void:
	AudioManager.play_select_sfx()
	get_tree().paused = false # Pastikan game tidak di-pause saat keluar
	get_tree().change_scene_to_file("res://core/ui/MainMenu.tscn")

func _on_settings_button_pressed() -> void:
	AudioManager.play_select_sfx()
	var settings_menu = load("res://core/ui/SettingsMenu.tscn").instantiate()
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	settings_menu.tree_exited.connect(func(): get_tree().paused = false)
	add_child(settings_menu)


# --- Heartbeat Rush UI Notification ---
var _heartbeat_label : Label = null

func _setup_heartbeat_label() -> void:
	_heartbeat_label = Label.new()
	_heartbeat_label.text = "⚡ DETAK JANTUNG KENCANG! ⚡\nSemua unit bergerak 1.5x lebih cepat!"
	_heartbeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heartbeat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font = load("res://assets/ui/Font/LilitaOne-Regular.ttf")
	if font:
		_heartbeat_label.add_theme_font_override("font", font)
	_heartbeat_label.add_theme_font_size_override("font_size", 38)
	_heartbeat_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	_heartbeat_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_heartbeat_label.add_theme_constant_override("outline_size", 12)
	
	_heartbeat_label.position = Vector2(100, 300)
	_heartbeat_label.size = Vector2(880, 150)
	_heartbeat_label.visible = false
	add_child(_heartbeat_label)


func _on_heartbeat_rush_started() -> void:
	if _heartbeat_label == null:
		_setup_heartbeat_label()
	_heartbeat_label.visible = true
	
	# Efek denyut detak jantung (pulse animation)
	var tween = create_tween().set_loops()
	_heartbeat_label.pivot_offset = _heartbeat_label.size / 2.0
	tween.tween_property(_heartbeat_label, "scale", Vector2(1.15, 1.15), 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_heartbeat_label, "scale", Vector2(1.0, 1.0), 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _on_heartbeat_rush_ended() -> void:
	if _heartbeat_label:
		_heartbeat_label.visible = false
