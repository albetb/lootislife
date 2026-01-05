extends CardState

func _enter():
	print("CLICK", card)

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transitioned.emit("drag")
