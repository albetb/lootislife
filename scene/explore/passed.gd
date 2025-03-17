extends MarginContainer

@onready var past_path_container: HBoxContainer = $HBoxContainer
@onready var room_scene: PackedScene = preload("res://scene/explore/room/room_card.tscn")

func _ready() -> void:
	Events.update_ui.connect(self.update_ui)
	update_ui()

func update_ui() -> void:
	for child in past_path_container.get_children():
		past_path_container.remove_child(child)
		child.queue_free()
		
	for room: Room in Player.data.past_path:
		var main_room_card: RoomCard = room_scene.instantiate()
		main_room_card.set_values(room.type)
		past_path_container.add_child(main_room_card)
