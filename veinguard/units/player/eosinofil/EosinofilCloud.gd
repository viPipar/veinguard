class_name EosinofilCloud
extends Area2D

var _eo_stats : EosinophilStats

@onready var life_timer : Timer = $LifeTimer
@onready var tick_timer : Timer = $TickTimer

func _ready() -> void:
	pass # Setup akan dipanggil dari luar (proyektil)


func setup(stats: EosinophilStats) -> void:
	_eo_stats = stats
	
	# Set durasi awan racun hidup
	life_timer.wait_time = _eo_stats.dot_duration
	life_timer.one_shot  = true
	life_timer.timeout.connect(queue_free)
	life_timer.start()
	
	# Set interval (tick) damage, misalnya setiap 1 detik
	tick_timer.wait_time = 1.0
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()


func _on_tick() -> void:
	if not _eo_stats:
		return
		
	# Dapatkan semua musuh yang sedang berdiri di genangan racun
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(_eo_stats.dot_damage)
			print("[EosinofilCloud] Memberikan %f DoT ke %s" % [_eo_stats.dot_damage, body.name])
