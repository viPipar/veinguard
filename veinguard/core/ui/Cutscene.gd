extends Control

@onready var panel_1 : TextureRect = $Panels/Panel1
@onready var panel_2 : TextureRect = $Panels/Panel2
@onready var panel_3 : TextureRect = $Panels/Panel3
@onready var panel_4 : TextureRect = $Panels/Panel4
@onready var skip_btn : Button = $SkipBtn
@onready var prompt_lbl : Label = $PromptLbl

var panel_nodes : Array[TextureRect] = []
var current_step : int = 0
var is_animating : bool = false

func _ready() -> void:
	panel_nodes = [panel_1, panel_2, panel_3, panel_4]
	
	# Load image asset secara dinamis berdasarkan level saat ini
	var lvl = GameManager.current_level
	var path = "res://assets/ui/cutscene/cutsceneLvl" + str(lvl) + ".jpeg"
	
	if not ResourceLoader.exists(path):
		push_warning("[Cutscene] File cutscene tidak ditemukan: " + path + ". Melewati cutscene.")
		_start_game()
		return
		
	var image_tex = load(path)
	if not image_tex:
		push_error("[Cutscene] Gagal memuat file: " + path)
		_start_game()
		return

	# Setup region untuk masing-masing panel secara dinamis berdasarkan ukuran tekstur
	var tex_width = image_tex.get_width()
	var tex_height = image_tex.get_height()
	var panel_height = tex_height / 4
	
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = image_tex
		atlas.region = Rect2(0, i * panel_height, tex_width, panel_height)
		
		panel_nodes[i].texture = atlas
		panel_nodes[i].visible = false
		
		# Set posisi awal di luar layar (slide dari kiri untuk ganjil, kanan untuk genap)
		if i % 2 == 0:
			panel_nodes[i].position.x = -1100 # Dari kiri
		else:
			panel_nodes[i].position.x = 1100  # Dari kanan

	skip_btn.pressed.connect(_on_skip_pressed)
	prompt_lbl.visible = false
	
	# Mulai panel pertama setelah layar hitam sesaat
	await get_tree().create_timer(0.5).timeout
	_show_next_panel()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_screen_tapped()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_screen_tapped()

func _on_screen_tapped() -> void:
	# Jika skip button ditekan, abaikan tap layar biasa
	if skip_btn.get_global_rect().has_point(get_global_mouse_position()):
		return
		
	if is_animating:
		return
		
	if current_step < 4:
		_show_next_panel()
	else:
		_start_game()

func _show_next_panel() -> void:
	if current_step >= 4 or is_animating:
		return
		
	is_animating = true
	var p = panel_nodes[current_step]
	p.visible = true
	
	# Mainkan Tween slide masuk
	var tween = create_tween()
	tween.tween_property(p, "position:x", 0.0, 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	is_animating = false
	current_step += 1
	
	# Jika semua panel sudah tampil, tampilkan teks instruksi lanjut
	if current_step == 4:
		prompt_lbl.visible = true
		_pulse_prompt()
	else:
		# Auto play panel berikutnya setelah 2.5 detik jika pemain tidak melakukan interaksi
		_start_auto_play_timer()

func _start_auto_play_timer() -> void:
	var my_step = current_step
	await get_tree().create_timer(2.5).timeout
	# Hanya panggil jika langkah belum berubah (belum di-tap manual)
	if current_step == my_step and current_step < 4 and not is_animating:
		_show_next_panel()

func _pulse_prompt() -> void:
	if not prompt_lbl.visible:
		return
	var tween = create_tween().set_loops()
	tween.tween_property(prompt_lbl, "modulate:a", 0.3, 0.6)
	tween.tween_property(prompt_lbl, "modulate:a", 1.0, 0.6)

func _on_skip_pressed() -> void:
	_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")
