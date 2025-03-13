extends Node

var save_file_path: String = "user://save/"
var save_file_name: String = "PlayerSave.Tres"
@export var data: PlayerData = PlayerData.new()

func _ready() -> void:
	DirAccess.make_dir_absolute(save_file_path)
	load_data()

func load_data():
	data = ResourceLoader.load(save_file_path + save_file_name, "PlayerData") as PlayerData
	if data == null:
		reset()
	else:
		data = data.duplicate(true)
	
func save():
	ResourceSaver.save(data, save_file_path + save_file_name)

func reset():
	data = PlayerData.new()
	data._ready()
	save()
	
func exp_needed() -> int:
	return int(data.level * 5 + 10)
	
func max_health() -> int:
	return int(floor(10 + data.level * data.ability[int(data.Ability.Cos)]))
	
func current_health() -> int:
	return int(max_health() - data.damage)
	
func current_room() -> int:
	return int(data.past_path.size() + 1)
	
func loot_mult() -> float:
	return float(data.floor + (current_room() - 1) * 0.1)
	
func mult_this_loot(value) -> int:
	return int(floor(value * loot_mult()))
	
func max_ability() -> int:
	return data.level + 4
	
func gain_exp(amount: int):
	data.exp += amount
	var _exp_needed = exp_needed()
	while data.exp >= _exp_needed:
		data.exp -= _exp_needed
		gain_level()

func gain_level():
	data.level += 1
	data.ability_points += 1

func is_game_started():
	var is_moved =  data.floor > 1 or data.past_path.size() > 0
	var is_leveled = data.ability_points != PlayerData.STARTING_ABILITY_POINTS 
	return is_moved or is_leveled
