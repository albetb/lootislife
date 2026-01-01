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

	plus_button.disabled = points_left <= 0 or current_value >= Player.max_ability()

	actual_bar.max_value = Player.max_ability()
	modified_bar.max_value = Player.max_ability()

	actual_bar.value = current_value
	modified_bar.value = current_value

func _on_plus_button_pressed() -> void:
	if Player.data.ability_points <= 0:
		return

	var stats := Player.data.stats
	var current_value = stats.get(stat_key)

	if current_value >= Player.max_ability():
		return

	stats.set(stat_key, current_value + 1)
	Player.data.ability_points -= 1
	Events.emit_signal("update_ui")
