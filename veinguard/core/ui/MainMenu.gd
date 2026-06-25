extends Control

func _on_start_button_pressed() -> void:
	# Transisi ke scene battle (Main.tscn)
	get_tree().change_scene_to_file("res://Main.tscn")
