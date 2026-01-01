extends Panel

func _ready() -> void:
	Events.update_ui.connect(update_ui)
	update_ui()

func update_ui():
	$FloorLabel.text = "Piano: " + str(Player.data.floor_number)
