extends Control
class_name Choice

@onready var label: Label = $HBoxContainer/Background/Label
@onready var background: TextureRect = $HBoxContainer/Background
@onready var text: String
@onready var selected_background: Texture2D
@onready var type: RoomResource.Type
@onready var choice_number: int


@export var battle_background: Texture2D
@export var rest_background: Texture2D
@export var treasure_background: Texture2D
@export var selection_background: Texture2D
@export var boss_background: Texture2D
@export var shop_background: Texture2D

func set_values(room_type: RoomResource.Type):
	type = room_type
	if room_type == RoomResource.Type.Battle:
		text = "Battaglia"
		selected_background = battle_background
	elif room_type == RoomResource.Type.Rest:
		text = "Riposa"
		selected_background = rest_background
	elif room_type == RoomResource.Type.Treasure:
		text = "Tesoro"
		selected_background = treasure_background
	elif room_type == RoomResource.Type.Selection:
		text = "Scelta"
		selected_background = selection_background
	elif room_type == RoomResource.Type.Boss:
		text = "Boss"
		selected_background = boss_background

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if label != null and label.text != str(text):
		label.set_text(str(text))
	if background != null and background.texture != selected_background:
		background.texture = selected_background

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Events.emit_signal("choice_selected", choice_number)
		accept_event()
