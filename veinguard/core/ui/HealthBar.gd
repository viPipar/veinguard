# HealthBar.gd
# Reusable health bar untuk semua unit.
# Dipanggil dari UnitBase via update_health_bar(current, max)

extends Node2D

@onready var _bar_bg   : ColorRect = $BG
@onready var _bar_fill : ColorRect = $Fill
@onready var _bar_dmg  : ColorRect = $DamageFill  # "damage flash" merah

const BAR_WIDTH  : float = 48.0
const BAR_HEIGHT : float = 6.0

# Warna berdasarkan HP %
const COLOR_HIGH : Color = Color(0.18, 0.85, 0.40)   # hijau cerah
const COLOR_MID  : Color = Color(0.95, 0.75, 0.10)   # kuning
const COLOR_LOW  : Color = Color(0.95, 0.22, 0.22)   # merah

var _tween : Tween


func _ready() -> void:
	# Sembunyikan bar saat HP penuh (akan muncul saat kena damage)
	visible = false


func setup(max_hp: float) -> void:
	# Panggil ini setelah add_child agar bar ter-setup dengan benar
	if _bar_bg   == null: return
	_bar_bg.size   = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_dmg.size  = Vector2(BAR_WIDTH, BAR_HEIGHT)
	# Offset agar bar ada di atas unit (dapat dioverride via position di .tscn)
	_bar_fill.color = COLOR_HIGH


func update(current_hp: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return

	visible = true  # tampilkan begitu ada damage

	var ratio : float = clampf(current_hp / max_hp, 0.0, 1.0)
	var target_w : float = BAR_WIDTH * ratio

	# Pilih warna
	var target_color : Color
	if ratio > 0.5:
		target_color = COLOR_HIGH
	elif ratio > 0.25:
		target_color = COLOR_MID
	else:
		target_color = COLOR_LOW

	# Animasi fill
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_bar_fill, "size:x", target_w,  0.15)
	_tween.parallel().tween_property(_bar_fill, "color",  target_color, 0.15)

	# "Damage flash": bar merah tetap lebar sebentar lalu menyusul
	_bar_dmg.size.x = _bar_fill.size.x  # mulai dari lebar saat ini
	var dmg_tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	dmg_tween.tween_interval(0.25)
	dmg_tween.tween_property(_bar_dmg, "size:x", target_w, 0.3)
