extends CanvasLayer

@onready var add_o2_btn: Button = $PanelContainer/VBoxContainer/AddO2Btn
@onready var sub_o2_btn: Button = $PanelContainer/VBoxContainer/SubO2Btn
@onready var spawn_bac_btn: Button = $PanelContainer/VBoxContainer/SpawnBacBtn
@onready var spawn_vir_btn: Button = $PanelContainer/VBoxContainer/SpawnVirBtn
@onready var panel: PanelContainer = $PanelContainer

func _ready() -> void:
	layer = 120
	visible = false
	
	add_o2_btn.pressed.connect(func(): GameManager.add_oxygen(1.0))
	sub_o2_btn.pressed.connect(func(): GameManager.try_spend_oxygen(1.0))
	
	spawn_bac_btn.pressed.connect(func(): _force_spawn("bacteria"))
	spawn_vir_btn.pressed.connect(func(): _force_spawn("virus"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Toggle with F3 (Keycode 4194334) or Tilde (QuoteLeft 96)
		if event.keycode == KEY_F3 or event.keycode == KEY_QUOTELEFT:
			visible = not visible
			get_viewport().set_input_as_handled()

func _on_toggle_button_pressed() -> void:
	visible = not visible

func _force_spawn(type: String) -> void:
	var enemy_base = get_tree().get_first_node_in_group("enemy_base")
	if enemy_base and enemy_base.has_method("spawn_specific_enemy"):
		enemy_base.spawn_specific_enemy(type)
	else:
		print("EnemyBase tidak memiliki fungsi spawn_specific_enemy atau tidak ditemukan")
