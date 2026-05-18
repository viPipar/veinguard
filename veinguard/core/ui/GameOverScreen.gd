class_name GameOverScreen
extends CanvasLayer

@onready var result_label  : Label  = $Panel/ResultLabel
@onready var message_label : Label  = $Panel/MessageLabel
@onready var restart_button: Button = $Panel/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart)
	hide()


func show_win() -> void:
	result_label.text  = "MENANG!"
	result_label.modulate = Color.GHOST_WHITE
	message_label.text = "Infeksi berhasil dihentikan!\nTubuh aman!"
	show()
	get_tree().paused = true


func show_lose() -> void:
	result_label.text  = "KALAH!"
	result_label.modulate = Color.RED
	message_label.text = "Infeksi menyebar ke organ!\nCoba lagi!"
	show()
	get_tree().paused = true


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
