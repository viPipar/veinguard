class_name Trombosit
extends UnitBase

@onready var patch_progress : ProgressBar = $PatchProgress

const PATCH_DURATION : float = 3.0  # detik untuk patching
var _patch_timer     : float = 0.0
var _enemy_base      : Node2D = null


func _on_ready() -> void:
	sprite     = $AnimatedSprite2D
	aggro_area = $AggroArea

	aggro_area.body_entered.connect(_on_body_entered)

	_enemy_base = get_tree().get_first_node_in_group("enemy_base")

	add_to_group("players")
	change_state(State.MOVE)
	patch_progress.visible = false


# Jalan terus ke atas menuju EnemyBase
func _process_move(_delta: float) -> void:
	if not is_instance_valid(_enemy_base):
		return

	var dir  := global_position.direction_to(_enemy_base.global_position)
	velocity  = dir * stats.move_speed
	move_and_slide()
	if sprite: sprite.play("walk")

	# Sampai di EnemyBase → mulai PATCHING
	if global_position.distance_to(_enemy_base.global_position) < 60.0:
		change_state(State.PATCHING)


# PATCHING — diam, hitung timer
func _process_patching(delta: float) -> void:
	velocity             = Vector2.ZERO
	_patch_timer        += delta
	patch_progress.visible = true
	patch_progress.value   = (_patch_timer / PATCH_DURATION) * 100.0
	if sprite: sprite.play("patch")

	if _patch_timer >= PATCH_DURATION:
		_finish_patching()


func _finish_patching() -> void:
	if _enemy_base.has_method("get_patched"):
		_enemy_base.get_patched()
	queue_free()


# Kalau ada musuh di jalan — Trombosit tidak lawan, tapi TETAP jalan
# (dia bukan sel tempur, hanya memperlambat)
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		# Perlambat saat ada musuh
		stats.move_speed = max(20.0, stats.move_speed * 0.5)


func _process_die(_delta: float) -> void:
	if sprite: sprite.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
