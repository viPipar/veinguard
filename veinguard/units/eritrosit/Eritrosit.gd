class_name Eritrosit
extends UnitBase

var _carried_oxygen : Oxygen = null
var _target_oxygen  : Oxygen = null

@onready var oxygen_label : Label = $OxygenLabel  # label O2 di atas kepala


func _on_ready() -> void:
	sprite     = $AnimatedSprite2D
	aggro_area = $OxygenDetector

	aggro_area.area_entered.connect(_on_oxygen_detected)
	aggro_area.area_exited.connect(_on_oxygen_lost)

	oxygen_label.visible = false
	oxygen_label.text    = "O₂"
	
	add_to_group("players")
	
	change_state(State.IDLE)  # mulai DIAM


# IDLE — diam, tunggu oxygen
func _process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if sprite: sprite.play("idle")


# MOVE — bergerak ke arah oxygen target (segala arah!)
func _process_move(delta: float) -> void:
	if not is_instance_valid(_target_oxygen):
		change_state(State.IDLE)
		return

	var dir := global_position.direction_to(_target_oxygen.global_position)
	velocity  = dir * stats.move_speed
	move_and_slide()
	if sprite: sprite.play("walk")


# RETURN — balik ke PlayerBase
func _process_attack(_delta: float) -> void:  # pakai slot ATTACK sebagai RETURN
	var base := get_tree().get_first_node_in_group("player_base")
	if not base:
		return

	var dir  := global_position.direction_to(base.global_position)
	velocity  = dir * stats.move_speed
	move_and_slide()
	if sprite: sprite.play("walk")

	if global_position.distance_to(base.global_position) < 60.0:
		_deliver_oxygen()


func _on_oxygen_detected(area: Area2D) -> void:
	if area is Oxygen and _target_oxygen == null and _carried_oxygen == null:
		_target_oxygen = area
		change_state(State.MOVE)


func _on_oxygen_lost(area: Area2D) -> void:
	pass


# Dipanggil saat Eritrosit overlap dengan Oxygen
func _physics_process(delta: float) -> void:
	super(delta)
	# Cek apakah sudah menyentuh target oxygen
	if current_state == State.MOVE and is_instance_valid(_target_oxygen):
		if global_position.distance_to(_target_oxygen.global_position) < 30.0:
			if _target_oxygen.try_pickup():
				_carried_oxygen        = _target_oxygen
				_target_oxygen         = null
				oxygen_label.visible   = true   # tampilkan O2 di atas kepala
				change_state(State.ATTACK)      # ATTACK = RETURN


func _deliver_oxygen() -> void:
	GameManager.add_oxygen(_carried_oxygen.oxygen_value)
	_carried_oxygen.queue_free()
	_carried_oxygen      = null
	oxygen_label.visible = false
	change_state(State.IDLE)


func _process_die(_delta: float) -> void:
	if _carried_oxygen != null:
		_carried_oxygen.drop_back(global_position)
		_carried_oxygen = null
	oxygen_label.visible = false
	if sprite: sprite.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
