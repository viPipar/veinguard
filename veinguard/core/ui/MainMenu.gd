extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/StartButton
@onready var encyclopedia_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/EncyclopediaButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/CreditsButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/ExitButton
@onready var credits_popup: Panel = $CreditsPopup
@onready var close_button: Button = $CreditsPopup/Margin/VBox/CloseButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/HeaderArea/Title

var _time: float = 0.0

func _ready() -> void:
	credits_popup.visible = false
	credits_popup.modulate.a = 0.0
	credits_popup.scale = Vector2(0.8, 0.8)
	
	# Connect mouse enter and exit signals for buttons to animate them
	for button in [start_button, encyclopedia_button, credits_button, exit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.pivot_offset = button.size / 2.0
		
	close_button.mouse_entered.connect(_on_button_hover.bind(close_button))
	close_button.mouse_exited.connect(_on_button_unhover.bind(close_button))
	close_button.pivot_offset = close_button.size / 2.0

func _process(delta: float) -> void:
	_time += delta
	# Pulse title scale and rotation slightly for a organic/dynamic feel
	var pulse = 1.0 + (sin(_time * 2.0) * 0.03)
	var rot = sin(_time * 1.5) * 0.01
	title_label.scale = Vector2(pulse, pulse)
	title_label.rotation = rot
	# Make sure scale pivot is centered
	title_label.pivot_offset = title_label.size / 2.0

func _on_button_hover(btn: Button) -> void:
	# Make sure pivot_offset is set correctly in case window resized
	btn.pivot_offset = btn.size / 2.0
	var tween = create_tween().set_parallel(true)
	# Smoothly scale up
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Brighten the modulation slightly
	tween.tween_property(btn, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.15)

func _on_button_unhover(btn: Button) -> void:
	var tween = create_tween().set_parallel(true)
	# Smoothly scale back to normal
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _on_start_button_pressed() -> void:
	start_button.pivot_offset = start_button.size / 2.0
	
	# Add a click effect: scale down quickly, then fade out and start
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.08)
	
	# Fade out whole screen
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.3)
	
	await fade_tween.finished
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_encyclopedia_button_pressed() -> void:
	encyclopedia_button.pivot_offset = encyclopedia_button.size / 2.0
	
	# Bounce click effect
	var tween = create_tween()
	tween.tween_property(encyclopedia_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(encyclopedia_button, "scale", Vector2(1.1, 1.1), 0.08)
	
	# Transition fade out
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.25)
	
	await fade_tween.finished
	get_tree().change_scene_to_file("res://core/ui/Encyclopedia.tscn")

func _on_credits_button_pressed() -> void:
	credits_popup.visible = true
	# Center pivot offset
	credits_popup.pivot_offset = credits_popup.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(credits_popup, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_popup, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_exit_button_pressed() -> void:
	# Fade out and quit
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	get_tree().quit()

func _on_close_credits_pressed() -> void:
	credits_popup.pivot_offset = credits_popup.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(credits_popup, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(credits_popup, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	credits_popup.visible = false
