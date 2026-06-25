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
var _name_label    : Label
var _stats_label   : Label
var _desc_label    : Label
var _btn_close     : Button
var _btn_flip      : Button


func _ready() -> void:
	# Overlay menutupi seluruh layar; berada di atas elemen CanvasLayer lain
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
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

	# --- Tampilan Kartu (besar, di tengah) ---
	_card_display = TextureRect.new()
	_card_display.expand_mode   = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	_card_display.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_display.position      = Vector2(240.0, 180.0)
	_card_display.size          = Vector2(600.0, 900.0)
	_card_display.pivot_offset  = Vector2(300.0, 450.0)  # pusat untuk animasi flip
	add_child(_card_display)

	# --- Panel info stats di bawah kartu ---
	var panel := Panel.new()
	panel.position = Vector2(60.0, 1115.0)
	panel.size     = Vector2(960.0, 370.0)
	var sb_panel   := _make_panel_stylebox()
	panel.add_theme_stylebox_override("panel", sb_panel)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20.0, 18.0)
	vbox.size     = Vector2(920.0, 334.0)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_override("font", _font)
	_name_label.add_theme_font_size_override("font_size", 60)
	_name_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	vbox.add_child(_name_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_override("font", _font)
	_stats_label.add_theme_font_size_override("font_size", 38)
	_stats_label.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0))
	vbox.add_child(_stats_label)

	_desc_label = Label.new()
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_override("font", _font)
	_desc_label.add_theme_font_size_override("font_size", 30)
	_desc_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.96))
	vbox.add_child(_desc_label)

	# --- Tombol TUTUP (kiri atas, merah) ---
	_btn_close          = _make_button("✕  Tutup", Color(0.72, 0.07, 0.07))
	_btn_close.position = Vector2(24.0, 40.0)
	_btn_close.size     = Vector2(220.0, 88.0)
	add_child(_btn_close)
	_btn_close.pressed.connect(close)

	# --- Tombol BALIK (kanan atas, hijau) ---
	_btn_flip          = _make_button("↺  Balik", Color(0.07, 0.58, 0.18))
	_btn_flip.position = Vector2(836.0, 40.0)
	_btn_flip.size     = Vector2(220.0, 88.0)
	add_child(_btn_flip)
	_btn_flip.pressed.connect(_on_flip_pressed)


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

	_name_label.text  = stats.unit_name
	_stats_label.text = "❤ %d HP   ⚔ %.0f DMG   💧 %d Cost" % \
		[int(stats.max_hp), stats.damage, stats.cost]

	if stats.description.is_empty():
		_desc_label.visible = false
	else:
		_desc_label.visible = true
		_desc_label.text    = stats.description

	# Animasi masuk (fade-in)
	modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.22)


## Tutup overlay dengan animasi fade-out
func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	await tween.finished
	hide()


# ── Animasi Flip Kartu (scaleX: 1→0→1) ────────────────────────────────────
func _on_flip_pressed() -> void:
	_showing_front = not _showing_front
	var new_tex := _front_tex if _showing_front else _back_tex

	_btn_flip.disabled = true   # cegah double-press saat animasi

	var tween := create_tween()
	# Fase 1: perkecil scaleX ke 0 (lipat ke dalam)
	tween.tween_property(_card_display, "scale:x", 0.0, 0.16) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Ganti texture di titik "tertutup"
	tween.tween_callback(func(): _card_display.texture = new_tex)
	# Fase 2: buka scaleX kembali ke 1
	tween.tween_property(_card_display, "scale:x", 1.0, 0.16) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Re-enable tombol setelah animasi selesai
	tween.tween_callback(func(): _btn_flip.disabled = false)
