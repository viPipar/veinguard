# HandManager.gd
# Mengelola sistem kartu bergaya Clash Royale:
# - Pool 6 unit tersedia
# - Hanya 3 kartu tampil di tangan sekaligus
# - Saat kartu dimainkan → animasi discard → kartu random baru masuk dari kanan

class_name HandManager
extends CanvasLayer

# ── Pool semua kartu (path ke scene, stats, texture depan & belakang) ─────
# Format tiap entry: [scene_path, stats_path, front_tex_path, back_tex_path]
const _POOL_ENTRIES: Array = [
	[
		"res://units/player/natural_killer/NKiller.tscn",
		"res://units/player/natural_killer/nkiller_stats.tres",
		"res://assets/ui/unit_cards/card_front_natural_killer.png",
		"res://assets/ui/unit_cards/card_back_natural_killer.png",
	],
	[
		"res://units/player/eritrosit/Eritrosit.tscn",
		"res://units/player/eritrosit/eritrosit_stats.tres",
		"res://assets/ui/unit_cards/card_front_eritrosit.png",
		"res://assets/ui/unit_cards/card_back_eritrosit.png",
	],
	[
		"res://units/player/trombosit/Trombosit.tscn",
		"res://units/player/trombosit/trombosit_stats.tres",
		"res://assets/ui/unit_cards/card_front_trombosit.png",
		"res://assets/ui/unit_cards/card_back_trombosit.png",
	],
	[
		"res://units/player/killer_t/KillerT.tscn",
		"res://units/player/killer_t/killert_stats.tres",
		"res://assets/ui/unit_cards/card_front_t_killer.png",
		"res://assets/ui/unit_cards/card_back_t_killer.png",
	],
	[
		"res://units/player/eosinofil/Eosinofil.tscn",
		"res://units/player/eosinofil/eosinofil_stats.tres",
		"res://assets/ui/unit_cards/card_front_limfosit_b.png",
		"res://assets/ui/unit_cards/card_back_limfosit_b.png",
	],
	[
		"res://units/player/makrofag/Makrofag.tscn",
		"res://units/player/makrofag/makrofag_stats.tres",
		"res://assets/ui/unit_cards/card_front_makrofag.png",
		"res://assets/ui/unit_cards/card_back_makrofag.png",
	],
]

# ── Konstanta layout ───────────────────────────────────────────────────────
const CARD_SCALE          : Vector2 = Vector2(0.165, 0.165)
const NEXT_CARD_SCALE     : Vector2 = Vector2(0.12, 0.12)
const CARD_CENTER_Y       : float   = 1710.0
const NEXT_CARD_CENTER_Y  : float   = 1710.0
const SLOT_CENTER_X       : Array   = [370.0, 565.0, 760.0, 955.0]
const NEXT_CARD_CENTER_X  : float   = 120.0

# ── State ─────────────────────────────────────────────────────────────────
var _pool               : Array        = []   # Array of {scene, stats, front_tex, back_tex}
var _slots              : Array        = []   # 4 UnitCard nodes
var _hand_indices       : Array        = [-1, -1, -1, -1]  # index pool untuk tiap slot
var _next_card_slot     : UnitCard     = null
var _next_card_idx      : int          = -1


func _ready() -> void:
	add_to_group("hand_manager")
	layer = 2   # Render di atas HUD (layer 1) tapi di bawah GameOver (layer 10)

	_load_pool()
	_create_card_slots()
	_init_hand()


# ── Load seluruh resource pool ────────────────────────────────────────────
func _load_pool() -> void:
	for entry in _POOL_ENTRIES:
		var front : Texture2D = _safe_load(entry[2])
		var back  : Texture2D = _safe_load(entry[3])
		_pool.append({
			"scene":     _safe_load(entry[0]),
			"stats":     _safe_load(entry[1]),
			"front_tex": front,
			"back_tex":  back if back else front,
		})


func _safe_load(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[HandManager] Resource tidak ditemukan: %s" % path)
	return null


# ── Buat 4 slot kartu & 1 Next Card ──────────────────────────────────────────
func _create_card_slots() -> void:
	for i in 4:
		var card          := UnitCard.new()
		card.name          = "HandSlot%d" % i
		card.scale         = CARD_SCALE
		# Posisi diset secara dinamis di _assign_slot setelah tekstur dimuat
		add_child(card)   # _ready() kartu dipanggil di sini
		_slots.append(card)

	# Buat Next Card slot
	_next_card_slot       = UnitCard.new()
	_next_card_slot.name  = "NextCardSlot"
	_next_card_slot.scale = NEXT_CARD_SCALE
	_next_card_slot.modulate.a = 0.8  # Sedikit transparan
	_next_card_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE # Tidak bisa diklik
	add_child(_next_card_slot)


# ── Inisialisasi tangan awal (4 kartu utama + 1 Next Card) ─────────────
func _init_hand() -> void:
	var indices := range(_pool.size())
	indices.shuffle()
	
	# Ambil 4 kartu untuk Hand
	for i in 4:
		_hand_indices[i] = indices[i]
		_assign_slot(i, indices[i], false)
		
	# Ambil 1 kartu untuk Next Card
	if _pool.size() > 4:
		_next_card_idx = indices[4]
	else:
		_next_card_idx = indices[0]
	_assign_next_card(false)


# ── Discard kartu yang dimainkan & draw kartu baru ───────────────────────
func discard_and_draw(played_card: UnitCard) -> void:
	var slot_idx : int = _slots.find(played_card)
	if slot_idx == -1:
		return

	# Tunggu animasi discard selesai
	await played_card.play_discard_animation()

	# Kartu dari Next Card masuk ke slot yang dimainkan
	var incoming_idx : int = _next_card_idx
	_hand_indices[slot_idx] = incoming_idx
	
	# Assign & animasikan masuk dari Next Card
	_assign_slot(slot_idx, incoming_idx, true, true)
	
	# Pilih kartu baru untuk mengisi Next Card
	_next_card_idx = _pick_new_card()
	_assign_next_card(true)


# ── Pilih kartu baru (prioritaskan yang belum ada) ────────────────────────
func _pick_new_card() -> int:
	var candidates : Array = []
	for i in _pool.size():
		if i not in _hand_indices and i != _next_card_idx:
			candidates.append(i)
	if candidates.is_empty():
		return randi() % _pool.size()
	candidates.shuffle()
	return candidates[0]


# ── Assign data pool ke slot kartu ────────────────────────────────────────
func _assign_slot(slot_idx: int, pool_idx: int, animate: bool, from_next: bool = false) -> void:
	var card : UnitCard = _slots[slot_idx]
	var data : Dictionary = _pool[pool_idx]

	card.unit_scene    = data.scene
	card.unit_stats    = data.stats
	card._front_tex    = data.front_tex
	card._back_tex     = data.back_tex

	# Set texture depan sebagai tampilan normal kartu
	if data.front_tex:
		card.texture_normal = data.front_tex
		card.size           = data.front_tex.get_size()

	card._recompute_center()
	
	# Posisikan dengan akurat berdasarkan pivot center
	card.position = Vector2(SLOT_CENTER_X[slot_idx], CARD_CENTER_Y) - (card.size / 2.0)
	card.base_pos = card.position

	if animate:
		if from_next and _next_card_slot:
			card.play_draw_animation(_next_card_slot.position, _next_card_slot.scale)
		else:
			card.play_draw_animation()

func _assign_next_card(animate: bool) -> void:
	if not _next_card_slot or _next_card_idx == -1: return
	
	var data : Dictionary = _pool[_next_card_idx]
	_next_card_slot.unit_scene = data.scene
	_next_card_slot.unit_stats = data.stats
	_next_card_slot._front_tex = data.front_tex
	_next_card_slot._back_tex  = data.back_tex
	
	if data.front_tex:
		_next_card_slot.texture_normal = data.front_tex
		_next_card_slot.size = data.front_tex.get_size()
		
	_next_card_slot._recompute_center()
	
	_next_card_slot.position = Vector2(NEXT_CARD_CENTER_X, NEXT_CARD_CENTER_Y) - (_next_card_slot.size / 2.0)
	_next_card_slot.base_pos = _next_card_slot.position
	
	if animate:
		_next_card_slot.play_draw_animation()
