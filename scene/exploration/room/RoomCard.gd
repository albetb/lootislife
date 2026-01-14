extends Control
class_name RoomCard

@onready var label: Label = $Label
@onready var number_label: Label = $NumberLabel
@onready var background: ColorRect = $ColorRect
@onready var color: Color
@onready var text: String
@onready var num: int
@onready var type: RoomResource.Type


func _ready() -> void:
	if label != null and label.text != str(text):
		label.set_text(str(text))
	if background != null and background.color != color:
		background.color = color
	
	if number_label != null and num == 0:
		number_label.text = ""
	elif number_label != null and number_label.text != "x" + str(num):
		number_label.text = "x" + str(num)
	
func set_values(room_type: RoomResource.Type):
	type = room_type
	if room_type == RoomResource.Type.Battle:
		text = "Battaglia"
		color = Color.INDIAN_RED
	elif room_type == RoomResource.Type.Rest:
		text = "Riposa"
		color = Color.GREEN_YELLOW
	elif room_type == RoomResource.Type.Treasure:
		text = "Tesoro"
		color = Color.YELLOW
	elif room_type == RoomResource.Type.Selection:
		text = "Scelta"
		color = Color.AQUA
	elif room_type == RoomResource.Type.Boss:
		text = "Boss"
		color = Color.ORANGE
		
func add_number(number: int):
	num = number
