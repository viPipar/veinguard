extends Control

@onready var panel_1 : TextureRect = $Panels/Panel1
@onready var panel_2 : TextureRect = $Panels/Panel2
@onready var panel_3 : TextureRect = $Panels/Panel3
@onready var panel_4 : TextureRect = $Panels/Panel4
@onready var skip_btn : Button = $SkipBtn
@onready var prompt_lbl : Label = $PromptLbl

var panel_nodes : Array[TextureRect] = []
var current_step : int = 0
var current_page : int = 0
var is_animating : bool = false

func _ready() -> void:
	panel_nodes = [panel_1, panel_2, panel_3, panel_4]
	skip_btn.pressed.connect(_on_skip_pressed)
	prompt_lbl.visible = false
	
	_load_page(0)

func _load_page(page_idx: int) -> void:
	current_page = page_idx
	current_step = 0
	is_animating = false
	prompt_lbl.visible = false
	
	var path = "res://assets/ui/cutscene/cutsceneEd1.png"
	if page_idx == 1:
		path = "res://assets/ui/cutscene/cutsceneEd2.png"
		
	var image_tex = load(path)
	if not image_tex:
		push_error("[CutsceneEnding] Gagal memuat file: " + path)
		_start_game()
		return

	var tex_width = image_tex.get_width()
	var tex_height = image_tex.get_height()
	var panel_height = tex_height / 4
	
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = image_tex
		atlas.region = Rect2(0, i * panel_height, tex_width, panel_height)
		
		panel_nodes[i].texture = atlas
		panel_nodes[i].visible = false
		
		# Set posisi awal di luar layar
		if i % 2 == 0:
			panel_nodes[i].position.x = -1100
		else:
			panel_nodes[i].position.x = 1100

	await get_tree().create_timer(0.5).timeout
	_show_next_panel()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_screen_tapped(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_screen_tapped(event.position)

func _on_screen_tapped(pos: Vector2) -> void:
	if skip_btn.get_global_rect().has_point(pos):
		return
		
	if is_animating:
		return
		
	if current_step < 4:
		_show_next_panel()
	else:
		if current_page == 0:
			_load_page(1)
		else:
			_start_game()

func _show_next_panel() -> void:
	if current_step >= 4 or is_animating:
		return
		
	is_animating = true
	var p = panel_nodes[current_step]
	p.visible = true
	
	var tween = create_tween()
	tween.tween_property(p, "position:x", 0.0, 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	is_animating = false
	current_step += 1
	
	if current_step == 4:
		prompt_lbl.visible = true
		if current_page == 0:
			prompt_lbl.text = "Ketuk untuk lanjut..."
		else:
			prompt_lbl.text = "Ketuk untuk kembali ke Menu..."
		_pulse_prompt()
	else:
		_start_auto_play_timer(current_page, current_step)

func _start_auto_play_timer(page_idx: int, step_idx: int) -> void:
	await get_tree().create_timer(2.5).timeout
	if current_page == page_idx and current_step == step_idx and current_step < 4 and not is_animating:
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
	get_tree().change_scene_to_file("res://core/ui/MainMenu.tscn")
