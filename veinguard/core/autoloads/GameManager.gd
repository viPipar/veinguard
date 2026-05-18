extends Node

# --- Signals ---
signal oxygen_changed(new_amount: int)
signal game_over
signal player_won
signal overtime_started
signal time_updated(seconds_remaining: float)

# --- Constants ---
const MAX_OXYGEN         : int   = 1000
const OVERTIME_THRESHOLD : float = 120.0  # 2 menit

# --- State ---
var oxygen_points  : int  = 0
var wave_number    : int  = 0
var is_game_over   : bool = false
var is_wave_active : bool = false
var match_time     : float = 0.0
var _is_overtime   : bool  = false

# --- Passive Oxygen Config ---
@export var passive_oxygen_rate     : int   = 10    # oxygen per tick
@export var passive_oxygen_interval : float = 0.25  # detik antar tick
var _passive_oxygen_timer : float = 0.0


func _process(delta: float) -> void:
	if is_game_over:
		return

	# --- Match Timer ---
	match_time += delta
	var remaining: float = max(0.0, OVERTIME_THRESHOLD - match_time)
	time_updated.emit(remaining)

	if match_time >= OVERTIME_THRESHOLD and not _is_overtime:
		_is_overtime = true
		overtime_started.emit()
		# Percepat regen oxygen saat overtime
		passive_oxygen_interval = max(0.1, passive_oxygen_interval / 2.0)
		print("⚡ OVERTIME! Spawn dan regen dipercepat!")

	# --- Passive Oxygen ---
	_passive_oxygen_timer += delta
	if _passive_oxygen_timer >= passive_oxygen_interval:
		_passive_oxygen_timer = 0.0
		add_oxygen(passive_oxygen_rate)


func add_oxygen(amount: int) -> void:
	oxygen_points = min(oxygen_points + amount, MAX_OXYGEN)
	oxygen_changed.emit(oxygen_points)


func try_spend_oxygen(cost: int) -> bool:
	if oxygen_points < cost:
		return false
	oxygen_points -= cost
	oxygen_changed.emit(oxygen_points)
	return true


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit()
	print("GAME OVER!")


func trigger_win() -> void:
	is_game_over = true
	player_won.emit()
	print("PLAYER MENANG!")


func start_wave() -> void:
	is_wave_active = true
	wave_number   += 1
	match_time     = 0.0
	_is_overtime   = false
	print("Wave %d dimulai!" % wave_number)


func end_wave() -> void:
	is_wave_active = false
