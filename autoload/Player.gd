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
	var loadout := preload("res://core/equipment/loadouts/base_equip.tres")
	apply_starting_loadout(loadout)
	
func apply_starting_loadout(loadout: StartingLoadoutData) -> void:
	# --- equip ---
	for equipment in loadout.starting_equipment:
		data.build.equip(equipment)

	# --- inventario ---
	data.inventory.items.clear()
	for entry in loadout.starting_inventory:
		data.inventory.items.append(entry.duplicate(true))

	save()

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
	
func update_stat(stat_key: String, stat_increment: int) -> void:
	if data.ability_points <= 0:
		return

	var stats := data.stats
	var current_value = stats.get(stat_key)

	if current_value >= data.MAX_ABILITY:
		return
	
	if stat_key == "constitution":
		update_cos(stat_increment)

	stats.set(stat_key, current_value + stat_increment)
	data.ability_points -= stat_increment

func update_cos(stat_increment: int) -> void:
	data.current_hp += stat_increment * data.LIFE_PER_COS

# -------------------------
# STATS DERIVATE
# -------------------------

func max_health() -> int:
	return data.BASE_LIFE + data.stats.constitution * data.LIFE_PER_COS

func max_energy() -> int:
	return data.BASE_ENERGY + int(data.stats.constitution / data.COS_PER_ENERGY)

func base_draw() -> int:
	return data.BASE_DRAW + int(data.stats.intelligence / data.INT_PER_DRAW)

func physical_damage_bonus() -> int:
	return data.stats.strength

func get_damage_bonus() -> int:
	return 0

func block_bonus() -> int:
	return data.stats.dexterity

func get_inventory_slots() -> int:
	var base := 16
	var bonus := data.stats.strength * 2
	return min(base + bonus, 36)

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
