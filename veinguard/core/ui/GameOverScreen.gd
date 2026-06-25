class_name GameOverScreen
extends CanvasLayer

@onready var result_label  : Label  = $Card/MarginContainer/VBoxContainer/ResultLabel
@onready var message_label : Label  = $Card/MarginContainer/VBoxContainer/MessageLabel
@onready var restart_button: Button = $Card/MarginContainer/VBoxContainer/RestartButton
@onready var card          : PanelContainer = $Card
@onready var overlay       : ColorRect = $Overlay


func _ready() -> void:
	layer        = 10   # Selalu di atas semua layer UI lainnya
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart)
	hide()


func show_win() -> void:
	# Warna hijau menyala untuk menang
	result_label.text  = "MENANG!"
	result_label.modulate = Color(0.3, 0.9, 0.3)
	message_label.text = "Infeksi berhasil dihentikan!\nTubuh aman!"
	
	# Ganti warna border panel menjadi hijau
	var stylebox = card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if stylebox:
		stylebox.border_color = Color(0.2, 0.8, 0.2, 0.8)
		card.add_theme_stylebox_override("panel", stylebox)
		
	# Ganti warna tombol restart menjadi hijau
	_style_button(Color(0.2, 0.6, 0.2))
	
	show()
	_animate_in()
	get_tree().paused = true


func show_lose() -> void:
	# Warna merah menyala untuk kalah
	result_label.text  = "KALAH!"
	result_label.modulate = Color(0.95, 0.15, 0.2)
	message_label.text = "Infeksi menyebar ke organ!\nCoba lagi!"
	
	# Ganti warna border panel menjadi merah
	var stylebox = card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if stylebox:
		stylebox.border_color = Color(0.8, 0.15, 0.25, 0.8)
		card.add_theme_stylebox_override("panel", stylebox)
		
	# Ganti warna tombol restart menjadi merah
	_style_button(Color(0.8, 0.15, 0.25))
	
	show()
	_animate_in()
	get_tree().paused = true


func _animate_in() -> void:
	# Setup awal animasi
	card.scale = Vector2(0.5, 0.5)
	overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Efek pop-up memantul (bounce) pada panel card
	tween.tween_property(card, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Efek fade-in hitam transparan pada background
	tween.tween_property(overlay, "modulate:a", 1.0, 0.3)


func _style_button(theme_color: Color) -> void:
	# Duplikasi stylebox tombol agar dinamis menyesuaikan tema menang/kalah
	var normal_box = restart_button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if normal_box:
		normal_box.bg_color = theme_color
		normal_box.border_color = theme_color.darkened(0.3)
		restart_button.add_theme_stylebox_override("normal", normal_box)
		
	var hover_box = restart_button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	if hover_box:
		hover_box.bg_color = theme_color.lightened(0.15)
		hover_box.border_color = theme_color.darkened(0.2)
		restart_button.add_theme_stylebox_override("hover", hover_box)


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
