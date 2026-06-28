extends CanvasLayer

@onready var tabs = $PanelContainer/VBoxContainer/TabContainer
@onready var player_vbox = $PanelContainer/VBoxContainer/TabContainer/Player/ScrollContainer/VBoxContainer
@onready var enemy_vbox = $PanelContainer/VBoxContainer/TabContainer/Enemy/ScrollContainer/VBoxContainer
@onready var global_vbox = $PanelContainer/VBoxContainer/TabContainer/Global/ScrollContainer/VBoxContainer
@onready var reset_btn = $PanelContainer/VBoxContainer/Header/ResetBtn
@onready var close_btn = $PanelContainer/VBoxContainer/Header/CloseBtn

var _default_values: Dictionary = {}

var unit_stats_paths = [
	"res://units/player/eritrosit/eritrosit_stats.tres",
	"res://units/player/trombosit/trombosit_stats.tres",
	"res://units/player/natural_killer/nkiller_stats.tres",
	"res://units/player/makrofag/makrofag_stats.tres",
	"res://units/player/limfosit_b/limfosit_b_stats.tres",
	"res://units/player/killer_t/killert_stats.tres",
	
	"res://units/enemies/bacteria/ecoli_stats.tres",
	"res://units/enemies/bacteria/clostridium/clostridium_stats.tres",
	"res://units/enemies/bacteria/streptococcus_pneumoniae/bacteria_stats.tres",
	"res://units/enemies/streptococcus/streptococcus_stats.tres",
	"res://units/enemies/hiv/hiv_stats.tres"
]

func _ready() -> void:
	close_btn.pressed.connect(func(): queue_free())
	reset_btn.pressed.connect(_reset_defaults)
	tabs.add_theme_font_size_override("font_size", 32)
	_build_ui()
	_build_global_ui()

func _reset_defaults() -> void:
	for res in _default_values:
		for prop in _default_values[res]:
			res.set(prop, _default_values[res][prop])
	
	for c in player_vbox.get_children(): c.queue_free()
	for c in enemy_vbox.get_children(): c.queue_free()
	for c in global_vbox.get_children(): c.queue_free()
	
	_build_ui()
	_build_global_ui()

func _build_ui() -> void:
	for path in unit_stats_paths:
		if ResourceLoader.exists(path):
			var res = load(path) as UnitStats
			if res:
				_create_unit_panel(res, path)

func _create_unit_panel(stat_res: UnitStats, path: String) -> void:
	var panel = PanelContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = stat_res.unit_name
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	_add_slider(grid, stat_res, "max_hp", 1.0, 2000.0)
	_add_slider(grid, stat_res, "move_speed", 10.0, 500.0)
	_add_slider(grid, stat_res, "damage", 1.0, 500.0)
	_add_slider(grid, stat_res, "attack_range", 10.0, 800.0)
	_add_slider(grid, stat_res, "attack_speed", 0.1, 5.0, 0.1)
	_add_slider(grid, stat_res, "cost", 1.0, 20.0, 1.0)
	
	if "player" in path.to_lower():
		player_vbox.add_child(panel)
	else:
		enemy_vbox.add_child(panel)

func _add_slider(parent: Control, res: Object, prop: String, min_val: float, max_val: float, step: float = 1.0) -> void:
	if not _default_values.has(res):
		_default_values[res] = {}
	var val = res.get(prop)
	if not _default_values[res].has(prop):
		_default_values[res][prop] = val if val != null else min_val
	
	var lbl = Label.new()
	lbl.text = prop.capitalize()
	lbl.custom_minimum_size.x = 280
	lbl.add_theme_font_size_override("font_size", 32)
	parent.add_child(lbl)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	if val == null:
		val = min_val
	slider.value = val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 80
	# Bikin handle lebih besar dengan stretch
	slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(slider)
	
	var val_lbl = Label.new()
	val_lbl.text = str(slider.value)
	val_lbl.custom_minimum_size.x = 120
	val_lbl.add_theme_font_size_override("font_size", 32)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val_lbl)
	
	slider.value_changed.connect(func(v):
		res.set(prop, v)
		val_lbl.text = str(v)
	)

func _build_global_ui() -> void:
	var panel = PanelContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "GLOBAL STATS"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	_add_slider(grid, GameManager, "max_oxygen", 100.0, 5000.0, 50.0)
	_add_slider(grid, GameManager, "passive_oxygen_interval", 0.1, 5.0, 0.1)
	
	global_vbox.add_child(panel)
