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
# Kartu ukuran ~1050×1410 dengan scale 0.165 → visual ~173×233 px
# 3 kartu dibagi rata di lebar 1080px:
#   margin = (1080 - 3×173) / 4 ≈ 140  →  slot di x = 140, 453, 766
const CARD_SCALE : Vector2 = Vector2(0.5, 0.5)
const CARD_Y     : float   = 1634.0
const SLOT_X     : Array   = [140.0, 453.0, 766.0]

# ── State ─────────────────────────────────────────────────────────────────
var _pool               : Array        = []   # Array of {scene, stats, front_tex, back_tex}
var _slots              : Array        = []   # 3 UnitCard nodes
var _hand_indices       : Array        = [-1, -1, -1]  # index pool untuk tiap slot


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


# ── Buat 3 slot kartu ──────────────────────────────────────────────────────────
func _create_card_slots() -> void:
	for i in 3:
		var card          := UnitCard.new()
		card.name          = "HandSlot%d" % i
		card.scale         = CARD_SCALE
		card.position      = Vector2(SLOT_X[i], CARD_Y)
		add_child(card)   # _ready() kartu dipanggil di sini
		_slots.append(card)


# ── Inisialisasi tangan awal (3 kartu random, tidak duplikat) ─────────────
func _init_hand() -> void:
	var indices := range(_pool.size())
	indices.shuffle()
	for i in 3:
		_hand_indices[i] = indices[i]
		_assign_slot(i, indices[i], false)   # false = tidak animasi saat mulai


# ── Discard kartu yang dimainkan & draw kartu baru ───────────────────────
func discard_and_draw(played_card: UnitCard) -> void:
	var slot_idx : int = _slots.find(played_card)
	if slot_idx == -1:
		return

	# Tunggu animasi discard selesai
	await played_card.play_discard_animation()

	# Pilih kartu baru dari pool (hindari duplikat jika bisa)
	var new_idx : int = _pick_new_card()
	_hand_indices[slot_idx] = new_idx

	# Assign data & animasikan masuk dari kanan
	_assign_slot(slot_idx, new_idx, true)


# ── Pilih kartu baru (prioritaskan yang belum ada di tangan) ──────────────
func _pick_new_card() -> int:
	var candidates : Array = []
	for i in _pool.size():
		if i not in _hand_indices:
			candidates.append(i)
	if candidates.is_empty():
		return randi() % _pool.size()   # semua sudah di tangan → random saja
	candidates.shuffle()
	return candidates[0]


# ── Assign data pool ke slot kartu ────────────────────────────────────────
func _assign_slot(slot_idx: int, pool_idx: int, animate: bool) -> void:
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

	if animate:
		card.play_draw_animation()   # Fire-and-forget coroutine



