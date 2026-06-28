class_name MiniEncyclopediaOverlay
extends CanvasLayer

var _panel: PanelContainer
var _close_btn: Button
var _tab_immune: Button
var _tab_pathogens: Button
var _grid_immune: GridContainer
var _grid_pathogens: GridContainer
var _scroll: ScrollContainer

var _style_active: StyleBoxFlat
var _style_inactive: StyleBoxFlat

var _inspect_overlay: CardInspectOverlay

func _ready() -> void:
	layer = 110 # Di bawah debug menu tapi di atas hud
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()
	_populate_grids()
	_select_tab("immune")

func _build_ui() -> void:
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	
	_panel = PanelContainer.new()
	_panel.size = Vector2(900, 1400)
	var vp = get_viewport().get_visible_rect().size
	_panel.position = Vector2((vp.x - 900) / 2, (vp.y - 1400) / 2)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.corner_radius_top_left = 30
	sb.corner_radius_top_right = 30
	sb.corner_radius_bottom_left = 30
	sb.corner_radius_bottom_right = 30
	sb.border_width_bottom = 10
	sb.border_color = Color(0.05, 0.05, 0.1)
	_panel.add_theme_stylebox_override("panel", sb)
	
	add_child(_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header with title and close btn
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "MINI ENSIKLOPEDIA"
	title.add_theme_font_override("font", load("res://assets/ui/Font/LilitaOne-Regular.ttf"))
	title.add_theme_font_size_override("font_size", 50)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(80, 80)
	var sb_close = StyleBoxFlat.new()
	sb_close.bg_color = Color(0.8, 0.2, 0.2)
	sb_close.corner_radius_top_left = 15
	sb_close.corner_radius_top_right = 15
	sb_close.corner_radius_bottom_left = 15
	sb_close.corner_radius_bottom_right = 15
	_close_btn.add_theme_stylebox_override("normal", sb_close)
	_close_btn.add_theme_font_override("font", load("res://assets/ui/Font/LilitaOne-Regular.ttf"))
	_close_btn.add_theme_font_size_override("font_size", 40)
	_close_btn.pressed.connect(_on_close)
	header.add_child(_close_btn)
	
	# Tabs
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 20)
	vbox.add_child(tabs)
	
	_style_active = StyleBoxFlat.new()
	_style_active.bg_color = Color(0.2, 0.5, 0.8)
	_style_active.corner_radius_top_left = 20
	_style_active.corner_radius_top_right = 20
	_style_active.corner_radius_bottom_left = 20
	_style_active.corner_radius_bottom_right = 20
	_style_active.content_margin_top = 15
	_style_active.content_margin_bottom = 15
	
	_style_inactive = _style_active.duplicate()
	_style_inactive.bg_color = Color(0.3, 0.3, 0.3)
	
	var font = load("res://assets/ui/Font/LilitaOne-Regular.ttf")
	
	_tab_immune = Button.new()
	_tab_immune.text = "PASUKAN"
	_tab_immune.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_immune.add_theme_font_override("font", font)
	_tab_immune.add_theme_font_size_override("font_size", 30)
	_tab_immune.pressed.connect(func(): _select_tab("immune"))
	tabs.add_child(_tab_immune)
	
	_tab_pathogens = Button.new()
	_tab_pathogens.text = "MUSUH"
	_tab_pathogens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_pathogens.add_theme_font_override("font", font)
	_tab_pathogens.add_theme_font_size_override("font_size", 30)
	_tab_pathogens.pressed.connect(func(): _select_tab("pathogens"))
	tabs.add_child(_tab_pathogens)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(scroll_vbox)
	
	_grid_immune = GridContainer.new()
	_grid_immune.columns = 3
	_grid_immune.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_immune.add_theme_constant_override("h_separation", 20)
	_grid_immune.add_theme_constant_override("v_separation", 30)
	scroll_vbox.add_child(_grid_immune)
	
	_grid_pathogens = GridContainer.new()
	_grid_pathogens.columns = 3
	_grid_pathogens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_pathogens.add_theme_constant_override("h_separation", 20)
	_grid_pathogens.add_theme_constant_override("v_separation", 30)
	scroll_vbox.add_child(_grid_pathogens)
	
	_inspect_overlay = CardInspectOverlay.new()
	add_child(_inspect_overlay)

func _populate_grids() -> void:
	var enc_script = preload("res://core/ui/Encyclopedia.gd")
	var immune_entries = enc_script._IMMUNE_ENTRIES
	var pathogen_entries = enc_script._PATHOGEN_ENTRIES
	
	_add_cards_to_grid(_grid_immune, immune_entries)
	_add_cards_to_grid(_grid_pathogens, pathogen_entries)

func _add_cards_to_grid(grid: GridContainer, entries: Array) -> void:
	for entry in entries:
		var is_unlocked = (entry.size() > 3 and entry[3] <= GameManager.unlocked_level)
		if not is_unlocked:
			continue # Mini encyclopedia HANYA menampilkan yang sudah terbuka!
			
		var stats = load(entry[0])
		var front_tex = load(entry[1])
		var back_tex = load(entry[2])
		
		if not stats or not front_tex:
			continue
			
		var card_btn = TextureButton.new()
		card_btn.texture_normal = front_tex
		card_btn.ignore_texture_size = true
		card_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		# Ukuran lebih kecil untuk 3 kolom
		card_btn.custom_minimum_size = Vector2(250, 375)
		card_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		card_btn.pivot_offset = Vector2(125, 187)
		card_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		card_btn.mouse_entered.connect(_on_card_hover.bind(card_btn))
		card_btn.mouse_exited.connect(_on_card_unhover.bind(card_btn))
		card_btn.pressed.connect(_on_card_pressed.bind(stats, front_tex, back_tex))
		
		grid.add_child(card_btn)

func _select_tab(tab_name: String) -> void:
	if tab_name == "immune":
		_grid_immune.show()
		_grid_pathogens.hide()
		_tab_immune.add_theme_stylebox_override("normal", _style_active)
		_tab_pathogens.add_theme_stylebox_override("normal", _style_inactive)
	else:
		_grid_immune.hide()
		_grid_pathogens.show()
		_tab_immune.add_theme_stylebox_override("normal", _style_inactive)
		_tab_pathogens.add_theme_stylebox_override("normal", _style_active)

func _on_card_hover(btn: TextureButton) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)

func _on_card_unhover(btn: TextureButton) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _on_card_pressed(stats, front, back) -> void:
	_inspect_overlay.open(stats, front, back)

func _on_close() -> void:
	get_tree().paused = false
	queue_free()
