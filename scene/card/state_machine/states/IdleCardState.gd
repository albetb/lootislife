extends CardState

func _enter():
	card.scale = Vector2(1,1)

func on_mouse_entered():
	transitioned.emit("hover")
