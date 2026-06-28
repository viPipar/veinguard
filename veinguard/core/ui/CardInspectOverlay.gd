# CardInspectOverlay.gd
# Overlay penuh layar untuk inspect detail kartu.
# Dibuat secara programatik (tanpa .tscn).
# Fitur: tampil animasi fade-in, tombol Tutup (merah) & Balik (hijau),
#        animasi flip scaleX saat tombol Balik ditekan.

class_name CardInspectOverlay
extends Control

# ── State ─────────────────────────────────────────────────────────────────
var _showing_front : bool      = true
var _front_tex     : Texture2D = null
var _back_tex      : Texture2D = null
var _stats         : UnitStats = null
var _font          : FontFile  = load("res://assets/ui/Font/LilitaOne-Regular.ttf")

# ── Node refs (diisi di _build_ui) ────────────────────────────────────────
var _card_display  : TextureRect
var _btn_close     : Button


func _ready() -> void:
	# Overlay menutupi seluruh layar; berada di atas elemen CanvasLayer lain
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_ui()


# ── Bangun seluruh UI secara programatik ─────────────────────────────────
func _build_ui() -> void:
	# --- Background gelap semi-transparan ---
	var dim := ColorRect.new()
	dim.color       = Color(0.0, 0.02, 0.08, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_card_display = TextureRect.new()
	_card_display.name          = "CardDisplay"
	_card_display.expand_mode   = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	_card_display.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_display.position      = Vector2(140.0, 360.0)
	_card_display.size          = Vector2(800.0, 1200.0)
	_card_display.pivot_offset  = Vector2(400.0, 600.0)  # pusat untuk animasi flip
	_card_display.mouse_filter  = Control.MOUSE_FILTER_STOP
	_card_display.gui_input.connect(_on_card_gui_input)
	add_child(_card_display)

	# --- Tombol TUTUP (kiri atas, merah) ---
	_btn_close          = _make_button("X", Color(0.72, 0.07, 0.07))
	_btn_close.name     = "CloseBtn"
	_btn_close.position = Vector2(40.0, 40.0)
	_btn_close.size     = Vector2(100.0, 100.0)
	add_child(_btn_close)
	_btn_close.pressed.connect(close)


# ── Helper: buat StyleBox panel ───────────────────────────────────────────
func _make_panel_stylebox() -> StyleBoxFlat:
	var sb         := StyleBoxFlat.new()
	sb.bg_color     = Color(0.04, 0.08, 0.16, 0.93)
	sb.border_color = Color(0.25, 0.55, 1.0, 0.55)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_border_width(side, 2)
	sb.corner_radius_top_left     = 22
	sb.corner_radius_top_right    = 22
	sb.corner_radius_bottom_left  = 22
	sb.corner_radius_bottom_right = 22
	return sb


# ── Helper: buat Button bergaya ───────────────────────────────────────────
func _make_button(btn_text: String, color: Color) -> Button:
	var btn  := Button.new()
	btn.text  = btn_text

	var sb_n := _rounded_box(color)
	var sb_h := _rounded_box(color.lightened(0.18))
	var sb_p := _rounded_box(color.darkened(0.22))

	btn.add_theme_font_override("font", _font)
	btn.add_theme_stylebox_override("normal",  sb_n)
	btn.add_theme_stylebox_override("hover",   sb_h)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 38)
	return btn


func _rounded_box(color: Color, radius: int = 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = color
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	return sb


# ── API Publik ────────────────────────────────────────────────────────────

## Buka overlay dengan data kartu
func open(stats: UnitStats, front_tex: Texture2D, back_tex: Texture2D) -> void:
	_stats         = stats
	_front_tex     = front_tex
	_back_tex      = back_tex if back_tex else front_tex
	_showing_front = true

	# Terapkan data ke UI
	_card_display.texture = _front_tex
	_card_display.scale   = Vector2(1.0, 1.0)

	# Animasi masuk (fade-in)
	get_tree().paused = true
	modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.22)


## Tutup overlay dengan animasi fade-out
func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	await tween.finished
	get_tree().paused = false
	hide()
	if GameManager.has_user_signal("tutorial_card_closed"):
		GameManager.emit_signal("tutorial_card_closed")


var _swipe_start_pos := Vector2.ZERO
var _is_swiping := false
var _is_flipping := false

func _on_card_gui_input(event: InputEvent) -> void:
	if _is_flipping:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_swiping = true
				_swipe_start_pos = event.global_position
			else:
				_is_swiping = false
				var dist = event.global_position.distance_to(_swipe_start_pos)
				# Kalau jarak kecil, anggap click
				if dist < 20.0:
					_do_flip()
					
	elif event is InputEventScreenDrag and _is_swiping:
		var swipe_dist = event.global_position.x - _swipe_start_pos.x
		if abs(swipe_dist) > 50.0:
			_is_swiping = false
			_do_flip()

# ── Animasi Flip Kartu (scaleX: 1→0→1) ────────────────────────────────────
func _do_flip() -> void:
	_is_flipping = true
	_showing_front = not _showing_front
	var new_tex := _front_tex if _showing_front else _back_tex

	var tween := create_tween()
	# Fase 1: perkecil scaleX ke 0 (lipat ke dalam)
	tween.tween_property(_card_display, "scale:x", 0.0, 0.16) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Ganti texture di titik "tertutup"
	tween.tween_callback(func(): _card_display.texture = new_tex)
	# Fase 2: buka scaleX kembali ke 1
	tween.tween_property(_card_display, "scale:x", 1.0, 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Re-enable setelah animasi selesai
	tween.tween_callback(func(): 
		_is_flipping = false
		if GameManager.has_user_signal("tutorial_card_flipped"):
			GameManager.emit_signal("tutorial_card_flipped")
	)
