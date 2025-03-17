extends Node

@export var length: int = 0
@export var path: Array[Room] = []
@export var past_path: Array[Room] = []
@export var current_path: Array[Room] = []

func _ready() -> void:
	Events.choice_selected.connect(self.choice_selected)
	begin()
	
func begin() -> void:
	if Player.data.path.size() == 0 and Player.data.current_path.size() == 0 and Player.data.past_path.size() > 0:
		clear_path()
		
	if Player.data.path.size() == 0 and Player.data.current_path.size() == 0:
		new_exploration()
		choose_path()
		save_path()
	else:
		load_path()
	
func clear_path() -> void:
	Player.data.path = []
	Player.data.past_path = []
	Player.data.current_path = []
	path = []
	past_path = []
	current_path = []
	save_path()

func load_path() -> void:
	path = Player.data.path
	past_path = Player.data.past_path
	current_path = Player.data.current_path

func save_path() -> void:
	Player.data.path = path
	Player.data.past_path = past_path
	Player.data.current_path = current_path
	Player.save()
	
func choose_path() -> void:
	current_path = []
	var pp_size: int = path.filter(func(x): return x.type != Room.Type.Boss).size()
	
	if pp_size == 0 and path.size() == 1:
		current_path = path
		path = []
		return
		
	for i in range(min(3, pp_size)):
		var chosen_room: Room
		chosen_room = path.filter(func(x): return x.type != Room.Type.Boss).pick_random()
		current_path.append(chosen_room)
		path.remove_at(path.find(chosen_room))
	
func choice_selected(num: int):
	var selected_path = current_path.pop_at(num)
	past_path.append(selected_path)
	path.append_array(current_path)
	choose_path()
	save_path()
	
	Events.emit_signal("update_ui")
	
	select_new_scene(selected_path)
	
func select_new_scene(room: Room) -> void:
	Player.save()
	if room.type == Room.Type.Battle:
		SceneManager.switch("res://scene/combat/battle.tscn")
	if room.type == Room.Type.Boss:
		Player.data.floor += 1
		Player.save()
		begin()
		Events.emit_signal("update_ui")

func new_exploration():
	path = []
	current_path = []
	past_path = []
	
	length = 3 + floor((Player.data.floor - 1) / 3)

	for i in range(length):
		var room_types = Room.Type.values().filter(func(x): return x != Room.Type.Boss and x != Room.Type.Battle)
		var room = Room.new()
		room.type = Room.Type.Battle 
		path.append(room.duplicate(true)) # add a battle
		room.type = room_types[randi() % room_types.size()]
		path.append(room.duplicate(true)) # add a random other room
	
	var boss_room = Room.new()
	boss_room.type = Room.Type.Boss 
	path.append(boss_room.duplicate(true)) # add a boss
	
	save_path()
