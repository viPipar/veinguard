extends Node

# --- Signals ---
signal oxygen_changed(new_amount: int)
signal game_over
signal player_won

# --- State ---
var oxygen_points  : int  = 0
var wave_number    : int  = 0
var is_game_over   : bool = false
var is_wave_active : bool = false  # ← INI YANG KURANG, tambahkan di sini!

# --- Passive Oxygen Config ---
@export var passive_oxygen_rate : int = 1      # Berapa banyak oxygen yang didapat
@export var passive_oxygen_interval : float = 0.5 # Setiap berapa detik
var _passive_oxygen_timer : float = 0.0

func _process(delta: float) -> void:
	if not is_game_over:
		_passive_oxygen_timer += delta
		if _passive_oxygen_timer >= passive_oxygen_interval:
			_passive_oxygen_timer = 0.0
			add_oxygen(passive_oxygen_rate)
func add_oxygen(amount: int) -> void:
	oxygen_points += amount
	oxygen_changed.emit(oxygen_points)
	print("Oxygen diterima! Total: ", oxygen_points)


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
	player_won.emit()
	print("PLAYER MENANG!")


# --- Dipanggil nanti oleh Trombosit saat mulai jalan ke enemy base ---
func start_wave() -> void:
	is_wave_active = true
	wave_number   += 1
	print("Wave %d dimulai!" % wave_number)


# --- Dipanggil saat wave selesai (menang/kalah) ---
func end_wave() -> void:
	is_wave_active = false
