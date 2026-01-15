extends ColorRect

@onready var room_scene: PackedScene = preload("res://scene/exploration/room/room_card.tscn")
@onready var choice_scene: PackedScene = preload("res://scene/exploration/choice/choice.tscn")

@onready var choice_container: HBoxContainer = $Choices/HBoxContainer
@onready var path_container: HBoxContainer = $Path/HBoxContainer
@onready var past_path_container: HBoxContainer = $Passed/HBoxContainer
@onready var floor_label: Label = $RoomPanel/FloorLabel
@onready var room_label: Label = $RoomPanel/RoomLabel

func _ready() -> void:
	Events.update_ui.connect(self.update_ui)
	update_ui()

func update_ui() -> void:
	# Room panel
	floor_label.text = "Piano: " + str(Player.data.floor_number)
	room_label.text = "Stanza: " + str(Player.current_room())
	
	# Passed
	for child in past_path_container.get_children():
		past_path_container.remove_child(child)
		child.queue_free()
		
	for room: RoomResource in Player.data.past_path:
		var main_room_card: RoomCard = room_scene.instantiate()
		main_room_card.set_values(room.type)
		past_path_container.add_child(main_room_card)
	
	# Path
	for child in path_container.get_children():
		path_container.remove_child(child)
		child.queue_free()
		
	for room_type in RoomResource.Type.values():
		var number = Player.data.path.filter(func(x: RoomResource): return x.type == room_type).size()
		if number <= 0:
			continue
		var main_room_card: RoomCard = room_scene.instantiate()
		main_room_card.set_values(room_type)
		if number > 1:
			main_room_card.add_number(number)
		path_container.add_child(main_room_card)

	# Choiches
	for child in choice_container.get_children():
		choice_container.remove_child(child)
		child.queue_free()
		
	for room: RoomResource in Player.data.current_path:
		var choice_card: Choice = choice_scene.instantiate()
		choice_card.set_values(room.type)
		choice_card.choice_number = choice_container.get_child_count() % 3
		if Player.data.current_path.size() == 1:
			choice_card.choice_number = 0
		choice_container.add_child(choice_card)
