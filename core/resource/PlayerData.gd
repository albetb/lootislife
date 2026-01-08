extends Resource
class_name PlayerData

# -------------------------
# PROGRESSION
# -------------------------
@export var level: int = 1
@export var experience: int = 0
@export var ability_points: int = STARTING_ABILITY_POINTS

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
@export var path: Array[RoomResource] = []
@export var current_path: Array[RoomResource] = []
@export var past_path: Array[RoomResource] = []

# -------------------------
# CLASS & BUILD
# -------------------------
@export var class_id: String = ""
@export var stats: PlayerStats = PlayerStats.new()
@export var inventory: InventoryData = InventoryData.new()

# -------------------------
# CONSTANTS
# -------------------------
const STARTING_ABILITY_POINTS := 3
const MAX_ABILITY := 10
const MAX_HAND_SIZE := 10
const BASE_LIFE := 10
const LIFE_PER_COS := 5
const BASE_ENERGY := 3
const COS_PER_ENERGY := 5
const BASE_DRAW := 5
const INT_PER_DRAW := 5
