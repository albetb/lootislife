extends VBoxContainer

@export_enum("strength", "dexterity", "constitution", "intelligence")
var stat_key: String

@export var display_name: String

@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var value_label: Label = $HBoxContainer/ValueLabel
@onready var plus_button: Button = $HBoxContainer/PlusButton
@onready var modified_bar: ProgressBar = $ModifiedBar
@onready var actual_bar: ProgressBar = $ModifiedBar/ActualBar

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()

func update_ui() -> void:
	if Player.data == null or Player.data.stats == null:
		return

	var stats := Player.data.stats
	var current_value = stats.get(stat_key)
	if current_value == null:
		push_error("StatsContainer: stat_key non valido: %s" % stat_key)
		return

	var points_left := Player.data.ability_points

	name_label.text = display_name
	value_label.text = str(current_value)
	
	var max_ability_value = max(stats.strength, stats.dexterity, stats.constitution, stats.intelligence)

	actual_bar.max_value = min(Player.data.MAX_ABILITY, max_ability_value + points_left)
	modified_bar.max_value = min(Player.data.MAX_ABILITY, max_ability_value + points_left)
	
	actual_bar.size = modified_bar.size

	actual_bar.value = current_value

	if points_left <= 0 or current_value >= Player.data.MAX_ABILITY:
		plus_button.visible = false
		plus_button.disabled = true
		modified_bar.value = current_value
	else:
		plus_button.text = "+%d" % points_left
		plus_button.visible = true
		plus_button.disabled = false
		var a = min(points_left, Player.data.MAX_ABILITY - current_value)
		modified_bar.value = current_value + a

func _on_plus_button_pressed() -> void:
	Player.update_stat(stat_key, 1) 
	Events.emit_signal("update_ui")
	Events.emit_signal("inventory_changed")
