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
signal card_inspected(card_node: UnitCard)

# ── State ─────────────────────────────────────────────────────────────────
var is_playable   := true
var is_focused    := false
var base_scale    := Vector2.ONE
var base_pos      := Vector2.ZERO

var _is_flipped       := false

var _hold_timer       := 0.0
var _is_holding       := false
var _hold_start_pos   := Vector2.ZERO

# Posisi & skala saat kartu dipilih (tengah layar)
var _center_pos   := Vector2(200.0, 600.0)
var _center_scale := Vector2(0.4, 0.4)


func _ready() -> void:
	add_to_group("unit_cards")
	pressed.connect(_on_pressed)
	base_scale = scale
	base_pos   = position
	_recompute_center()

func _process(delta: float) -> void:
	if not is_playable:
		return
	if _is_holding:
		_hold_timer += delta
		if _hold_timer >= 0.4:
			_is_holding = false
			_hold_timer = 0.0
			card_inspected.emit(self)
			if GameManager.has_user_signal("tutorial_card_inspected"):
				GameManager.emit_signal("tutorial_card_inspected")


# Hitung posisi & skala tengah layar berdasarkan ukuran texture aktif
func _recompute_center() -> void:
	var vp := get_viewport_rect().size
	
	# Cari base_screen_pos (posisi PlayerBase di screen space)
	var base_screen_pos := Vector2(vp.x * 0.5, vp.y * 0.5 + 75.0) # Default/fallback
	var player_base := get_node_or_null("/root/Main/Lane/PlayerBase")
	var camera := get_node_or_null("/root/Main/Camera2D")
	if player_base and camera:
		base_screen_pos = vp * 0.5 + (player_base.global_position - camera.global_position) * camera.zoom
		
	if texture_normal:
		var tw := texture_normal.get_width()
		var th := texture_normal.get_height()
		# Skala proporsional 0.4 tanpa distorsi
		_center_scale = Vector2(0.4, 0.4)
		# Posisikan pas di base hero (agar visual_center = base_screen_pos)
		_center_pos = base_screen_pos - Vector2(tw, th) * 0.5
		
		# Set pivot di tengah agar saat flip (scale x mengecil) titik tengahnya tetap
		pivot_offset = size / 2.0
	else:
		_center_scale = Vector2(0.4, 0.4)
		_center_pos = base_screen_pos - Vector2(200.0, 300.0) # Fallback offset
		pivot_offset = size / 2.0


# ── Input ─────────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if not is_playable:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			card_inspected.emit(self)
			if GameManager.has_user_signal("tutorial_card_inspected"):
				GameManager.emit_signal("tutorial_card_inspected")
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_holding = true
				_hold_timer = 0.0
				_hold_start_pos = event.global_position
			else:
				_is_holding = false
				
	if event is InputEventScreenTouch:
		if event.pressed:
			_is_holding = true
			_hold_timer = 0.0
			_hold_start_pos = event.global_position
		else:
			_is_holding = false

	if _is_holding and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		if event.global_position.distance_to(_hold_start_pos) > 15.0:
			_is_holding = false


func _on_pressed() -> void:
	if not is_playable:
		return
	if is_focused:
		# Blokir deselect jika tutorial sedang berjalan
		if get_tree().root.find_child("TutorialManager", true, false) != null:
			return
			
		# Klik kartu yang sudah di tengah → batal pilih
		set_focus(false)
		card_toggled.emit(self, false)
	else:
		# Defocus semua kartu lain, lalu fokuskan ini
		get_tree().call_group("unit_cards", "set_focus", false)
		set_focus(true)
		card_toggled.emit(self, true)
		if GameManager.has_user_signal("tutorial_card_selected"):
			GameManager.emit_signal("tutorial_card_selected")


# ── Focus: kartu terbang ke tengah layar ─────────────────────────────────
func set_focus(focused: bool) -> void:
	is_focused = focused
	
	if not is_focused and _is_flipped:
		_is_flipped = false
		texture_normal = _front_tex
		
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


# ── Animasi Draw: kartu masuk (default dari luar layar kanan) ────────────
func play_draw_animation(start_pos = null, start_scale = null) -> void:
	var vp := get_viewport_rect().size
	
	if start_pos != null:
		position = start_pos
	else:
		position = Vector2(vp.x + 80.0, base_pos.y)
		
	if start_scale != null:
		scale = start_scale
	else:
		scale = base_scale
		
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
	if is_playable:
		mouse_filter = Control.MOUSE_FILTER_STOP     # Bisa diklik kembali
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE   # Tetap tidak bisa diklik


func update_energy_state(current_oxygen: float) -> void:
	if unit_stats:
		if current_oxygen < unit_stats.cost:
			self_modulate = Color(0.4, 0.4, 0.4, 1.0)
		else:
			self_modulate = Color(1.0, 1.0, 1.0, 1.0)
