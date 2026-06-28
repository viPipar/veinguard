extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/StartButton
@onready var encyclopedia_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/EncyclopediaButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/SettingsButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/CreditsButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/ExitButton
@onready var credits_popup: Panel = $CreditsPopup
@onready var close_button: Button = $CreditsPopup/Margin/VBox/CloseButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/HeaderArea/Title

var _time: float = 0.0
var level_container: VBoxContainer

func _ready() -> void:
	AudioManager.play_idle_bgm()
	credits_popup.visible = false
	credits_popup.modulate.a = 0.0
	credits_popup.scale = Vector2(0.8, 0.8)
	
	# Connect mouse enter and exit signals for buttons to animate them
	for button in [start_button, encyclopedia_button, settings_button, credits_button, exit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.pivot_offset = button.size / 2.0
		
	close_button.mouse_entered.connect(_on_button_hover.bind(close_button))
	close_button.mouse_exited.connect(_on_button_unhover.bind(close_button))
	close_button.pivot_offset = close_button.size / 2.0

	_setup_level_container()

func _setup_level_container() -> void:
	level_container = VBoxContainer.new()
	level_container.add_theme_constant_override("separation", 20)
	level_container.alignment = BoxContainer.ALIGNMENT_CENTER
	level_container.visible = false
	
	var btn_container = $MarginContainer/VBoxContainer/ButtonContainer
	btn_container.get_parent().add_child(level_container)
	btn_container.get_parent().move_child(level_container, btn_container.get_index() + 1)
	
	for i in range(1, 5):
		var btn = Button.new()
		btn.text = "LEVEL " + str(i)
		btn.custom_minimum_size = Vector2(500, 90)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		if i > GameManager.unlocked_level:
			btn.disabled = true
			btn.text += " 🔒"
		
		btn.add_theme_font_override("font", start_button.get_theme_font("font"))
		btn.add_theme_font_size_override("font_size", 40)
		btn.add_theme_stylebox_override("normal", start_button.get_theme_stylebox("normal"))
		btn.add_theme_stylebox_override("hover", start_button.get_theme_stylebox("hover"))
		btn.add_theme_stylebox_override("pressed", start_button.get_theme_stylebox("pressed"))
		btn.add_theme_stylebox_override("focus", start_button.get_theme_stylebox("focus"))
		
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))
		btn.pressed.connect(_on_level_selected.bind(i, btn))
		level_container.add_child(btn)
		
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(500, 90)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_override("font", encyclopedia_button.get_theme_font("font"))
	back_btn.add_theme_font_size_override("font_size", 36)
	back_btn.add_theme_stylebox_override("normal", encyclopedia_button.get_theme_stylebox("normal"))
	back_btn.add_theme_stylebox_override("hover", encyclopedia_button.get_theme_stylebox("hover"))
	back_btn.add_theme_stylebox_override("pressed", encyclopedia_button.get_theme_stylebox("pressed"))
	back_btn.add_theme_stylebox_override("focus", encyclopedia_button.get_theme_stylebox("focus"))
	
	back_btn.mouse_entered.connect(_on_button_hover.bind(back_btn))
	back_btn.mouse_exited.connect(_on_button_unhover.bind(back_btn))
	back_btn.pressed.connect(_on_level_back_pressed.bind(back_btn))
	level_container.add_child(back_btn)

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
	AudioManager.play_select_sfx()
	start_button.pivot_offset = start_button.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.08)
	
	await tween.finished
	$MarginContainer/VBoxContainer/ButtonContainer.visible = false
	level_container.visible = true
	for c in level_container.get_children():
		c.pivot_offset = c.size / 2.0

func _on_level_back_pressed(btn: Button) -> void:
	AudioManager.play_select_sfx()
	btn.pivot_offset = btn.size / 2.0
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished
	level_container.visible = false
	$MarginContainer/VBoxContainer/ButtonContainer.visible = true

func _on_level_selected(level: int, btn: Button) -> void:
	AudioManager.play_select_sfx()
	GameManager.current_level = level
	
	btn.pivot_offset = btn.size / 2.0
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
	
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.3)
	
	await fade_tween.finished
	if level == 1 or level == 2 or level == 3 or level == 4:
		get_tree().change_scene_to_file("res://core/ui/Cutscene.tscn")
	else:
		get_tree().change_scene_to_file("res://main.tscn")

func _on_encyclopedia_button_pressed() -> void:
	AudioManager.play_select_sfx()
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
	AudioManager.play_select_sfx()
	credits_popup.visible = true
	# Center pivot offset
	credits_popup.pivot_offset = credits_popup.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(credits_popup, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(credits_popup, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_settings_button_pressed() -> void:
	AudioManager.play_select_sfx()
	var settings_menu = load("res://core/ui/SettingsMenu.tscn").instantiate()
	add_child(settings_menu)

func _on_exit_button_pressed() -> void:
	AudioManager.play_select_sfx()
	# Fade out and quit
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	get_tree().quit()

func _on_close_credits_pressed() -> void:
	AudioManager.play_select_sfx()
	credits_popup.pivot_offset = credits_popup.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(credits_popup, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(credits_popup, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	credits_popup.visible = false
