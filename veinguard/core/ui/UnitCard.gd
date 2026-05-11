# UnitCard.gd — SIMPEL, hanya emit sinyal
class_name UnitCard
extends TextureButton

@export var unit_scene : PackedScene
@export var unit_stats : UnitStats

signal card_selected(unit_scene: PackedScene, unit_stats: UnitStats)


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	card_selected.emit(unit_scene, unit_stats)
