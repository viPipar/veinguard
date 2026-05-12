class_name SlingshotController
extends Node2D

@onready var preview_line : Line2D = $PreviewLine
@onready var player_base  : Node2D = get_node("/root/Main/Lane/PlayerBase")

@export var max_drag_distance : float = 250.0
@export var launch_speed_mult : float = 6.0
@export var preview_steps     : int   = 20

var _selected_scene : PackedScene = null
var _selected_stats : UnitStats   = null

enum Phase { IDLE, WAITING_TOUCH, DRAGGING }
var _phase      : Phase   = Phase.IDLE
var _drag_start : Vector2 = Vector2.ZERO


func _ready() -> void:
	preview_line.visible = false
	for card in get_tree().get_nodes_in_group("unit_cards"):
		_connect_card(card)
	get_tree().node_added.connect(func(n): if n is UnitCard: _connect_card(n))


func _connect_card(card: UnitCard) -> void:
	if not card.card_selected.is_connected(_on_card_selected):
		card.card_selected.connect(_on_card_selected)


func _on_card_selected(scene: PackedScene, stats: UnitStats) -> void:
	_selected_scene = scene
	_selected_stats = stats
	_phase          = Phase.WAITING_TOUCH
	print("Kartu dipilih, tunggu drag...")


func _input(event: InputEvent) -> void:
	match _phase:
		Phase.WAITING_TOUCH:
			if _is_press(event):
				_drag_start          = _get_pos(event)
				_phase               = Phase.DRAGGING
				preview_line.visible = true
		Phase.DRAGGING:
			if _is_move(event):
				_update_arc_preview(_get_pos(event))
			elif _is_release(event):
				_launch_unit(_get_pos(event))


func _get_launch_vector(touch_pos: Vector2) -> Vector2:
	var drag_vec := _drag_start - touch_pos
	var clamped  := drag_vec.limit_length(max_drag_distance)
	return clamped * launch_speed_mult


func _update_arc_preview(touch_pos: Vector2) -> void:
	var launch_vel := _get_launch_vector(touch_pos)
	var gravity    := Vector2(0, 980.0)
	var pos        := player_base.global_position
	var vel        := launch_vel
	var dt         := 0.05

	preview_line.clear_points()
	for i in preview_steps:
		preview_line.add_point(to_local(pos))
		vel += gravity * dt
		pos += vel * dt


func _launch_unit(touch_pos: Vector2) -> void:
	preview_line.visible = false
	_phase               = Phase.IDLE

	var launch_vel := _get_launch_vector(touch_pos)

	if launch_vel.length() < 100.0:
		print("Drag terlalu pendek, batal!")
		_reset()
		return

	if not GameManager.try_spend_oxygen(_selected_stats.cost):
		print("Oxygen tidak cukup!")
		_reset()
		return

	var unit : UnitBase = _selected_scene.instantiate()
	get_tree().current_scene.add_child(unit)
	unit.global_position = player_base.global_position
	unit.launch_projectile(launch_vel)
	print("Unit diluncurkan!")
	_reset()


func _reset() -> void:
	_selected_scene = null
	_selected_stats = null
	_phase          = Phase.IDLE


func _is_press(e: InputEvent) -> bool:
	if e is InputEventScreenTouch:  return e.pressed
	if e is InputEventMouseButton:  return e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	return false

func _is_move(e: InputEvent) -> bool:
	if e is InputEventScreenDrag:   return true
	if e is InputEventMouseMotion:  return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	return false

func _is_release(e: InputEvent) -> bool:
	if e is InputEventScreenTouch:  return not e.pressed
	if e is InputEventMouseButton:  return not e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	return false

func _get_pos(e: InputEvent) -> Vector2:
	if e is InputEventScreenTouch:  return e.position
	if e is InputEventScreenDrag:   return e.position
	if e is InputEventMouseButton:  return e.position
	if e is InputEventMouseMotion:  return e.position
	return Vector2.ZERO
