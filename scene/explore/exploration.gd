extends Node

@export var length: int = 0
@export var path: Array[Room] = []
@export var past_path: Array[Room] = []
@export var current_path: Array[Room] = []
@onready var path_container: HBoxContainer = $"../Path/HBoxContainer"
@onready var past_path_container: HBoxContainer = $"../Passed/HBoxContainer"
@onready var choice_container: HBoxContainer = $"../MarginContainer/HBoxContainer"
@onready var instance_manager: Node = $"../InstanceManager"
@onready var room_scene: PackedScene = preload("res://scene/room/room_card.tscn")
@onready var choice_scene: PackedScene = preload("res://scene/explore/choice/choice.tscn")

func _ready() -> void:
	if Player.data.path.size() == 0 and Player.data.current_path.size() == 0 and Player.data.past_path.size() > 0:
		clear_path()
		
	if Player.data.path.size() == 0 and Player.data.current_path.size() == 0:
		new_exploration()
		choose_path()
		save_path()
	else:
		load_path()
	
	display()
	
func clear_path() -> void:
	Player.data.path = []
	Player.data.past_path = []
	Player.data.current_path = []
	path = []
	past_path = []
	current_path = []
	save_path()

func display() -> void:
	display_path()
	display_past_path()
	display_choiches() 

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
	display()
	
	select_new_scene(selected_path)
	
func select_new_scene(room: Room) -> void:
	if room.type == Room.Type.Battle:
		SceneManager.switch("res://scene/combat/battle.tscn")
	if room.type == Room.Type.Boss:
		SceneManager.switch("res://scene/city/city.tscn")
	
func display_path() -> void:
	for child in path_container.get_children():
		child.queue_free()
		
	for room_type in Room.Type.values():
		var number = path.filter(func(x: Room): return x.type == room_type).size()
		if number <= 0:
			continue
		var main_room_card: RoomCard = room_scene.instantiate()
		main_room_card.set_values(room_type)
		if number > 1:
			main_room_card.add_number(number)
		path_container.add_child(main_room_card)

func display_past_path() -> void:
	for child in past_path_container.get_children():
		child.queue_free()
		
	print(past_path)
	for room: Room in past_path:
		var main_room_card: RoomCard = room_scene.instantiate()
		main_room_card.set_values(room.type)
		past_path_container.add_child(main_room_card)

func display_choiches() -> void:
	for child in choice_container.get_children():
		child.queue_free()
		
	for room: Room in current_path:
		var choice_card: Choice = choice_scene.instantiate()
		choice_card.set_values(room.type)
		choice_card.choice_number = choice_container.get_child_count() % 3
		if current_path.size() == 1:
			choice_card.choice_number = 0
		choice_container.add_child(choice_card)

func new_exploration(difficult: int = 2):
	path = []
	current_path = []
	past_path = []
	
	#length = min(floor(3 * sqrt(Player.data.level)) - 3, 10)
	length = 5#min(floor(3 * sqrt(5)) - 3, 10)

	for i in range(length):
		var room_types = Room.Type.values().filter(func(x): return x != Room.Type.Boss)
		var room = Room.new()
		room.type = room_types[randi() % room_types.size()]
		path.append(room.duplicate(true))
		
	for room_type in Room.Type.values():
		var room = Room.new()
		room.type = room_type
		path.append(room)
	
	save_path()
