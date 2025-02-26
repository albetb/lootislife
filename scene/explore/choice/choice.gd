extends Control
class_name Choice

@onready var label: Label = $Label
@onready var text: String
@onready var type: Room.Type
@onready var choice_number: int
@onready var sprite: Sprite2D = $Sprite2D

func set_values(room_type: Room.Type):
	type = room_type
	if room_type == Room.Type.Battle:
		text = "Battle"
	elif room_type == Room.Type.Rest:
		text = "Rest"
	elif room_type == Room.Type.Treasure:
		text = "Treasure"
	elif room_type == Room.Type.Choice:
		text = "Choice"
	elif room_type == Room.Type.Boss:
		text = "Boss"

func _process(delta: float) -> void:
	if label != null and label.text != str(text):
		label.set_text(str(text))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var left = sprite.global_position.x - sprite.get_rect().size.x / 2 
		var right = sprite.global_position.x + sprite.get_rect().size.x / 2 
		if left <= event.position.x and event.position.x <= right:
			get_tree().call_group("exploration", "choice_selected", choice_number)
