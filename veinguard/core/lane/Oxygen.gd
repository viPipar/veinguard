# Oxygen.gd
# Objek oksigen yang spawn di lane
# Eritrosit mendekat → mengambil → membawa ke base

class_name Oxygen
extends Area2D

@export var oxygen_value : int = 50   # nilai poin yang diberikan ke GameManager

var _is_taken : bool = false          # sudah diambil Eritrosit atau belum


func _ready() -> void:
	# Animasi mengambang
	#_start_float_animation()
	pass


func _start_float_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 8.0, 0.6)\
		 .set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y, 0.6)\
		 .set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# Dipanggil oleh Eritrosit saat menyentuh oxygen ini
# Mengembalikan true kalau berhasil diambil, false kalau sudah diambil duluan
func try_pickup() -> bool:
	if _is_taken:
		return false
	_is_taken = true
	# Sembunyikan dari lane — Eritrosit yang "membawa"
	hide()
	get_node("CollisionShape2D").set_deferred("disabled", true)
	return true


# Dipanggil Eritrosit kalau dia mati sebelum sampai base
# Oxygen "jatuh" kembali ke lane
func drop_back(drop_position: Vector2) -> void:
	_is_taken = false
	global_position = drop_position
	show()
	get_node("CollisionShape2D").set_deferred("disabled", false)
