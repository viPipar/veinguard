class_name PreBattlePresentation
extends CanvasLayer

var cards_to_show : Array = []
var current_card_index : int = 0

var _bg_dim : ColorRect
var _stack_container : Control
var _next_btn : Button
var _label_info : Label
var _inspect_overlay : CardInspectOverlay

var _card_nodes : Array[TextureButton] = []

signal presentation_finished

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()
	_setup_cards()
	_update_stack_visuals()

func _build_ui() -> void:
	_bg_dim = ColorRect.new()
	_bg_dim.color = Color(0, 0, 0, 0.85)
	_bg_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg_dim)
	
	_label_info = Label.new()
	_label_info.text = "Unit Baru Ditemukan!\nKlik kartu untuk melihat detail."
	_label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_info.add_theme_font_override("font", load("res://assets/ui/Font/LilitaOne-Regular.ttf"))
	_label_info.add_theme_font_size_override("font_size", 50)
	_label_info.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label_info.position.y = 150
	add_child(_label_info)
	
	_stack_container = Control.new()
	_stack_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stack_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stack_container)
	
	_next_btn = Button.new()
	_next_btn.text = "NEXT"
	_next_btn.add_theme_font_override("font", load("res://assets/ui/Font/LilitaOne-Regular.ttf"))
	_next_btn.add_theme_font_size_override("font_size", 60)
	_next_btn.size = Vector2(400, 120)
	var vp = get_viewport().get_visible_rect().size
	_next_btn.position = Vector2((vp.x - 400) / 2, vp.y - 250)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.6, 0.2)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20
	sb.corner_radius_bottom_right = 20
	_next_btn.add_theme_stylebox_override("normal", sb)
	
	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.3, 0.8, 0.3)
	_next_btn.add_theme_stylebox_override("hover", sb_hover)
	
	var sb_press = sb.duplicate()
	sb_press.bg_color = Color(0.1, 0.4, 0.1)
	_next_btn.add_theme_stylebox_override("pressed", sb_press)
	
	_next_btn.pressed.connect(_on_next_pressed)
	add_child(_next_btn)
	
	_inspect_overlay = CardInspectOverlay.new()
	add_child(_inspect_overlay)

func _setup_cards() -> void:
	var vp = get_viewport().get_visible_rect().size
	var center = Vector2(vp.x / 2, vp.y / 2)
	
	# Reverse to draw top card last so it appears on top in the tree
	for i in range(cards_to_show.size() - 1, -1, -1):
		var data = cards_to_show[i]
		var btn = TextureButton.new()
		btn.texture_normal = data.front
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.size = Vector2(500, 750)
		btn.pivot_offset = btn.size / 2
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Agak berantakan secara acak
		var offset_x = randf_range(-40, 40)
		var offset_y = randf_range(-40, 40)
		var rot = randf_range(-15, 15)
		
		btn.position = center - btn.pivot_offset + Vector2(offset_x, offset_y)
		btn.rotation_degrees = rot
		
		btn.pressed.connect(_on_card_pressed.bind(data.stats, data.front, data.back))
		
		_stack_container.add_child(btn)
		
		# We want index 0 to be the top card, but tree order puts it at the back if added first.
		# Since we reversed the loop, index 0 is added last (top).
		# We must prepend to the card_nodes array so index 0 is the top card.
		_card_nodes.insert(0, btn)

func _update_stack_visuals() -> void:
	if current_card_index >= _card_nodes.size():
		_next_btn.text = "MULAI"
		var sb = _next_btn.get_theme_stylebox("normal").duplicate()
		sb.bg_color = Color(0.8, 0.2, 0.2)
		_next_btn.add_theme_stylebox_override("normal", sb)
		return
		
	# Tombol jika kartu terakhir
	if current_card_index == _card_nodes.size() - 1:
		_next_btn.text = "MULAI"
		var sb = _next_btn.get_theme_stylebox("normal").duplicate()
		sb.bg_color = Color(0.8, 0.2, 0.2)
		_next_btn.add_theme_stylebox_override("normal", sb)
	else:
		_next_btn.text = "NEXT"
		var sb = _next_btn.get_theme_stylebox("normal").duplicate()
		sb.bg_color = Color(0.2, 0.6, 0.2)
		_next_btn.add_theme_stylebox_override("normal", sb)
		
	for i in range(_card_nodes.size()):
		var btn = _card_nodes[i]
		if i < current_card_index:
			btn.visible = false
		elif i == current_card_index:
			btn.disabled = false
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)

func _on_card_pressed(stats, front, back) -> void:
	_inspect_overlay.open(stats, front, back)

func _on_next_pressed() -> void:
	if current_card_index >= _card_nodes.size():
		_finish()
		return
		
	var active_btn = _card_nodes[current_card_index]
	active_btn.disabled = true
	
	var tween = create_tween()
	var throw_dir = Vector2(-800 if randf() > 0.5 else 800, -200)
	tween.tween_property(active_btn, "position", active_btn.position + throw_dir, 0.4).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(active_btn, "rotation_degrees", active_btn.rotation_degrees + (180 if throw_dir.x > 0 else -180), 0.4)
	tween.parallel().tween_property(active_btn, "modulate:a", 0.0, 0.4)
	
	current_card_index += 1
	_update_stack_visuals()

func _finish() -> void:
	presentation_finished.emit()
	queue_free()
