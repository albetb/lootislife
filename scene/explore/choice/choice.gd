extends Control
class_name Choice

@onready var label: Label = $Label
@onready var text: String
@onready var type: RoomResource.Type
@onready var choice_number: int
@onready var sprite: Sprite2D = $Sprite2D

func set_values(room_type: RoomResource.Type):
	type = room_type
	if room_type == RoomResource.Type.Battle:
		text = "Battaglia"
	elif room_type == RoomResource.Type.Rest:
		text = "Riposa"
	elif room_type == RoomResource.Type.Treasure:
		text = "Tesoro"
	elif room_type == RoomResource.Type.Selection:
		text = "Scelta"
	elif room_type == RoomResource.Type.Boss:
		text = "Boss"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if label != null and label.text != str(text):
		label.set_text(str(text))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Events.emit_signal("choice_selected", choice_number)
		accept_event()
