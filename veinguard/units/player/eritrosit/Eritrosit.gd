class_name Eritrosit
extends UnitBase

var _carried_oxygen : Oxygen = null
var _target_oxygen  : Oxygen = null

@onready var oxygen_label : Label = $OxygenLabel


func _on_ready() -> void:
	sprite     = $AnimatedSprite2D
	aggro_area = $OxygenDetector
	aggro_area.area_entered.connect(_on_oxygen_detected)
	oxygen_label.visible = false
	oxygen_label.text    = "O₂"
	add_to_group("players")
	change_state(State.IDLE)


func _process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func _process_move(_delta: float) -> void:
	if not is_instance_valid(_target_oxygen):
		_scan_existing_oxygen()
		return
	# Jika oxygen target sudah diambil eritrosit lain, cari target baru
	if _target_oxygen._is_taken:
		_target_oxygen = null
		_scan_existing_oxygen()
		return
	var dir  := global_position.direction_to(_target_oxygen.global_position)
	velocity  = dir * stats.move_speed
	move_and_slide()
	if global_position.distance_to(_target_oxygen.global_position) < 30.0:
		if _target_oxygen.try_pickup():
			_carried_oxygen      = _target_oxygen
			_target_oxygen       = null
			oxygen_label.visible = true
			change_state(State.ATTACK)
		else:
			# try_pickup gagal (race condition), cari oxygen lain
			_target_oxygen = null
			_scan_existing_oxygen()


func _process_attack(_delta: float) -> void:
	var base := get_tree().get_first_node_in_group("player_base")
	if not base:
		return
	var dir  := global_position.direction_to(base.global_position)
	velocity  = dir * stats.move_speed
	move_and_slide()
	if global_position.distance_to(base.global_position) < 60.0:
		_deliver_oxygen()


func _deliver_oxygen() -> void:
	if not is_instance_valid(_carried_oxygen):
		return
	GameManager.add_oxygen(_carried_oxygen.oxygen_value)
	_carried_oxygen.queue_free()
	_carried_oxygen      = null
	oxygen_label.visible = false
	_scan_existing_oxygen()


func _process_die(_delta: float) -> void:
	if is_instance_valid(_carried_oxygen):
		_carried_oxygen.drop_back(global_position)
		_carried_oxygen = null
	oxygen_label.visible = false
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _on_oxygen_detected(area: Area2D) -> void:
	if area is Oxygen and _carried_oxygen == null and not area._is_taken:
		# Ambil target baru jika belum punya target, atau target lama sudah diambil orang lain
		if _target_oxygen == null or _target_oxygen._is_taken:
			_target_oxygen = area
			change_state(State.MOVE)


func _scan_existing_oxygen() -> void:
	var nearest      : Oxygen = null
	var nearest_dist : float  = INF
	for o in get_tree().get_nodes_in_group("oxygen_objects"):
		if o._is_taken:
			continue
		var d := global_position.distance_to(o.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest      = o
	if nearest:
		_target_oxygen = nearest
		change_state(State.MOVE)
	else:
		change_state(State.IDLE)
