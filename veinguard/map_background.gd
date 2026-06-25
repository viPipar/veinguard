extends Sprite2D

# Kecepatan aliran darah (pixel per detik)
@export var scroll_speed : float = 100.0

func _process(delta: float) -> void:
	# Menggeser region texture ke arah vertikal (ke bawah)
	region_rect.position.y -= scroll_speed * delta
