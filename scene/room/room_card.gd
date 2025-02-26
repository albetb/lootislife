extends Control
class_name RoomCard

@onready var label: Label = $Label
@onready var background: ColorRect = $ColorRect
@onready var color: Color
@onready var text: String
@onready var type: Room.Type


func _ready() -> void:
	pass
	
func set_values(room_type: Room.Type):
	type = room_type
	if room_type == Room.Type.Battle:
		text = "Battle"
		color = Color.INDIAN_RED
	elif room_type == Room.Type.Rest:
		text = "Rest"
		color = Color.GREEN_YELLOW
	elif room_type == Room.Type.Treasure:
		text = "Treasure"
		color = Color.YELLOW
	elif room_type == Room.Type.Choice:
		text = "Choice"
		color = Color.AQUA
	elif room_type == Room.Type.Boss:
		text = "Boss"
		color = Color.ORANGE
		
func add_number(number: int):
	text = str(number) + "x " + text
	
func _process(delta: float) -> void:
	if label != null and label.text != str(text):
		label.set_text(str(text))
	if background != null and background.color != color:
		background.color = color
