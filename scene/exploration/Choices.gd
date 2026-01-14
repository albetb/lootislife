extends MarginContainer

@onready var choice_container: HBoxContainer = $HBoxContainer
@onready var choice_scene: PackedScene = preload("res://scene/exploration/choice/choice.tscn")

func _ready() -> void:
	Events.update_ui.connect(self.update_ui)
	update_ui()

func update_ui() -> void:
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
