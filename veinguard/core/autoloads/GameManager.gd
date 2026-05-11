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
