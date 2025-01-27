extends CardState


func _enter():
	card.pivot_offset = Vector2.ZERO

func on_mouse_entered():
	transitioned.emit("hover")
