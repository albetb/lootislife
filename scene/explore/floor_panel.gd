extends Panel

func _ready() -> void:
	update_ui()

func update_ui():
	$FloorLabel.text = "Piano: " + str(Player.data.floor)
