class_name LimfositBCloud
extends Area2D

var _eo_stats : LimfositBStats

@onready var life_timer : Timer = $LifeTimer
@onready var tick_timer : Timer = $TickTimer

func setup(stats: LimfositBStats) -> void:
	_eo_stats = stats

func _ready() -> void:
	if not _eo_stats: return
	
	# Set durasi awan racun hidup
	life_timer.wait_time = _eo_stats.dot_duration
	life_timer.one_shot  = true
	if not life_timer.timeout.is_connected(_fade_out_and_free):
		life_timer.timeout.connect(_fade_out_and_free)
	life_timer.start()
	
	# Set interval (tick) damage, misalnya setiap 1 detik
	tick_timer.wait_time = 1.0
	if not tick_timer.timeout.is_connected(_on_tick):
		tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	# --- Animasi Muncul (Cloud Expand & Color Tint) ---
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.scale = Vector2.ZERO
		sprite.modulate = Color(0.85, 0.2, 0.6, 0.0) # Pink asam transparan
		var tween = create_tween()
		tween.set_parallel(true)
		# Mengembang keluar
		tween.tween_property(sprite, "scale", Vector2(0.15, 0.15), 0.4)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Memudar masuk ke opacity target
		tween.tween_property(sprite, "modulate:a", 0.75, 0.4)


func _fade_out_and_free() -> void:
	tick_timer.stop()
	
	# --- Animasi Menghilang (Cloud Shrink & Fade Out) ---
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2.ZERO, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await tween.finished
	queue_free()


func _on_tick() -> void:
	if not _eo_stats:
		return
		
	# Dapatkan semua musuh yang sedang berdiri di genangan racun
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(_eo_stats.dot_damage)
			print("[LimfositBCloud] Memberikan %f DoT ke %s" % [_eo_stats.dot_damage, body.name])
