class_name EnemyBase
extends Area2D

@export var enemy_scene     : PackedScene
@export var spawn_interval  : float = 12.0
@export var max_enemies     : int   = 5

@export var max_health      : float = 400.0
var current_health          : float
var _health_bar             : Node2D = null

var _timer      : float = 0.0
var _is_patched : bool  = false


func _ready() -> void:
	var lvl = GameManager.current_level
	print("Menjalankan Level: ", lvl)
	
	match lvl:
		2:
			max_health *= 1.5
			spawn_interval /= 1.2
			max_enemies += 1
		3:
			max_health *= 2.0
			spawn_interval /= 1.5
			max_enemies += 2
		4:
			max_health *= 2.5
			spawn_interval /= 2.0
			max_enemies += 4
		5:
			max_health *= 3.5
			spawn_interval /= 2.5
			max_enemies += 6
			
	current_health = max_health
	var hb_scene = load("res://core/ui/HealthBar.tscn")
	if hb_scene:
		_health_bar = hb_scene.instantiate()
		add_child(_health_bar)
		_health_bar.position = Vector2(-24, -180) # Posisikan di atas tumor
		_health_bar.setup(max_health)


func _process(delta: float) -> void:
	if _is_patched or not GameManager.is_wave_active:
		return

	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_enemy()


@export var virus_scene : PackedScene = preload("res://units/enemies/virus/Virus.tscn") if ResourceLoader.exists("res://units/enemies/virus/Virus.tscn") else null

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	# Weighted spawn: 70% bacteria, 30% virus
	var scene_to_spawn = enemy_scene
	
	# Berikan probabilitas 30% untuk spawn Virus jika Virus sudah disetup
	if virus_scene != null and randf() < 0.3:
		scene_to_spawn = virus_scene

	var enemy = scene_to_spawn.instantiate()
	get_parent().add_child(enemy)
	_animate_spawn(enemy)

func spawn_specific_enemy(type: String) -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies + 2:
		return
		
	var scene_to_spawn = enemy_scene
	if type == "virus" and virus_scene != null:
		scene_to_spawn = virus_scene
	elif type == "virus" and virus_scene == null:
		# Fallback if Virus not created yet
		var loaded_virus = load("res://units/enemies/virus/Virus.tscn")
		if loaded_virus:
			scene_to_spawn = loaded_virus
			virus_scene = loaded_virus
			
	var enemy = scene_to_spawn.instantiate()
	get_parent().add_child(enemy)
	_animate_spawn(enemy)

func _animate_spawn(enemy: Node2D) -> void:
	# --- Animasi Spawn Bakteri (Ejection & Elastic Pop) ---
	# 1. Mulai dari posisi agak ke atas (seolah di dalam markas)
	var spawn_pos = global_position
	enemy.global_position = spawn_pos + Vector2(0, -40)
	
	# 2. Set scale awal ke 0 dan sembunyikan alpha
	var final_scale = enemy.scale
	enemy.scale = Vector2.ZERO
	enemy.modulate.a = 0.0
	
	# 3. Jalankan Tween (segaris/paralel)
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Luncurkan keluar (ke bawah ke arah lane) dengan sebaran X acak
	var target_pos = spawn_pos + Vector2(randf_range(-40, 40), 90)
	tween.tween_property(enemy, "global_position", target_pos, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# Perbesar skala ke ukuran aslinya dengan efek memantul
	tween.tween_property(enemy, "scale", final_scale, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# Fading-in
	tween.tween_property(enemy, "modulate:a", 1.0, 0.3)
	_pulse_base()


func _pulse_base() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
		
	var default_scale = sprite.scale
	var tween = create_tween()
	
	# Mengempit/mengontraksi markas (squash ke bawah, stretch ke samping)
	tween.tween_property(sprite, "scale", Vector2(default_scale.x * 1.25, default_scale.y * 0.75), 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Mengembalikan ke bentuk semula dengan pantulan ringan
	tween.tween_property(sprite, "scale", default_scale, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func take_damage(amount: float) -> void:
	if _is_patched:
		return
	current_health = max(0.0, current_health - amount)
	if _health_bar:
		_health_bar.update(current_health, max_health)
		
	# Hit flash effect (berkedip putih sebentar)
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		sprite.modulate = Color(5.0, 5.0, 5.0, 1.0)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
	if current_health <= 0.0:
		get_patched()


func get_patched() -> void:
	_is_patched = true
	GameManager.trigger_win()


func start_spawning() -> void:
	GameManager.start_wave()
	GameManager.overtime_started.connect(_on_overtime)


func _on_overtime() -> void:
	spawn_interval = max(3.0, spawn_interval / 2.0)
	max_enemies   += 2
	print("⚡ EnemyBase: spawn sekarang tiap %.1fs, max %d musuh" % [spawn_interval, max_enemies])
