# UnitStats.gd
# Custom Resource untuk menyimpan data stats semua unit
# Edit nilainya langsung di Inspector — tidak perlu buka kode!

class_name UnitStats
extends Resource

@export var unit_name    : String = "Unknown Unit"
@export var max_hp       : float  = 100.0
@export var move_speed   : float  = 80.0
@export var damage       : float  = 10.0
@export var attack_range : float  = 50.0
@export var attack_speed : float  = 1.0   # serangan per detik
@export var cost         : int    = 100   # biaya Oxygen Points
