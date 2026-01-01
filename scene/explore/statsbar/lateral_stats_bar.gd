extends ColorRect

@onready var points_label: Label = $VBoxContainer/PointsLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()

func update_ui() -> void:
	if Player.data == null:
		return

	var points := Player.data.ability_points

	if points > 0:
		points_label.text = "+%d" % points
		points_label.visible = true
	else:
		points_label.visible = false

func _on_back_button_pressed() -> void:
	Player.save()
	SceneManager.switch("res://scene/start/start_menu.tscn")
