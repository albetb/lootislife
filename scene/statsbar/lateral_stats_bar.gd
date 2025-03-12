extends ColorRect
signal update_ability_points
@onready var points_label: Label = $VBoxContainer/PointsLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_text()
	
func update_text():
	if Player.data.ability_points > 0:
		points_label.text = "+" + str(Player.data.ability_points - Player.data.updating_ability_points)
	else:
		points_label.text = ""

func _update_ability_points():
	update_text()

func _on_save_button_pressed() -> void:
	Player.data.ability_points -= Player.data.updating_ability_points
	Player.data.updating_ability_points = 0
	for i in range(Player.data.Ability.size()):
		Player.data.ability[i] = Player.data.ability[i] + Player.data.updating_ability[i]
		Player.data.updating_ability[i] = 0
	update_text()
	emit_signal("update_ability_points")
	Player.save()
