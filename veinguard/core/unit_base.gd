# unit_base.gd
# Base class untuk SEMUA unit — extends ini di script unit kalian!
# Contoh: class_name Neutrophil extends UnitBase

class_name UnitBase
extends CharacterBody2D

# --- Data (drag file .tres ke slot ini di Inspector) ---
@export var stats : UnitStats

# --- FSM States ---
enum State { IDLE, MOVE, ATTACK, DIE, PATCHING }
var current_state : State = State.IDLE

# --- Runtime ---
var current_hp     : float
var current_target : Node2D = null  # musuh yang sedang diincar

# --- Node refs (assign di _ready() child) ---
@onready var sprite      : AnimatedSprite2D
@onready var aggro_area  : Area2D
@onready var attack_area : Area2D


func _ready() -> void:
	if stats == null:
		push_error("[%s] Stats belum di-assign! Drag file .tres ke Inspector." % name)
		return
	current_hp = stats.max_hp
	_on_ready()  # hook untuk child class


# Override ini di child class untuk setup tambahan
func _on_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:     _process_idle(delta)
		State.MOVE:     _process_move(delta)
		State.ATTACK:   _process_attack(delta)
		State.DIE:      _process_die(delta)
		State.PATCHING: _process_patching(delta)


# --- Override state handlers di child class ---
func _process_idle(_delta: float)     -> void: pass
func _process_attack(_delta: float)   -> void: pass
func _process_patching(_delta: float) -> void: pass


func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	print("[%s] %s → %s" % [name, State.keys()[current_state], State.keys()[new_state]])
	current_state = new_state
	_on_state_changed(new_state)


func _on_state_changed(_new_state: State) -> void:
	pass  # override di child jika perlu react ke transisi state


func take_damage(amount: float) -> void:
	if current_state == State.DIE:
		return
	current_hp -= amount
	_play_hit_effect()
	if current_hp <= 0.0:
		change_state(State.DIE)

var _launch_velocity : Vector2 = Vector2.ZERO
var _is_launched     : bool    = false

func launch(direction: Vector2, speed: float) -> void:
	_launch_velocity = direction * speed
	_is_launched     = true
	change_state(State.MOVE)

func _process_move(delta: float) -> void:
	# Kalau baru diluncurkan, pakai launch velocity dulu
	# lalu perlahan beralih ke move_speed normal
	if _is_launched:
		velocity         = _launch_velocity
		_launch_velocity  = _launch_velocity.move_toward(
			Vector2(0, -stats.move_speed),  # target velocity normal
			300.0 * delta                  # kecepatan transisi
		)
		# Selesai meluncur saat kecepatan sudah hampir normal
		if _launch_velocity.distance_to(Vector2(stats.move_speed, 0)) < 5.0:
			_is_launched = false
	else:
		velocity = Vector2(stats.move_speed, 0)

	move_and_slide()
	

func _play_hit_effect() -> void:
	if not sprite:
		return
	var tween := create_tween()
	# Flash merah
	tween.tween_callback(func(): sprite.modulate = Color.RED)
	tween.tween_interval(0.05)
	# Gepeng sebentar
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.05)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	# Balik warna normal
	tween.tween_callback(func(): sprite.modulate = Color.WHITE)

func _process_die(_delta: float) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
