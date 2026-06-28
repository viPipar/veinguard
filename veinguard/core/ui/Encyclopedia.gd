extends Control

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/HeaderArea/Title

const _POOL_ENTRIES: Array = [
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

var _inspect_overlay: CardInspectOverlay = null
var _time: float = 0.0

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
	
	# Populate the grid with cards
	_populate_grid()

func _process(delta: float) -> void:
	_time += delta
	# Subtle floating rotation for title
	title_label.rotation = sin(_time * 1.5) * 0.01

func _populate_grid() -> void:
	# Clear existing children just in case
	for child in grid_container.get_children():
		child.queue_free()
		
	for entry in _POOL_ENTRIES:
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
		
		# Set card dimensions: we want them to look good in 2 columns (e.g. 450x675)
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
		
		grid_container.add_child(card_btn)

func _on_card_hover(btn: TextureButton) -> void:
	var tween = create_tween().set_parallel(true)
	# Zoom card up
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
	# Click bounce and transition back to menu
	var tween = create_tween()
	tween.tween_property(back_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(back_button, "scale", Vector2(1.1, 1.1), 0.08)
	
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.25)
	
	await fade_tween.finished
	get_tree().change_scene_to_file("res://core/ui/MainMenu.tscn")
