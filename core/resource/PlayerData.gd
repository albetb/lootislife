extends Resource
class_name PlayerData

# -------------------------
# PROGRESSION
# -------------------------
@export var level: int = 1
@export var experience: int = 0
@export var ability_points: int = STARTING_ABILITY_POINTS
@export var max_hand_size: int = 10

# -------------------------
# ECONOMY
# -------------------------
@export var coins: int = 0

# -------------------------
# HEALTH (PERSISTENT)
# -------------------------
@export var current_hp: int = 10

# -------------------------
# RUN / MAP
# -------------------------
@export var floor_number: int = 1
@export var path: Array[Room] = []
@export var current_path: Array[Room] = []
@export var past_path: Array[Room] = []

# -------------------------
# CLASS & BUILD
# -------------------------
@export var class_id: String = ""
@export var stats: PlayerStats = PlayerStats.new()
# i RefCounted non possono essere export e vanno creati a runtime
var build: PlayerEquipmentManager

# -------------------------
# CONSTANTS
# -------------------------
const STARTING_ABILITY_POINTS := 5

func _init():
	build = PlayerEquipmentManager.new()
