# UnitCard.gd — Clash Royale-style card dengan animasi ke tengah & inspect
class_name UnitCard
extends TextureButton

# ── Data yang di-assign oleh HandManager ──────────────────────────────────
@export var unit_scene : PackedScene
@export var unit_stats : UnitStats

# Texture depan/belakang (diisi HandManager saat draw)
var _front_tex : Texture2D = null
var _back_tex  : Texture2D = null

# ── Signals ───────────────────────────────────────────────────────────────
signal card_toggled(card_node: UnitCard, is_selected: bool)
signal card_inspect_requested(card_node: UnitCard)

# ── State ─────────────────────────────────────────────────────────────────
var is_focused    := false
var base_scale    := Vector2.ONE
var base_pos      := Vector2.ZERO

# Posisi & skala saat kartu dipilih (tengah layar)
var _center_pos   := Vector2(200.0, 600.0)
var _center_scale := Vector2(0.32, 0.32)


func _ready() -> void:
	add_to_group("unit_cards")
	pressed.connect(_on_pressed)
	base_scale = scale
	base_pos   = position
	_recompute_center()


# Hitung posisi & skala tengah layar berdasarkan ukuran texture aktif
func _recompute_center() -> void:
	_center_scale = Vector2(0.32, 0.32)
	var vp := get_viewport_rect().size
	if texture_normal:
		var tw := texture_normal.get_width()  * _center_scale.x
		var th := texture_normal.get_height() * _center_scale.y
		_center_pos = Vector2((vp.x - tw) * 0.5, (vp.y - th) * 0.5)
	else:
		_center_pos = Vector2(200.0, 600.0)


# ── Input ─────────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	# Klik kanan atau long-press (android) → buka inspect
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			accept_event()
			card_inspect_requested.emit(self)


func _on_pressed() -> void:
	if is_focused:
		# Klik kartu yang sudah di tengah → batal pilih
		set_focus(false)
		card_toggled.emit(self, false)
	else:
		# Defocus semua kartu lain, lalu fokuskan ini
		get_tree().call_group("unit_cards", "set_focus", false)
		set_focus(true)
		card_toggled.emit(self, true)


# ── Focus: kartu terbang ke tengah layar ─────────────────────────────────
func set_focus(focused: bool) -> void:
	is_focused = focused
	var tween := create_tween().set_parallel(true)
	if is_focused:
		tween.tween_property(self, "position", _center_pos, 0.30) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", _center_scale, 0.28) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		rotation = 0.0
		tween.tween_property(self, "position", base_pos, 0.22) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", base_scale, 0.22) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# ── Animasi Discard: kartu terbang ke atas & fade out ────────────────────
func play_discard_animation() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 380.0, 0.30) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.25) \
		.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", scale * 0.55, 0.28) \
		.set_ease(Tween.EASE_IN)
	await tween.finished
	# Reset untuk kartu berikutnya
	modulate.a = 0.0
	rotation   = 0.0


# ── Animasi Draw: kartu masuk dari kanan ─────────────────────────────────
func play_draw_animation() -> void:
	var vp := get_viewport_rect().size
	# Mulai dari luar layar kanan
	position   = Vector2(vp.x + 80.0, base_pos.y)
	scale      = base_scale
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Tidak bisa diklik saat animasi

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", base_pos, 0.45) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.35) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale, 0.35) \
		.set_ease(Tween.EASE_OUT)
	await tween.finished
	mouse_filter = Control.MOUSE_FILTER_STOP     # Bisa diklik kembali
