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

	oxygen_bar.min_value   = 0
	oxygen_bar.max_value   = GameManager.MAX_OXYGEN
	oxygen_bar.value       = 0
	oxygen_label.text      = "O₂: 0 / %d" % GameManager.MAX_OXYGEN
	timer_label.text       = "2:00"
	overtime_label.visible = false


# --- Oxygen ---
func _on_oxygen_changed(amount: int) -> void:
	oxygen_label.text = "O₂: %d / %d" % [amount, GameManager.MAX_OXYGEN]

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
