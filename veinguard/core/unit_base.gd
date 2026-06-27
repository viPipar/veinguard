# unit_base.gd
# Base class untuk SEMUA unit — extends ini di script unit kalian!
# Contoh: class_name Neutrophil extends UnitBase

class_name UnitBase
extends CharacterBody2D

# --- Data (drag file .tres ke slot ini di Inspector) ---
@export var stats : UnitStats
@export var gameplay_scale : float = 1.6

# --- FSM States ---
enum State { IDLE, MOVE, ATTACK, DIE, PATCHING, EAT }
var current_state : State = State.IDLE

# --- Runtime ---
var _proj_velocity  : Vector2 = Vector2.ZERO
var _is_projectile  : bool    = false
var _gravity        : Vector2 = Vector2(0, 980.0)

var current_hp     : float
var current_target : Node2D = null  # musuh yang sedang diincar

# --- Debuffs (Slow & Stun) ---
var is_stunned         : bool  = false
var _active_slow_count : int   = 0
var _active_stun_count : int   = 0
var _original_speed    : float = -1.0

# --- Node refs (assign di _ready() child) ---
@onready var sprite      : AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var aggro_area  : Area2D = get_node_or_null("AggroArea")
@onready var attack_area : Area2D = get_node_or_null("AttackArea")

# --- Health Bar ---
var _health_bar : Node = null   # HealthBar node (lazy-found)


func _ready() -> void:
	scale = Vector2(gameplay_scale, gameplay_scale)
	if stats == null:
		push_error("[%s] Stats belum di-assign! Drag file .tres ke Inspector." % name)
		return
	stats = stats.duplicate() # Duplikasi resource agar perubahan stats bersifat lokal per unit
	current_hp = stats.max_hp
	
	# Hubungkan ke sinyal Heartbeat Rush
	GameManager.heartbeat_rush_started.connect(_on_heartbeat_start)
	GameManager.heartbeat_rush_ended.connect(_on_heartbeat_end)
	if GameManager.is_heartbeat_rush:
		stats.move_speed *= 1.5
		
	_on_ready()  # hook untuk child class
	# Temukan HealthBar child jika ada
	_health_bar = get_node_or_null("HealthBar")
	if _health_bar:
		_health_bar.setup(stats.max_hp)


# Override ini di child class untuk setup tambahan
func _on_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if is_stunned:
		velocity = Vector2.ZERO
		return

	if _is_projectile:
		_proj_velocity += _gravity * delta
		velocity        = _proj_velocity
		move_and_slide()
		if sprite: sprite.rotation = velocity.angle()
		var base := get_tree().get_first_node_in_group("player_base")
		if base and _proj_velocity.y > 0 and \
		   global_position.distance_to(base.global_position) > 150.0:
			_land()
		return
	match current_state:
		State.IDLE:     _process_idle(delta)
		State.MOVE:     _process_move(delta)
		State.ATTACK:   _process_attack(delta)
		State.DIE:      _process_die(delta)
		State.PATCHING: _process_patching(delta)
		State.EAT:      _process_eat(delta)
		
	# Jaga agar semua unit tidak keluar dari layar/arena (pagar batas)
	global_position.x = clamp(global_position.x, 30.0, 1050.0)


# --- Override state handlers di child class ---
func _process_idle(_delta: float)     -> void: pass
func _process_attack(_delta: float)   -> void: pass
func _process_patching(_delta: float) -> void: pass
func _process_eat(_delta: float)      -> void: pass


func change_state(new_state: State) -> void:
	if current_state == State.DIE:
		return # Sekali mati, tidak bisa ganti state lagi!
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
	# Update health bar
	if _health_bar:
		_health_bar.update(current_hp, stats.max_hp)
	if current_hp <= 0.0:
		change_state(State.DIE)

var _launch_velocity : Vector2 = Vector2.ZERO
var _is_launched     : bool    = false

func launch(direction: Vector2, speed: float) -> void:
	_launch_velocity = direction * speed
	_is_launched     = true
	change_state(State.MOVE)

func get_sprite_base_scale() -> Vector2:
	return Vector2.ONE


func _play_hit_effect() -> void:
	if not sprite:
		return
	var tween := create_tween()
	# Flash merah
	tween.tween_callback(func(): sprite.modulate = Color.RED)
	tween.tween_interval(0.05)
	# Gepeng sebentar
	var base_scale := get_sprite_base_scale()
	tween.tween_property(sprite, "scale", base_scale * Vector2(1.3, 0.7), 0.05)
	tween.tween_property(sprite, "scale", base_scale, 0.1)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	# Balik warna normal
	tween.tween_callback(func(): sprite.modulate = Color.WHITE)


var _is_dying : bool = false

func _process_die(_delta: float) -> void:
	if _is_dying:
		return
	_is_dying = true
	
	# Nonaktifkan tabrakan fisik & deteksi area agar tidak memicu aggro/serangan lagi saat mati
	collision_layer = 0
	collision_mask = 0
	if aggro_area:
		aggro_area.monitoring = false
		aggro_area.monitorable = false
	if attack_area:
		attack_area.monitoring = false
		attack_area.monitorable = false
		
	if sprite:
		# Play die animation if available, otherwise stop sprite
		if sprite.sprite_frames.has_animation("die"):
			sprite.play("die")
			sprite.scale = get_sprite_base_scale()
		else:
			sprite.stop()
		var tween := create_tween()
		# Perlahan berubah putih dan fade out
		tween.tween_property(sprite, "modulate", Color(10, 10, 10, 0), 0.5)
		await tween.finished
	else:
		await get_tree().create_timer(0.5).timeout
	queue_free()

func launch_projectile(vel: Vector2) -> void:
	_proj_velocity = vel
	_is_projectile = true
	change_state(State.MOVE)
	

func _process_move(delta: float) -> void:
	if _is_projectile:
		_proj_velocity += _gravity * delta
		velocity        = _proj_velocity
		move_and_slide()

		# Landing: velocity mulai ke bawah & sudah jauh dari base
		var base := get_tree().get_first_node_in_group("player_base")
		if base and _proj_velocity.y > 0 and \
		   global_position.distance_to(base.global_position) > 150.0:
			_land()
	else:
		velocity = Vector2(0, -stats.move_speed)
		move_and_slide()


func _land() -> void:
	_is_projectile = false
	_proj_velocity = Vector2.ZERO
	AudioManager.play_plop_sfx()
	if sprite: sprite.rotation = 0.0
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.08)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)\
			 .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func apply_slow(factor: float, duration: float) -> void:
	if current_state == State.DIE:
		return
	if _original_speed < 0:
		_original_speed = stats.move_speed
	
	# Kurangi move speed (hanya untuk stats duplikat unit ini)
	stats.move_speed = _original_speed * factor
	_active_slow_count += 1
	
	# Visual effect (bluish tint)
	if sprite:
		sprite.modulate = Color(0.6, 0.6, 1.0, 1.0)
		
	await get_tree().create_timer(duration).timeout
	
	if not is_instance_valid(self):
		return
		
	_active_slow_count -= 1
	if _active_slow_count <= 0:
		_active_slow_count = 0
		stats.move_speed = _original_speed
		if sprite and not is_stunned:
			sprite.modulate = Color.WHITE


func apply_stun(duration: float) -> void:
	if current_state == State.DIE:
		return
	is_stunned = true
	_active_stun_count += 1
	velocity = Vector2.ZERO
	
	# Visual effect (greyed out & stop animation)
	if sprite:
		sprite.stop()
		sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
		
	await get_tree().create_timer(duration).timeout
	
	if not is_instance_valid(self):
		return
		
	_active_stun_count -= 1
	if _active_stun_count <= 0:
		_active_stun_count = 0
		is_stunned = false
		if sprite:
			if sprite.sprite_frames.has_animation("walk") and current_state == State.MOVE:
				sprite.play("walk")
			else:
				sprite.play("idle")
			
			# Kembalikan modulate (cek jika masih ada efek slow aktif)
			if _active_slow_count > 0:
				sprite.modulate = Color(0.6, 0.6, 1.0, 1.0)
			else:
				sprite.modulate = Color.WHITE


func _on_heartbeat_start() -> void:
	if current_state == State.DIE:
		return
	stats.move_speed *= 1.5
	if _original_speed >= 0:
		_original_speed *= 1.5
	if sprite:
		sprite.modulate = Color(1.3, 0.7, 0.7, 1.0) # Efek kemerahan karena tekanan darah naik


func _on_heartbeat_end() -> void:
	if not is_instance_valid(self) or current_state == State.DIE:
		return
	stats.move_speed /= 1.5
	if _original_speed >= 0:
		_original_speed /= 1.5
	if sprite:
		if _active_slow_count > 0:
			sprite.modulate = Color(0.6, 0.6, 1.0, 1.0)
		elif is_stunned:
			sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			sprite.modulate = Color.WHITE
