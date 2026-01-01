extends Node

# --- Save ---
const SAVE_DIR := "user://save/"
const SAVE_FILE := "PlayerSave.tres"

# --- Data ---
@export var data: PlayerData
var pending_combat_deck: Array[CardInstance] = []

func _ready() -> void:
	DirAccess.make_dir_absolute(SAVE_DIR)
	load_data()

# -------------------------
# SAVE / LOAD
# -------------------------

func load_data() -> void:
	var path := SAVE_DIR + SAVE_FILE
	if ResourceLoader.exists(path):
		data = ResourceLoader.load(path, "PlayerData") as PlayerData
		if data:
			data = data.duplicate(true)
		else:
			reset()
	else:
		reset()

func save() -> void:
	if data:
		ResourceSaver.save(data, SAVE_DIR + SAVE_FILE)

func reset() -> void:
	data = PlayerData.new()
	_setup_starting_equipment()
	save()

func _setup_starting_equipment() -> void:
	var build := data.build

	var weapon := preload("res://equipment/templates/short_sword.tres")
	var armor := preload("res://equipment/templates/armor_base.tres")
	var relic := preload("res://equipment/templates/ninnolo_base.tres")

	build.equip(weapon)
	build.equip(armor)
	build.equip(relic)

# -------------------------
# PROGRESSION
# -------------------------

func exp_needed() -> int:
	return data.level * 5 + 10

func gain_exp(amount: int) -> void:
	data.experience += amount
	while data.experience >= exp_needed():
		data.experience -= exp_needed()
		level_up()

func level_up() -> void:
	data.level += 1
	data.ability_points += 1
	# eventuale hook per eventi
	# Events.player_level_up.emit(data.level)

# -------------------------
# STATS DERIVATE
# -------------------------

func max_health() -> int:
	return 10 + data.stats.constitution * 5

func base_draw() -> int:
	return 5 + int(data.stats.intelligence / 5)

func physical_damage_bonus() -> int:
	return data.stats.strength

func block_bonus() -> int:
	return data.stats.dexterity
	
func max_ability() -> int:
	return data.level + 4

# -------------------------
# VITA
# -------------------------

func heal(amount: int) -> void:
	data.current_hp = min(data.current_hp + amount, max_health())

func take_damage(amount: int) -> void:
	data.current_hp = max(data.current_hp - amount, 0)

func is_dead() -> bool:
	return data.current_hp <= 0

# -------------------------
# RUN / PROGRESS
# -------------------------

func current_room() -> int:
	return data.past_path.size() + 1

func loot_multiplier() -> float:
	return data.floor_number + (current_room() - 1) * 0.1

func apply_loot_multiplier(value: int) -> int:
	return int(floor(value * loot_multiplier()))

func is_game_started() -> bool:
	return data.floor_number > 1 or data.past_path.size() > 0

# -------------------------
# DECK / COMBAT
# -------------------------

func generate_deck() -> Array[CardInstance]:
	if data == null or data.build == null:
		return []

	# Genera il mazzo a partire dall'equipaggiamento
	var deck: Array[CardInstance] = data.build.generate_deck()
	print("Generated deck size:", deck.size())

	return deck
