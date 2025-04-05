extends VBoxContainer

@export var ability_type: PlayerData.Ability
@onready var name_label: Label = $NameLabel
@onready var stats_bar: ColorRect = $"../.."
@onready var value_label: Label = $HBoxContainer/ValueLabel
@onready var minus_button: Button = $HBoxContainer/MinusButton
@onready var plus_button: Button = $HBoxContainer/PlusButton
@onready var modified_bar: ProgressBar = $ModifiedBar
@onready var actual_bar: ProgressBar = $ModifiedBar/ActualBar

func _ready() -> void:
	Events.update_ui.connect(self.update_ui)
	update_ui()
	
func update_ui() -> void:
	var points_to_assign: int = Player.data.ability_points - Player.data.updating_ability_points
	var current_points = Player.data.ability[ability_type] + Player.data.updating_ability[ability_type]
	minus_button.disabled = Player.data.updating_ability[ability_type] <= 0
	plus_button.disabled = points_to_assign <= 0 or current_points >= Player.max_ability()
	minus_button.visible = Player.data.ability_points > 0
	plus_button.visible = Player.data.ability_points > 0
	
	if ability_type == PlayerData.Ability.Str:
		name_label.text = "Forza"
	elif ability_type == PlayerData.Ability.Des:
		name_label.text = "Agilità"
	elif ability_type == PlayerData.Ability.Cos:
		name_label.text = "Tempra"
	elif ability_type == PlayerData.Ability.Int:
		name_label.text = "Intellig."
	elif ability_type == PlayerData.Ability.Sag:
		name_label.text = "Percez."
	elif ability_type == PlayerData.Ability.Car:
		name_label.text = "Carisma"
		
	value_label.text = str(current_points)
	
	actual_bar.value = Player.data.ability[ability_type]
	modified_bar.value = current_points
	if Player.data.ability_points > 0:
		actual_bar.max_value = Player.max_ability()
		modified_bar.max_value = Player.max_ability()
	else:
		var hightest_ability = 1
		for i in range(Player.data.Ability.size()):
			if Player.data.ability[i] > hightest_ability:
				hightest_ability = Player.data.ability[i]
		actual_bar.max_value = hightest_ability
		modified_bar.max_value = hightest_ability
	
	
func _on_minus_button_pressed() -> void:
	if Player.data.updating_ability[ability_type] > 0:
		Player.data.updating_ability[ability_type] = Player.data.updating_ability[ability_type] - 1
		Player.data.updating_ability_points -= 1
		Events.emit_signal("update_ui")

func _on_plus_button_pressed() -> void:
	var remaining_points = Player.data.ability_points - Player.data.updating_ability_points
	var max_points = Player.max_ability()
	var current_points = Player.data.ability[ability_type] + Player.data.updating_ability[ability_type]
	if remaining_points > 0 and current_points < max_points:
		Player.data.updating_ability[ability_type] = Player.data.updating_ability[ability_type] + 1
		Player.data.updating_ability_points += 1
		Events.emit_signal("update_ui")
