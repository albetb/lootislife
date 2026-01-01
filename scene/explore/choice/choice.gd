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
		text = "Battaglia"
	elif room_type == Room.Type.Rest:
		text = "Riposa"
	elif room_type == Room.Type.Treasure:
		text = "Tesoro"
	elif room_type == Room.Type.Selection:
		text = "Scelta"
	elif room_type == Room.Type.Boss:
		text = "Boss"

func _ready() -> void:
	if label != null and label.text != str(text):
		label.set_text(str(text))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var left = sprite.global_position.x - sprite.get_rect().size.x / 2 
		var right = sprite.global_position.x + sprite.get_rect().size.x / 2 
		var bottom = sprite.global_position.y - sprite.get_rect().size.y / 2 
		var top = sprite.global_position.y + sprite.get_rect().size.y / 2 
		var is_in_card = left <= event.position.x and event.position.x <= right
		var is_over_card = bottom <= event.position.y and event.position.y <= top
		if is_in_card and is_over_card:
			Events.emit_signal("choice_selected", choice_number)
