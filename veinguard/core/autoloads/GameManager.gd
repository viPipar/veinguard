extends Node

# --- Signals ---
signal oxygen_changed(new_amount: float)
signal game_over
signal player_won
signal overtime_started
signal time_updated(seconds_remaining: float)
signal heartbeat_rush_started
signal heartbeat_rush_ended

# --- Constants ---
const MAX_OXYGEN         : float = 10.0
const OVERTIME_THRESHOLD : float = 120.0  # 2 menit

# --- State ---
var current_level  : int   = 1
var oxygen_points  : float = 0.0
var wave_number    : int  = 0
var is_game_over   : bool = false
var is_wave_active : bool = false
var match_time     : float = 0.0
var _is_overtime   : bool  = false
var _has_played_last_second: bool = false
var unlocked_level : int = 1

func unlock_next_level() -> void:
	if unlocked_level < 4:
		unlocked_level += 1

# --- Heartbeat Rush state ---
var is_heartbeat_rush : bool  = false
var _heartbeat_timer  : float = 0.0

# --- Passive Oxygen Config ---
@export var passive_oxygen_rate     : float = 0.2  # 0.2 oksigen per detik (1 oksigen per 5s)
@export var passive_oxygen_interval : float = 1.0  # Detik antar tick
var _passive_oxygen_timer : float = 0.0
var is_infinite_oxygen : bool = false


func _process(delta: float) -> void:
	if not is_wave_active or is_game_over:
		return

	# --- Match Timer ---
	match_time += delta
	var remaining: float = max(0.0, OVERTIME_THRESHOLD - match_time)
	time_updated.emit(remaining)

	if remaining <= 60.0 and not _has_played_last_second:
		_has_played_last_second = true
		AudioManager.play_last_second_sfx()

	if match_time >= OVERTIME_THRESHOLD and not _is_overtime:
		_is_overtime = true
		overtime_started.emit()
		# Percepat regen oxygen saat overtime (setengah interval, jadi 1 oksigen per 5s)
		passive_oxygen_interval = 0.5
		print("⚡ OVERTIME! Spawn dan regen dipercepat!")

	# --- Passive Oxygen ---
	if is_infinite_oxygen:
		if oxygen_points < MAX_OXYGEN:
			add_oxygen(MAX_OXYGEN)
	else:
		_passive_oxygen_timer += delta
		if _passive_oxygen_timer >= passive_oxygen_interval:
			_passive_oxygen_timer = 0.0
			add_oxygen(passive_oxygen_rate)

	# --- Heartbeat Rush Timer (Level 2+) ---
	if is_wave_active and current_level >= 2:
		_heartbeat_timer += delta
		if not is_heartbeat_rush:
			if _heartbeat_timer >= 30.0:
				_heartbeat_timer = 0.0
				_start_heartbeat_rush()
		else:
			if _heartbeat_timer >= 5.0: # Durasi 5 detik
				_heartbeat_timer = 0.0
				_end_heartbeat_rush()


func add_oxygen(amount: float) -> void:
	var final_amount = amount
	if is_heartbeat_rush:
		final_amount *= 2.0 # Lipatgandakan pertambahan oksigen saat Heartbeat Rush
	oxygen_points = min(oxygen_points + final_amount, MAX_OXYGEN)
	oxygen_changed.emit(oxygen_points)


func try_spend_oxygen(cost: float) -> bool:
	if oxygen_points < cost:
		return false
	oxygen_points -= cost
	oxygen_changed.emit(oxygen_points)
	return true


func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	if is_heartbeat_rush:
		_end_heartbeat_rush()
	game_over.emit()
	print("GAME OVER!")


func trigger_win() -> void:
	is_game_over = true
	if is_heartbeat_rush:
		_end_heartbeat_rush()
	player_won.emit()
	print("PLAYER MENANG!")


func start_wave() -> void:
	is_wave_active = true
	wave_number   += 1
	match_time     = 0.0
	_is_overtime   = false
	_has_played_last_second = false
	_heartbeat_timer = 0.0
	passive_oxygen_interval = 1.0 # Reset interval ke default
	oxygen_points = MAX_OXYGEN # Mulai wave dengan Oksigen penuh!
	oxygen_changed.emit(oxygen_points)
	print("Wave %d dimulai!" % wave_number)


func end_wave() -> void:
	is_wave_active = false
	if is_heartbeat_rush:
		_end_heartbeat_rush()
	_heartbeat_timer = 0.0


func _start_heartbeat_rush() -> void:
	is_heartbeat_rush = true
	heartbeat_rush_started.emit()
	print("⚡ HEARTBEAT RUSH! Kecepatan gerak bertambah 1.5x!")


func _end_heartbeat_rush() -> void:
	is_heartbeat_rush = false
	heartbeat_rush_ended.emit()
	print("⚡ Aliran darah kembali normal.")
