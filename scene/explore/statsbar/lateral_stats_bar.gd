extends ColorRect

@onready var points_label: Label = $VBoxContainer/PointsLabel
@onready var save_button = $VBoxContainer/SaveButton

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()
		
func update_ui():
	if points_label != null:
		if Player.data.ability_points > 0:
			var remaining_ability_points = Player.data.ability_points - Player.data.updating_ability_points
			points_label.text = "+" + str(remaining_ability_points)
		else:
			points_label.text = ""
		
	if save_button != null:
		save_button.visible = Player.data.ability_points > 0
		save_button.disabled = true
		for i in range(Player.data.Ability.size()):
			if Player.data.updating_ability[i] > 0:
				save_button.disabled = false

func _on_save_button_pressed() -> void:
	Player.data.ability_points -= Player.data.updating_ability_points
	Player.data.updating_ability_points = 0
	for i in range(Player.data.Ability.size()):
		Player.data.ability[i] = Player.data.ability[i] + Player.data.updating_ability[i]
		Player.data.updating_ability[i] = 0
	Events.emit_signal("update_ui")
	Player.save()


func _on_back_button_pressed() -> void:
	SceneManager.switch("res://scene/start/start_menu.tscn")
