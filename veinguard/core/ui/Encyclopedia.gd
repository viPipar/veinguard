extends Control

@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/HeaderArea/Title

const _IMMUNE_ENTRIES: Array = [
	[
		"res://units/player/natural_killer/nkiller_stats.tres",
		"res://assets/ui/unit_cards/card_front_natural_killer.png",
		"res://assets/ui/unit_cards/card_back_natural_killer.png",
	],
	[
		"res://units/player/eritrosit/eritrosit_stats.tres",
		"res://assets/ui/unit_cards/card_front_eritrosit.png",
		"res://assets/ui/unit_cards/card_back_eritrosit.png",
	],
	[
		"res://units/player/trombosit/trombosit_stats.tres",
		"res://assets/ui/unit_cards/card_front_trombosit.png",
		"res://assets/ui/unit_cards/card_back_trombosit.png",
	],
	[
		"res://units/player/killer_t/killert_stats.tres",
		"res://assets/ui/unit_cards/card_front_t_killer.png",
		"res://assets/ui/unit_cards/card_back_t_killer.png",
	],
	[
		"res://units/player/limfosit_b/limfosit_b_stats.tres",
		"res://assets/ui/unit_cards/card_front_limfosit_b.png",
		"res://assets/ui/unit_cards/card_back_limfosit_b.png",
	],
	[
		"res://units/player/Makrofag/makrofag_stats.tres",
		"res://assets/ui/unit_cards/card_front_makrofag.png",
		"res://assets/ui/unit_cards/card_back_makrofag.png",
	],
]

const _PATHOGEN_ENTRIES: Array = [
	[
		"res://units/enemies/bacteria/clostridium/clostridium_stats.tres",
		"res://assets/ui/unit_cards/Card Front Clostridium tetani.png",
		"res://assets/ui/unit_cards/Card Back Clostridium tetani.png",
	],
	[
		"res://units/enemies/streptococcus/streptococcus_stats.tres",
		"res://assets/ui/unit_cards/Card Front Streptococcus.png",
		"res://assets/ui/unit_cards/Card Back Streptococcus.png",
	],
	[
		"res://units/enemies/hiv/hiv_stats.tres",
		"res://assets/ui/unit_cards/Card Front HIV.png",
		"res://assets/ui/unit_cards/Card Back HIV.png",
	],
	[
		"res://units/enemies/bacteria/ecoli_stats.tres",
		"res://assets/ui/unit_cards/Card Front E. Coli.png",
		"res://assets/ui/unit_cards/Card Back E.Coli.png",
	],
]

var _inspect_overlay: CardInspectOverlay = null
var _time: float = 0.0

# Dynamic tab references
var _tab_immune: Button = null
var _tab_pathogens: Button = null
var _immune_grid_container: GridContainer = null
var _pathogen_grid_container: GridContainer = null

# Styleboxes
var _style_inactive: StyleBoxFlat = null
var _style_active_immune: StyleBoxFlat = null
var _style_active_pathogens: StyleBoxFlat = null

func _ready() -> void:
	# Add the inspect overlay programmatically
	_inspect_overlay = CardInspectOverlay.new()
	_inspect_overlay.name = "CardInspectOverlay"
	add_child(_inspect_overlay)
	
	# Connect back button signals
	back_button.mouse_entered.connect(_on_button_hover.bind(back_button))
	back_button.mouse_exited.connect(_on_button_unhover.bind(back_button))
	back_button.pivot_offset = back_button.size / 2.0
	back_button.pressed.connect(_on_back_pressed)
	
	# Setup custom styleboxes for tabs
	_setup_tab_styles()
	
	# Create tab headers container
	_setup_tabs_ui()
	
	# Populate grids
	_populate_grids()
	
	# Select default tab
	_select_tab("immune", false)

func _process(delta: float) -> void:
	_time += delta
	# Subtle floating rotation for title
	title_label.rotation = sin(_time * 1.5) * 0.01

func _setup_tab_styles() -> void:
	_style_inactive = StyleBoxFlat.new()
	_style_inactive.bg_color = Color(0.12, 0.05, 0.08, 0.6)
	_style_inactive.border_color = Color(0.3, 0.3, 0.3, 0.4)
	_style_inactive.border_width_left = 2
	_style_inactive.border_width_top = 2
	_style_inactive.border_width_right = 2
	_style_inactive.border_width_bottom = 2
	_style_inactive.corner_radius_top_left = 18
	_style_inactive.corner_radius_top_right = 18
	_style_inactive.corner_radius_bottom_right = 18
	_style_inactive.corner_radius_bottom_left = 18
	
	_style_active_immune = StyleBoxFlat.new()
	_style_active_immune.bg_color = Color(0.08, 0.25, 0.35, 0.8) # Dark cyan
	_style_active_immune.border_color = Color(0.3, 0.9, 1.0) # Bright cyan glow
	_style_active_immune.border_width_left = 2
	_style_active_immune.border_width_top = 2
	_style_active_immune.border_width_right = 2
	_style_active_immune.border_width_bottom = 2
	_style_active_immune.corner_radius_top_left = 18
	_style_active_immune.corner_radius_top_right = 18
	_style_active_immune.corner_radius_bottom_right = 18
	_style_active_immune.corner_radius_bottom_left = 18
	
	_style_active_pathogens = StyleBoxFlat.new()
	_style_active_pathogens.bg_color = Color(0.35, 0.08, 0.15, 0.8) # Dark red
	_style_active_pathogens.border_color = Color(0.95, 0.25, 0.35) # Bright red/pink glow
	_style_active_pathogens.border_width_left = 2
	_style_active_pathogens.border_width_top = 2
	_style_active_pathogens.border_width_right = 2
	_style_active_pathogens.border_width_bottom = 2
	_style_active_pathogens.corner_radius_top_left = 18
	_style_active_pathogens.corner_radius_top_right = 18
	_style_active_pathogens.corner_radius_bottom_right = 18
	_style_active_pathogens.corner_radius_bottom_left = 18

func _setup_tabs_ui() -> void:
	var vbox = $MarginContainer/VBoxContainer
	
	var tabs_container = HBoxContainer.new()
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_container.add_theme_constant_override("separation", 30)
	vbox.add_child(tabs_container)
	# Insert below HeaderArea (index 1) and above ScrollContainer (index 2)
	vbox.move_child(tabs_container, 1)
	
	# Immune Tab Button
	_tab_immune = Button.new()
	_tab_immune.text = "IMMUNE CELLS"
	_tab_immune.custom_minimum_size = Vector2(340, 70)
	_tab_immune.add_theme_font_override("font", back_button.get_theme_font("font"))
	_tab_immune.add_theme_font_size_override("font_size", 28)
	_tab_immune.pressed.connect(func(): _select_tab("immune", true))
	tabs_container.add_child(_tab_immune)
	
	# Pathogens Tab Button
	_tab_pathogens = Button.new()
	_tab_pathogens.text = "PATHOGENS & ENEMIES"
	_tab_pathogens.custom_minimum_size = Vector2(340, 70)
	_tab_pathogens.add_theme_font_override("font", back_button.get_theme_font("font"))
	_tab_pathogens.add_theme_font_size_override("font_size", 28)
	_tab_pathogens.pressed.connect(func(): _select_tab("pathogens", true))
	tabs_container.add_child(_tab_pathogens)

func _populate_grids() -> void:
	# Clear existing children from scroll container
	for child in scroll_container.get_children():
		child.queue_free()
		
	# Create parent VBoxContainer inside ScrollContainer
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(scroll_vbox)
	
	# Create Immune Grid
	_immune_grid_container = GridContainer.new()
	_immune_grid_container.columns = 2
	_immune_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_immune_grid_container.add_theme_constant_override("h_separation", 40)
	_immune_grid_container.add_theme_constant_override("v_separation", 50)
	scroll_vbox.add_child(_immune_grid_container)
	_add_cards_to_grid(_immune_grid_container, _IMMUNE_ENTRIES)
	
	# Create Pathogen Grid
	_pathogen_grid_container = GridContainer.new()
	_pathogen_grid_container.columns = 2
	_pathogen_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pathogen_grid_container.add_theme_constant_override("h_separation", 40)
	_pathogen_grid_container.add_theme_constant_override("v_separation", 50)
	scroll_vbox.add_child(_pathogen_grid_container)
	_add_cards_to_grid(_pathogen_grid_container, _PATHOGEN_ENTRIES)

func _add_cards_to_grid(grid: GridContainer, entries: Array) -> void:
	for entry in entries:
		var stats: UnitStats = load(entry[0])
		var front_tex: Texture2D = load(entry[1])
		var back_tex: Texture2D = load(entry[2])
		
		if not stats or not front_tex:
			continue
			
		# Create a button container/frame for the card preview
		var card_btn := TextureButton.new()
		card_btn.texture_normal = front_tex
		card_btn.ignore_texture_size = true
		card_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		# Set card dimensions
		card_btn.custom_minimum_size = Vector2(440, 660)
		card_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Set pivot offset for hover scale
		card_btn.pivot_offset = Vector2(220, 330)
		card_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Connect signals
		card_btn.mouse_entered.connect(_on_card_hover.bind(card_btn))
		card_btn.mouse_exited.connect(_on_card_unhover.bind(card_btn))
		card_btn.pressed.connect(_on_card_pressed.bind(stats, front_tex, back_tex))
		
		grid.add_child(card_btn)

func _select_tab(tab_name: String, play_sfx: bool) -> void:
	if play_sfx:
		AudioManager.play_select_sfx()
		
	if tab_name == "immune":
		_immune_grid_container.show()
		_pathogen_grid_container.hide()
		
		# Style active tab
		_tab_immune.add_theme_stylebox_override("normal", _style_active_immune)
		_tab_immune.add_theme_stylebox_override("hover", _style_active_immune)
		_tab_immune.add_theme_stylebox_override("pressed", _style_active_immune)
		_tab_immune.add_theme_stylebox_override("focus", _style_active_immune)
		_tab_immune.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0)) # Cyan text
		
		# Style inactive tab
		_tab_pathogens.add_theme_stylebox_override("normal", _style_inactive)
		_tab_pathogens.add_theme_stylebox_override("hover", _style_inactive)
		_tab_pathogens.add_theme_stylebox_override("pressed", _style_inactive)
		_tab_pathogens.add_theme_stylebox_override("focus", _style_inactive)
		_tab_pathogens.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)) # Muted grey text
	else:
		_immune_grid_container.hide()
		_pathogen_grid_container.show()
		
		# Style active tab
		_tab_pathogens.add_theme_stylebox_override("normal", _style_active_pathogens)
		_tab_pathogens.add_theme_stylebox_override("hover", _style_active_pathogens)
		_tab_pathogens.add_theme_stylebox_override("pressed", _style_active_pathogens)
		_tab_pathogens.add_theme_stylebox_override("focus", _style_active_pathogens)
		_tab_pathogens.add_theme_color_override("font_color", Color(0.95, 0.25, 0.35)) # Reddish text
		
		# Style inactive tab
		_tab_immune.add_theme_stylebox_override("normal", _style_inactive)
		_tab_immune.add_theme_stylebox_override("hover", _style_inactive)
		_tab_immune.add_theme_stylebox_override("pressed", _style_inactive)
		_tab_immune.add_theme_stylebox_override("focus", _style_inactive)
		_tab_immune.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7)) # Muted grey text

func _on_card_hover(btn: TextureButton) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.15)

func _on_card_unhover(btn: TextureButton) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _on_card_pressed(stats: UnitStats, front_tex: Texture2D, back_tex: Texture2D) -> void:
	_inspect_overlay.open(stats, front_tex, back_tex)

func _on_button_hover(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.15)

func _on_button_unhover(btn: Button) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _on_back_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(back_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(back_button, "scale", Vector2(1.1, 1.1), 0.08)
	
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.25)
	
	await fade_tween.finished
	get_tree().change_scene_to_file("res://core/ui/MainMenu.tscn")
