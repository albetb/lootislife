extends MarginContainer

@onready var path_container: HBoxContainer = $HBoxContainer
@onready var room_scene: PackedScene = preload("res://scene/explore/room/room_card.tscn")

func _ready() -> void:
	Events.update_ui.connect(self.update_ui)
	update_ui()

func update_ui() -> void:
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
