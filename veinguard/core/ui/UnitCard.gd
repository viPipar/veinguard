# UnitCard.gd — SIMPEL, hanya emit sinyal
class_name UnitCard
extends TextureButton

@export var unit_scene : PackedScene
@export var unit_stats : UnitStats

signal card_toggled(card_node: UnitCard, is_selected: bool)

var is_focused := false
var base_scale := Vector2.ONE
var base_pos   := Vector2.ZERO
var wobble_time:= 0.0


func _ready() -> void:
	pressed.connect(_on_pressed)
	base_scale = scale
	base_pos = position


func _process(delta: float) -> void:
	if is_focused:
		wobble_time += delta * 5.0
		rotation = sin(wobble_time) * 0.05 # sedikit goyang


func _on_pressed() -> void:
	if is_focused:
		# Jika sedang fokus, klik lagi = batal
		set_focus(false)
		card_toggled.emit(self, false)
	else:
		# Jika tidak fokus, fokuskan dan batalkan yang lain
		get_tree().call_group("unit_cards", "set_focus", false)
		set_focus(true)
		card_toggled.emit(self, true)


func set_focus(focused: bool) -> void:
	is_focused = focused
	wobble_time = 0.0
	var tween = create_tween().set_parallel(true)
	if is_focused:
		tween.tween_property(self, "position", base_pos + Vector2(0, -30), 0.2)
		tween.tween_property(self, "scale", base_scale * 1.15, 0.2)
	else:
		rotation = 0.0
		tween.tween_property(self, "position", base_pos, 0.2)
		tween.tween_property(self, "scale", base_scale, 0.2)
