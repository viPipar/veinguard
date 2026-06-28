class_name TutorialManager
extends CanvasLayer

enum Step {
	OXYGEN_INTRO,
	ENCY_INTRO,
	CARD_SELECT,
	CARD_INSPECT,
	CARD_FLIP,
	CARD_CLOSE,
	SLINGSHOT_DRAG,
	FINISH
}

var current_step: Step = Step.OXYGEN_INTRO

var _rect_top: ColorRect
var _rect_bottom: ColorRect
var _rect_left: ColorRect
var _rect_right: ColorRect

var _dialog_box: PanelContainer
var _dialog_label: Label
var _portrait: TextureRect
var _click_overlay: Control

var _is_waiting_for_action: bool = false
var _anim_timer: float = 0.0
var _anim_frame: int = 0

signal tutorial_finished

func _ready() -> void:
	layer = 150 # Di atas segalanya
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Buka akses klik pada HandManager meskipun game sedang pause!
	var hand = get_tree().root.find_child("HandManager", true, false)
	if hand: hand.process_mode = Node.PROCESS_MODE_ALWAYS
	
	_build_ui()
	_apply_step()

func _process(delta: float) -> void:
	get_tree().paused = true # Pastikan selalu pause saat tutorial aktif
	
	# Animasi sprite eritrosit
	if _portrait and _portrait.texture is AtlasTexture:
		var atlas: AtlasTexture = _portrait.texture
		if atlas.atlas:
			_anim_timer += delta
			if _anim_timer > 0.15:
				_anim_timer = 0.0
				var frames_count = 4.0 # Asumsi 4 frame
				var fw = atlas.atlas.get_width() / frames_count
				_anim_frame = (_anim_frame + 1) % int(frames_count)
				atlas.region = Rect2(_anim_frame * fw, 0, fw, atlas.atlas.get_height())

func _build_ui() -> void:
	var c = Color(0, 0, 0, 0.75)
	_rect_top = ColorRect.new(); _rect_top.color = c; _rect_top.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_rect_top)
	_rect_bottom = ColorRect.new(); _rect_bottom.color = c; _rect_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_rect_bottom)
	_rect_left = ColorRect.new(); _rect_left.color = c; _rect_left.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_rect_left)
	_rect_right = ColorRect.new(); _rect_right.color = c; _rect_right.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_rect_right)
	
	_click_overlay = Control.new()
	_click_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_overlay.gui_input.connect(_on_overlay_gui_input)
	add_child(_click_overlay)
	
	_dialog_box = PanelContainer.new()
	var vp = get_viewport().get_visible_rect().size
	_dialog_box.size = Vector2(800, 250)
	# Posisikan persis di tengah layar
	_dialog_box.position = Vector2((vp.x - 800) / 2, (vp.y - 250) / 2)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.9, 0.9, 0.9, 0.85) # 85% opacity
	sb.border_width_left = 8; sb.border_width_right = 8
	sb.border_width_top = 8; sb.border_width_bottom = 8
	sb.border_color = Color(0.8, 0.1, 0.1)
	sb.corner_radius_top_left = 20; sb.corner_radius_top_right = 20
	sb.corner_radius_bottom_left = 20; sb.corner_radius_bottom_right = 20
	_dialog_box.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_dialog_box.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	margin.add_child(hbox)
	
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(200, 200)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/ui/Character/eritrosit_walk.png")
	if atlas.atlas:
		atlas.region = Rect2(0, 0, atlas.atlas.get_width() / 4.0, atlas.atlas.get_height())
	_portrait.texture = atlas
	hbox.add_child(_portrait)
	
	_dialog_label = Label.new()
	_dialog_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialog_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_font_override("font", load("res://assets/ui/Font/LilitaOne-Regular.ttf"))
	_dialog_label.add_theme_font_size_override("font_size", 36)
	_dialog_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	hbox.add_child(_dialog_label)
	
	var hint = Label.new()
	hint.text = "(Ketuk layar untuk lanjut)"
	hint.add_theme_font_override("font", load("res://assets/ui/Font/LilitaOne-Regular.ttf"))
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	margin.add_child(hint)
	
	add_child(_dialog_box)

func _set_spotlight(target_rect: Rect2) -> void:
	var vp = get_viewport().get_visible_rect().size
	
	if target_rect == Rect2():
		# Full screen dark
		_rect_top.size = Vector2(vp.x, vp.y)
		_rect_top.position = Vector2.ZERO
		_rect_bottom.size = Vector2.ZERO
		_rect_left.size = Vector2.ZERO
		_rect_right.size = Vector2.ZERO
		return
		
	var r = target_rect
	
	# Top
	_rect_top.position = Vector2(0, 0)
	_rect_top.size = Vector2(vp.x, r.position.y)
	
	# Bottom
	_rect_bottom.position = Vector2(0, r.end.y)
	_rect_bottom.size = Vector2(vp.x, vp.y - r.end.y)
	
	# Left
	_rect_left.position = Vector2(0, r.position.y)
	_rect_left.size = Vector2(r.position.x, r.size.y)
	
	# Right
	_rect_right.position = Vector2(r.end.x, r.position.y)
	_rect_right.size = Vector2(vp.x - r.end.x, r.size.y)

func _apply_step() -> void:
	get_tree().paused = true
	_is_waiting_for_action = false
	_click_overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Block underlying clicks
	
	match current_step:
		Step.OXYGEN_INTRO:
			_dialog_label.text = "Selamat datang, Komandan! Oksigen di atas ini sangat penting untuk memanggil unit-unit kita."
			var bar = get_tree().root.find_child("OxygenBar", true, false)
			if bar:
				var rect = Rect2(bar.global_position - Vector2(10, 10), bar.size + Vector2(20, 20))
				_set_spotlight(rect)
			else:
				_set_spotlight(Rect2())
				
		Step.ENCY_INTRO:
			_dialog_label.text = "Lupa fungsi setiap sel? Ketuk tombol '?' ini kapan saja untuk membuka Mini Ensiklopedia!"
			var btn = get_tree().root.find_child("MiniEncyBtn", true, false)
			if btn:
				var rect = Rect2(btn.global_position - Vector2(10, 10), btn.size + Vector2(20, 20))
				_set_spotlight(rect)
			else:
				_set_spotlight(Rect2(30, 140, 80, 80))
				
		Step.CARD_SELECT:
			_is_waiting_for_action = true
			_click_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # Allow clicking
			_dialog_label.text = "Sekarang, coba ketuk (pilih) kartu Eritrosit di bagian bawah layar!"
			
			var card = get_tree().root.find_child("EritrositSlot", true, false)
			if card:
				var rect = Rect2(card.global_position - Vector2(15, 15), card.size * card.scale + Vector2(30, 30))
				_set_spotlight(rect)
			else:
				var vp = get_viewport().get_visible_rect().size
				_set_spotlight(Rect2(0, vp.y - 300, vp.x, 300))
			
			if not GameManager.has_user_signal("tutorial_card_selected"):
				GameManager.add_user_signal("tutorial_card_selected")
			if not GameManager.is_connected("tutorial_card_selected", _on_action_done):
				GameManager.connect("tutorial_card_selected", _on_action_done)
				
		Step.CARD_INSPECT:
			_is_waiting_for_action = true
			_click_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dialog_label.text = "Bagus! Tahukah kamu? Menahan (Hold) kartu di HP, atau Klik Kanan di PC, akan membuka detail statistik. Coba lakukan sekarang!"
			
			var card = get_tree().root.find_child("EritrositSlot", true, false)
			if card:
				var rect = Rect2(card.global_position - Vector2(15, 15), card.size * card.scale + Vector2(30, 30))
				_set_spotlight(rect)
			else:
				var vp = get_viewport().get_visible_rect().size
				_set_spotlight(Rect2(0, vp.y - 300, vp.x, 300))
			
			if not GameManager.has_user_signal("tutorial_card_inspected"):
				GameManager.add_user_signal("tutorial_card_inspected")
			if not GameManager.is_connected("tutorial_card_inspected", _on_action_done):
				GameManager.connect("tutorial_card_inspected", _on_action_done)
				
		Step.CARD_FLIP:
			_is_waiting_for_action = true
			_click_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dialog_label.text = "Ketuk gambar kartu besar di tengah layar untuk membaliknya dan membaca fakta biologi sel ini!"
			
			var card_disp = get_tree().root.find_child("CardDisplay", true, false)
			if card_disp:
				var rect = Rect2(card_disp.global_position - Vector2(10, 10), card_disp.size * card_disp.scale + Vector2(20, 20))
				_set_spotlight(rect)
			else:
				var vp = get_viewport().get_visible_rect().size
				_set_spotlight(Rect2(vp.x/2 - 200, vp.y/2 - 300, 400, 600))
			
			if not GameManager.has_user_signal("tutorial_card_flipped"):
				GameManager.add_user_signal("tutorial_card_flipped")
			if not GameManager.is_connected("tutorial_card_flipped", _on_action_done):
				GameManager.connect("tutorial_card_flipped", _on_action_done)
				
		Step.CARD_CLOSE:
			_is_waiting_for_action = true
			_click_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dialog_label.text = "Sekarang, ketuk tombol silang (X) di kiri atas layar atau geser layar ke bawah untuk menutup detail."
			
			var close_btn = get_tree().root.find_child("CloseBtn", true, false)
			if close_btn:
				var rect = Rect2(close_btn.global_position - Vector2(10, 10), close_btn.size + Vector2(20, 20))
				_set_spotlight(rect)
			else:
				_set_spotlight(Rect2(20, 20, 140, 140))
			
			if not GameManager.has_user_signal("tutorial_card_closed"):
				GameManager.add_user_signal("tutorial_card_closed")
			if not GameManager.is_connected("tutorial_card_closed", _on_action_done):
				GameManager.connect("tutorial_card_closed", _on_action_done)
				
		Step.SLINGSHOT_DRAG:
			_is_waiting_for_action = true
			_click_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dialog_label.text = "Tarik kartumu ke area medan perang, arahkan, lalu lepaskan untuk meluncurkan sel!"
			
			var sling = get_tree().root.find_child("SlingshotController", true, false)
			if sling: sling.process_mode = Node.PROCESS_MODE_ALWAYS
			
			var vp = get_viewport().get_visible_rect().size
			_set_spotlight(Rect2(0, vp.y / 2, vp.x, vp.y / 2)) # Highlight area bawah dialog
			
			if not GameManager.has_user_signal("tutorial_unit_launched"):
				GameManager.add_user_signal("tutorial_unit_launched")
			if not GameManager.is_connected("tutorial_unit_launched", _on_action_done):
				GameManager.connect("tutorial_unit_launched", _on_action_done)
				
		Step.FINISH:
			_dialog_label.text = "Kerja bagus Komandan! Hancurkan semua bakteri dan selamatkan tubuh ini!"
			_set_spotlight(Rect2())

func _on_overlay_gui_input(event: InputEvent) -> void:
	if _is_waiting_for_action: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_step == Step.FINISH:
			_finish_tutorial()
		else:
			current_step += 1
			_apply_step()
	elif event is InputEventScreenTouch and event.pressed:
		if current_step == Step.FINISH:
			_finish_tutorial()
		else:
			current_step += 1
			_apply_step()

func _on_action_done() -> void:
	if not _is_waiting_for_action: return
	
	# Disconnect specific signal to prevent duplicate firing
	_is_waiting_for_action = false
	
	# Add slight delay for smoothness
	await get_tree().create_timer(0.5).timeout
	current_step += 1
	_apply_step()

func _finish_tutorial() -> void:
	var hand = get_tree().root.find_child("HandManager", true, false)
	if hand: hand.process_mode = Node.PROCESS_MODE_INHERIT
	var sling = get_tree().root.find_child("SlingshotController", true, false)
	if sling: sling.process_mode = Node.PROCESS_MODE_INHERIT
	
	set_process(false)
	get_tree().paused = false
	tutorial_finished.emit()
	queue_free()
