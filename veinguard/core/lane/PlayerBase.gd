# PlayerBase.gd
# Base pemain — kalau musuh sampai sini dan merusak base sampai hancur, game over!

class_name PlayerBase
extends Area2D

@onready var sprite : Sprite2D = $Sprite2D

@export var max_health : float = 1000.0
var current_health : float
var _health_bar : Node2D = null

var _float_time : float = 0.0

func _ready() -> void:
	# Sesuaikan max_health (di-fix 500 sesuai rebalancing)
	max_health = 500.0
		
	current_health = max_health
	
	# Load dan setup HealthBar
	var hb_scene = load("res://core/ui/HealthBar.tscn")
	if hb_scene:
		_health_bar = hb_scene.instantiate()
		add_child(_health_bar)
		# Tempatkan sedikit di atas base sprite
		_health_bar.position = Vector2(-24, -130)
		_health_bar.setup(max_health)
		
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if sprite:
		_float_time += delta
		# Efek mengambang (floating) menggunakan gelombang sinus (sin wave)
		# Naik-turun sejauh 8 pixel dengan kecepatan halus
		sprite.position.y = sin(_float_time * 2.5) * 8.0


func _on_body_entered(body: Node2D) -> void:
	# Jika musuh menyentuh base, mereka tetap menyerang menggunakan take_damage.
	# Kita bisa memberikan damage penalti kecil/sekali masuk agar base terluka jika musuh mencapainya
	if body is UnitBase and body.is_in_group("enemies") and body.current_state != UnitBase.State.DIE:
		take_damage(body.stats.damage * 1.5)
		print("[PlayerBase] Musuh masuk base! Menerima damage awal: ", body.stats.damage * 1.5)


func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return
		
	current_health = max(0.0, current_health - amount)
	if _health_bar:
		_health_bar.update(current_health, max_health)
		
	# Hit flash effect (berkedip putih sebentar)
	if sprite:
		var tween = create_tween()
		sprite.modulate = Color(5.0, 5.0, 5.0, 1.0)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
	if current_health <= 0.0:
		print("[PlayerBase] HANCUR! Game Over!")
		GameManager.trigger_game_over()
