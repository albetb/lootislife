extends VBoxContainer

@export_enum("strength", "dexterity", "constitution", "intelligence")
var stat_key: String

@export var display_name: String

@onready var value_label: Label = $HBoxContainer/ValueLabel
@onready var plus_button: Button = $HBoxContainer/PlusButton
@onready var image: TextureRect = $HBoxContainer/Image

@export var str_icon: Texture2D
@export var des_icon: Texture2D
@export var cos_icon: Texture2D
@export var int_icon: Texture2D

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()
	
	plus_button.focus_mode = Control.FOCUS_NONE

func update_ui() -> void:
	if Player.data == null or Player.data.stats == null:
		return

	var stats := Player.data.stats
	var current_value = stats.get(stat_key)
	if current_value == null:
		push_error("StatsContainer: stat_key non valido: %s" % stat_key)
		return

	var points_left := Player.data.ability_points

	if stat_key == "strength":
		image.texture = str_icon
	elif stat_key == "dexterity":
		image.texture = des_icon
	elif stat_key == "constitution":
		image.texture = cos_icon
	elif stat_key == "intelligence":
		image.texture = int_icon
		
		
	value_label.text = str(current_value)
	
	var max_ability_value = max(stats.strength, stats.dexterity, stats.constitution, stats.intelligence)

	if points_left <= 0 or current_value >= Player.data.MAX_ABILITY:
		plus_button.visible = false
		plus_button.disabled = true
	else:
		plus_button.visible = true
		plus_button.disabled = false
		var a = min(points_left, Player.data.MAX_ABILITY - current_value)

func _on_plus_button_pressed() -> void:
	Player.update_stat(stat_key, 1) 
	Events.emit_signal("update_ui")
	Events.emit_signal("inventory_changed")
