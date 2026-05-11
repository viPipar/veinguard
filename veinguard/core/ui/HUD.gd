class_name HUD
extends CanvasLayer

@onready var oxygen_label : Label = $OxygenLabel


func _ready() -> void:
	GameManager.oxygen_changed.connect(_on_oxygen_changed)
	oxygen_label.text = "O₂: 0"


func _on_oxygen_changed(amount: int) -> void:
	oxygen_label.text = "O₂: %d" % amount
